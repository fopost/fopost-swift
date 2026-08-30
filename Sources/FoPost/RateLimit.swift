import Foundation

/// The per-key, per-minute budget reported on every response.
public struct RateLimit: Sendable, Hashable {
  public let limit: Int?
  public let remaining: Int?
  public let reset: Date?

  public init(limit: Int?, remaining: Int?, reset: Date?) {
    self.limit = limit
    self.remaining = remaining
    self.reset = reset
  }

  /// Reads the `X-RateLimit-*` headers, returning nil when none are present.
  static func from(headers: [AnyHashable: Any]) -> RateLimit? {
    let limit = headers.headerInt("X-RateLimit-Limit")
    let remaining = headers.headerInt("X-RateLimit-Remaining")
    var reset: Date?
    if let raw = headers.headerString("X-RateLimit-Reset"), let seconds = Double(raw) {
      // The API sends a unix timestamp; tolerate a delta from a proxy.
      reset =
        seconds > 1_000_000_000
        ? Date(timeIntervalSince1970: seconds)
        : Date().addingTimeInterval(seconds)
    }
    if limit == nil, remaining == nil, reset == nil { return nil }
    return RateLimit(limit: limit, remaining: remaining, reset: reset)
  }
}

extension Dictionary where Key == AnyHashable, Value == Any {
  func headerString(_ name: String) -> String? {
    for (key, value) in self where (key as? String)?.caseInsensitiveCompare(name) == .orderedSame {
      if let string = value as? String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
    }
    return nil
  }

  func headerInt(_ name: String) -> Int? {
    headerString(name).flatMap(Int.init)
  }
}
