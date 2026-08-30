import Foundation

/// Everything the API told us about a failed request.
public struct FoPostAPIErrorDetails: Sendable, Hashable {
  /// The HTTP status code.
  public let status: Int
  /// The machine-readable code from the `{"error": ...}` envelope.
  public let code: String?
  /// The human-readable explanation.
  public let message: String
  /// The raw response body, for fields this type does not model.
  public let body: Data
  /// The `X-RateLimit-*` headers that came with the response.
  public let rateLimit: RateLimit?
  /// The wait the API asked for, from `Retry-After`.
  public let retryAfter: TimeInterval?

  public init(
    status: Int,
    code: String?,
    message: String,
    body: Data,
    rateLimit: RateLimit? = nil,
    retryAfter: TimeInterval? = nil
  ) {
    self.status = status
    self.code = code
    self.message = message
    self.body = body
    self.rateLimit = rateLimit
    self.retryAfter = retryAfter
  }

  /// The page a 402 suggests sending the user to, when it carries one.
  public var upgradeURL: URL? {
    guard let raw: String = field("upgrade_url") else { return nil }
    return URL(string: raw)
  }

  /// Decodes an extra field an error carries alongside `error` and `message`.
  public func field<T: Decodable>(_ name: String, as type: T.Type = T.self) -> T? {
    guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
      let value = object[name]
    else { return nil }
    guard
      let data = try? JSONSerialization.data(withJSONObject: [value], options: [.fragmentsAllowed])
    else { return nil }
    return try? JSONDecoder().decode([T].self, from: data).first
  }

  /// The response body as text, when it was text at all.
  public var bodyText: String? { String(data: body, encoding: .utf8) }
}

/// Every error the SDK throws.
public enum FoPostError: Error, Sendable {
  /// 400 or 422 — the request body did not pass validation.
  case validation(FoPostAPIErrorDetails)
  /// 401 — the API key is missing, invalid, or expired.
  case authentication(FoPostAPIErrorDetails)
  /// 402 — no active subscription, or AI credits are exhausted.
  case paymentRequired(FoPostAPIErrorDetails)
  /// 403 — the key is valid but lacks the scope or workspace access.
  case permissionDenied(FoPostAPIErrorDetails)
  /// 404 — no such resource, or it is outside the key's reach.
  case notFound(FoPostAPIErrorDetails)
  /// 409 — the resource is in a state that forbids the change.
  case conflict(FoPostAPIErrorDetails)
  /// 429 — the rate limit is spent. `retryAfter` carries the wait.
  case rateLimited(FoPostAPIErrorDetails)
  /// 5xx — the API failed.
  case server(FoPostAPIErrorDetails)
  /// Any other non-2xx status.
  case api(FoPostAPIErrorDetails)
  /// The request never reached the API.
  case transport(URLError)
  /// The response was not valid JSON, or not the shape the SDK expected.
  case decoding(message: String, body: Data)
  /// A request body could not be encoded.
  case encoding(message: String)
  /// The client was built without a usable API key or base URL.
  case configuration(message: String)

  /// The API's account of the failure, for the cases that have one.
  public var details: FoPostAPIErrorDetails? {
    switch self {
    case .validation(let details), .authentication(let details), .paymentRequired(let details),
      .permissionDenied(let details), .notFound(let details), .conflict(let details),
      .rateLimited(let details), .server(let details), .api(let details):
      return details
    case .transport, .decoding, .encoding, .configuration:
      return nil
    }
  }

  /// The HTTP status behind the error, when it came from the API.
  public var status: Int? { details?.status }

  /// The machine-readable API error code, e.g. `subscription_required`.
  public var code: String? { details?.code }

  /// Where to send the user when a 402 says the plan is the blocker.
  public var upgradeURL: URL? {
    guard case .paymentRequired(let details) = self else { return nil }
    return details.upgradeURL
  }

  /// The wait a 429 asked for, in seconds.
  public var retryAfter: TimeInterval? { details?.retryAfter }

  /// The rate-limit budget reported with the response.
  public var rateLimit: RateLimit? { details?.rateLimit }

  public var message: String {
    switch self {
    case .validation(let d), .authentication(let d), .paymentRequired(let d),
      .permissionDenied(let d), .notFound(let d), .conflict(let d), .rateLimited(let d),
      .server(let d), .api(let d):
      return d.message
    case .transport(let error):
      return error.localizedDescription
    case .decoding(let message, _):
      return message
    case .encoding(let message):
      return message
    case .configuration(let message):
      return message
    }
  }

  static func from(status: Int, details: FoPostAPIErrorDetails) -> FoPostError {
    switch status {
    case 400, 422: return .validation(details)
    case 401: return .authentication(details)
    case 402: return .paymentRequired(details)
    case 403: return .permissionDenied(details)
    case 404: return .notFound(details)
    case 409: return .conflict(details)
    case 429: return .rateLimited(details)
    case 500...599: return .server(details)
    default: return .api(details)
    }
  }
}

extension FoPostError: LocalizedError {
  public var errorDescription: String? {
    guard let details else { return "FoPost: \(message)" }
    if let code = details.code, !code.isEmpty {
      return "FoPost: \(details.status) \(code): \(details.message)"
    }
    return "FoPost: \(details.status): \(details.message)"
  }
}
