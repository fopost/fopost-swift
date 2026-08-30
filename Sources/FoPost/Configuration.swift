import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Transport settings shared by every request the client makes.
public struct FoPostConfiguration: Sendable {
  /// The production API root, including its version prefix.
  public static let defaultBaseURL = URL(string: "https://api.fopost.com/v1")!

  /// Bounds a single request, including its body.
  public static let defaultTimeout: TimeInterval = 30

  /// Total attempts per request, so 3 means two retries.
  public static let defaultMaxAttempts = 3

  /// No backoff ever waits longer than this.
  public static let maximumRetryDelay: TimeInterval = 60

  /// The first retry waits this long; each further one doubles it.
  public static let baseRetryDelay: TimeInterval = 0.5

  public var baseURL: URL
  public var timeout: TimeInterval
  public var maxAttempts: Int
  /// The first retry waits this long; each further one doubles it.
  public var retryBaseDelay: TimeInterval
  /// No wait, backoff or `Retry-After`, ever exceeds this.
  public var retryMaximumDelay: TimeInterval
  /// Prepended to the SDK's own `fopost-swift/<version>` identifier.
  public var userAgentPrefix: String?

  public init(
    baseURL: URL = FoPostConfiguration.defaultBaseURL,
    timeout: TimeInterval = FoPostConfiguration.defaultTimeout,
    maxAttempts: Int = FoPostConfiguration.defaultMaxAttempts,
    retryBaseDelay: TimeInterval = FoPostConfiguration.baseRetryDelay,
    retryMaximumDelay: TimeInterval = FoPostConfiguration.maximumRetryDelay,
    userAgentPrefix: String? = nil
  ) {
    self.baseURL = baseURL
    self.timeout = timeout
    self.maxAttempts = max(1, maxAttempts)
    self.retryBaseDelay = retryBaseDelay
    self.retryMaximumDelay = retryMaximumDelay
    self.userAgentPrefix = userAgentPrefix
  }

  /// Reads `FOPOST_BASE_URL` when it is set, otherwise keeps the default.
  public static func fromEnvironment() -> FoPostConfiguration {
    var configuration = FoPostConfiguration()
    if let raw = ProcessInfo.processInfo.environment["FOPOST_BASE_URL"],
      !raw.trimmingCharacters(in: .whitespaces).isEmpty,
      let url = URL(string: raw.trimmingTrailingSlashes())
    {
      configuration.baseURL = url
    }
    return configuration
  }

  var userAgent: String {
    let sdk = "fopost-swift/\(fopostVersion)"
    guard let prefix = userAgentPrefix, !prefix.isEmpty else { return sdk }
    return "\(prefix) \(sdk)"
  }
}

extension String {
  func trimmingTrailingSlashes() -> String {
    var value = trimmingCharacters(in: .whitespacesAndNewlines)
    while value.hasSuffix("/") { value.removeLast() }
    return value
  }
}
