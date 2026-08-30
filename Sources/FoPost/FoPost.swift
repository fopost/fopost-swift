/// The FoPost SDK version, reported in the `User-Agent` header.
public let fopostVersion = "0.1.0"

/// An empty response body, for endpoints that answer with nothing.
public struct Empty: Codable, Sendable, Hashable {
  public init() {}
}
