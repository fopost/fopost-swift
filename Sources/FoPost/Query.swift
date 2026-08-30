import Foundation

/// Collects query parameters, skipping the empty values the API reads as
/// "not sent" and answers with its own default for.
struct Query {
  private(set) var items: [URLQueryItem] = []

  init() {}

  init(_ pairs: [String: String]) {
    for key in pairs.keys.sorted() { add(key, pairs[key]) }
  }

  mutating func add(_ name: String, _ value: String?) {
    guard let value, !value.isEmpty else { return }
    items.append(URLQueryItem(name: name, value: value))
  }

  mutating func add(_ name: String, _ value: Int?) {
    guard let value else { return }
    items.append(URLQueryItem(name: name, value: String(value)))
  }

  mutating func add(_ name: String, _ value: Bool?) {
    guard let value else { return }
    items.append(URLQueryItem(name: name, value: value ? "true" : "false"))
  }

  mutating func add(_ name: String, _ value: Date?) {
    guard let value else { return }
    items.append(URLQueryItem(name: name, value: Timestamps.format(value)))
  }

  /// Comma-separated, the form every list filter on the API accepts.
  mutating func add(_ name: String, _ values: [String]?) {
    guard let values, !values.isEmpty else { return }
    items.append(URLQueryItem(name: name, value: values.joined(separator: ",")))
  }
}
