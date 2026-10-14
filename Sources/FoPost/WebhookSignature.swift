import CryptoKit
import Foundation

/// The envelope every FoPost webhook delivers. `data` is the event-specific
/// body; decode it with ``decodeData(as:)``.
public struct WebhookEnvelope: Decodable, Sendable, Hashable {
  public let event: WebhookEvent
  public let data: JSONValue
  public let timestamp: Date?

  /// The event body as a typed model, e.g. ``BlogArticleWebhookPayload`` for
  /// `article.published`.
  public func decodeData<T: Decodable>(as type: T.Type = T.self) throws -> T {
    let raw = try Coding.encoder.encode(data)
    return try Coding.decoder.decode(T.self, from: raw)
  }
}

/// Why a delivery was refused.
public enum WebhookVerificationError: Error, Sendable, Hashable {
  /// Neither signature header was present.
  case missingSignature
  /// The signature does not match the body, or the secret is wrong.
  case invalidSignature
  /// The timestamped signature is older or newer than the tolerance allows.
  case staleTimestamp
  /// The body verified but is not a webhook envelope.
  case invalidPayload(String)
}

/// Verifies the signature on an inbound FoPost webhook and parses it.
///
/// The API signs the exact bytes it sends, so hand over the raw request body,
/// never re-serialised JSON. Headers are matched case-insensitively.
///
/// ```swift
/// let envelope = try FoPostWebhook.verify(rawBody: body, headers: headers, secret: secret)
/// if envelope.event == .articlePublished {
///   let article: BlogArticleWebhookPayload = try envelope.decodeData()
/// }
/// ```
public enum FoPostWebhook {
  /// `sha256=<hex HMAC-SHA256(secret, rawBody)>`.
  public static let signatureHeader = "X-FoPost-Signature"
  /// Unix seconds, sent alongside ``timestampedSignatureHeader``.
  public static let timestampHeader = "X-FoPost-Timestamp"
  /// `sha256=<hex HMAC-SHA256(secret, "<timestamp>.<rawBody>")>`.
  public static let timestampedSignatureHeader = "X-FoPost-Signature-256"
  public static let eventHeader = "X-FoPost-Event"
  public static let deliveryHeader = "X-FoPost-Delivery"

  /// How far a delivery's timestamp may sit from now.
  public static let defaultTolerance: TimeInterval = 300

  /// Checks the signature and returns the parsed envelope.
  ///
  /// The timestamped signature is preferred and rejected when the timestamp is
  /// more than `tolerance` away from `now`. The plain body signature is
  /// accepted only when no timestamp header came with the delivery.
  ///
  /// - Throws: ``WebhookVerificationError``.
  public static func verify(
    rawBody: Data, headers: [String: String], secret: String,
    tolerance: TimeInterval = defaultTolerance, now: Date = Date()
  ) throws -> WebhookEnvelope {
    let lookup = Dictionary(
      headers.map { ($0.key.lowercased(), $0.value.trimmingCharacters(in: .whitespaces)) }
    ) { _, last in last }
    let timestamp = lookup[timestampHeader.lowercased()]
    let timestamped = lookup[timestampedSignatureHeader.lowercased()]
    let plain = lookup[signatureHeader.lowercased()]

    if let timestamp, let timestamped {
      guard let seconds = TimeInterval(timestamp) else {
        throw WebhookVerificationError.invalidSignature
      }
      guard abs(now.timeIntervalSince1970 - seconds) <= tolerance else {
        throw WebhookVerificationError.staleTimestamp
      }
      var signed = Data("\(timestamp).".utf8)
      signed.append(rawBody)
      guard matches(timestamped, expected: hmac(signed, secret: secret)) else {
        throw WebhookVerificationError.invalidSignature
      }
    } else if timestamp == nil, let plain {
      guard matches(plain, expected: hmac(rawBody, secret: secret)) else {
        throw WebhookVerificationError.invalidSignature
      }
    } else {
      throw WebhookVerificationError.missingSignature
    }

    do {
      return try Coding.decoder.decode(WebhookEnvelope.self, from: rawBody)
    } catch {
      throw WebhookVerificationError.invalidPayload("\(error)")
    }
  }

  /// The `sha256=<hex>` value the API sends for these bytes.
  public static func sign(_ rawBody: Data, secret: String) -> String {
    "sha256=" + hmac(rawBody, secret: secret).map { String(format: "%02x", $0) }.joined()
  }

  /// The `sha256=<hex>` value the API sends for these bytes at `timestamp`.
  public static func sign(_ rawBody: Data, secret: String, timestamp: Int) -> String {
    var signed = Data("\(timestamp).".utf8)
    signed.append(rawBody)
    return sign(signed, secret: secret)
  }

  private static func hmac(_ message: Data, secret: String) -> [UInt8] {
    let key = SymmetricKey(data: Data(secret.utf8))
    return Array(HMAC<SHA256>.authenticationCode(for: message, using: key))
  }

  private static func matches(_ header: String, expected: [UInt8]) -> Bool {
    var hex = Substring(header)
    if hex.lowercased().hasPrefix("sha256=") { hex = hex.dropFirst("sha256=".count) }
    guard let actual = bytes(fromHex: hex), actual.count == expected.count else { return false }
    // XOR-accumulate so the compare takes the same time whatever differs.
    var difference: UInt8 = 0
    for (left, right) in zip(actual, expected) { difference |= left ^ right }
    return difference == 0
  }

  private static func bytes(fromHex hex: Substring) -> [UInt8]? {
    guard hex.count % 2 == 0 else { return nil }
    var result: [UInt8] = []
    result.reserveCapacity(hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
      let next = hex.index(index, offsetBy: 2)
      guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
      result.append(byte)
      index = next
    }
    return result
  }
}
