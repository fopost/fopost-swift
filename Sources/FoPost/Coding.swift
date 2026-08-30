import Foundation

enum Coding {
  /// The API answers in ISO 8601, with and without fractional seconds, and a
  /// handful of endpoints answer in plain date or date-time form.
  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      if let seconds = try? container.decode(Double.self) {
        return Date(timeIntervalSince1970: seconds)
      }
      let raw = try container.decode(String.self)
      if let date = Timestamps.parse(raw) { return date }
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Unrecognised timestamp \"\(raw)\"")
    }
    return decoder
  }()

  static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
      var container = encoder.singleValueContainer()
      try container.encode(Timestamps.format(date))
    }
    return encoder
  }()
}

enum Timestamps {
  // Foundation's date formatters are documented thread-safe for formatting
  // and parsing, so one shared instance each is safe and much cheaper.
  nonisolated(unsafe) private static let internetDate: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  nonisolated(unsafe) private static let internetDateWithFraction: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let fallbacks: [DateFormatter] = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"].map {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = $0
    return formatter
  }

  static func parse(_ raw: String) -> Date? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if let date = internetDateWithFraction.date(from: trimmed) { return date }
    if let date = internetDate.date(from: trimmed) { return date }
    for formatter in fallbacks {
      if let date = formatter.date(from: trimmed) { return date }
    }
    return nil
  }

  /// RFC 3339 in UTC, the form the API accepts on the way in.
  static func format(_ date: Date) -> String { internetDate.string(from: date) }
}

/// Peels the `{"data": ...}` wrapper the API puts around most resources.
struct DataEnvelope<Wrapped: Decodable>: Decodable {
  let data: Wrapped
}

private struct EnvelopeKey: CodingKey {
  let stringValue: String
  var intValue: Int? { nil }
  init?(stringValue: String) { self.stringValue = stringValue }
  init?(intValue: Int) { nil }
}

/// True when the payload is an object carrying a top-level `data` key.
struct EnvelopeProbe: Decodable {
  let isEnveloped: Bool

  init(from decoder: any Decoder) throws {
    guard let container = try? decoder.container(keyedBy: EnvelopeKey.self) else {
      isEnveloped = false
      return
    }
    isEnveloped = container.contains(EnvelopeKey(stringValue: "data")!)
  }
}
