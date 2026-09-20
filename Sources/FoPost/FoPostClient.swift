import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The official Swift SDK for the FoPost API — schedule, publish, and analyze
/// social media content across every connected platform.
///
/// ```swift
/// let client = try FoPostClient(apiKey: "fp_...")
/// let post = try await client.posts.create(
///     CreatePostRequest(
///         workspaceID: workspace.id,
///         accounts: [account.id],
///         content: .text("Hello from Swift")))
/// try await client.posts.publish(post.id)
/// ```
///
/// The client is `Sendable` and safe to share across tasks.
public final class FoPostClient: Sendable {
  private let transport: Transport

  /// The API root every request is sent to.
  public var baseURL: URL { transport.baseURL }

  /// Builds a client for an API key, created in the FoPost dashboard under
  /// Settings → API Keys. Omitting the key reads `FOPOST_API_KEY`, and the
  /// base URL falls back to `FOPOST_BASE_URL`.
  ///
  /// - Throws: ``FoPostError/configuration(message:)`` when no key is available.
  public init(
    apiKey: String? = nil,
    configuration: FoPostConfiguration? = nil,
    session: URLSession? = nil
  ) throws {
    let key =
      apiKey?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
      ?? ProcessInfo.processInfo.environment["FOPOST_API_KEY"]?
      .trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

    guard let key else {
      throw FoPostError.configuration(
        message:
          "An API key is required — pass one to FoPostClient or set FOPOST_API_KEY.")
    }

    let resolved = configuration ?? .fromEnvironment()
    let resolvedSession: URLSession
    if let session {
      resolvedSession = session
    } else {
      let sessionConfiguration = URLSessionConfiguration.ephemeral
      sessionConfiguration.timeoutIntervalForRequest = resolved.timeout
      resolvedSession = URLSession(configuration: sessionConfiguration)
    }

    transport = Transport(apiKey: key, configuration: resolved, session: resolvedSession)
  }

  // MARK: - Resources

  /// Posts, publishing, deliveries, and bulk operations.
  public var posts: PostsResource { PostsResource(transport: transport) }
  /// Workspaces, the tenant boundary every other resource is scoped to.
  public var workspaces: WorkspacesResource { WorkspacesResource(transport: transport) }
  /// Connected social accounts.
  public var accounts: AccountsResource { AccountsResource(transport: transport) }
  /// Account groups, named sets of accounts a post can target at once.
  public var accountGroups: AccountGroupsResource {
    AccountGroupsResource(transport: transport)
  }
  /// The X communities an account can post into.
  public var communities: CommunitiesResource { CommunitiesResource(transport: transport) }
  /// Labels, the campaign tags posts are grouped by.
  public var labels: LabelsResource { LabelsResource(transport: transport) }
  /// Outbound webhooks, the push counterpart to polling a post's deliveries.
  public var webhooks: WebhooksResource { WebhooksResource(transport: transport) }
  /// The cross-account reporting surface.
  public var analytics: AnalyticsResource { AnalyticsResource(transport: transport) }
  /// Automations: a trigger plus the steps it runs.
  public var automations: AutomationsResource { AutomationsResource(transport: transport) }
  /// The media library.
  public var media: MediaResource { MediaResource(transport: transport) }
  /// Comments, mentions, and direct messages on connected accounts.
  public var inbox: InboxResource { InboxResource(transport: transport) }
  /// Boosts, ads, audiences, and lead forms on a Meta Ads connection.
  public var ads: AdsResource { AdsResource(transport: transport) }
  /// Content, length, and media checks that create nothing.
  public var validate: ValidateResource { ValidateResource(transport: transport) }

  /// WhatsApp Business: templates, flows, groups, blocking and commerce.
  public var whatsapp: WhatsappResource { WhatsappResource(transport: transport) }

  // MARK: - Escape hatch

  /// Sends an authenticated request to an endpoint the SDK does not wrap yet
  /// and decodes the response.
  ///
  /// ```swift
  /// let platforms: JSONValue = try await client.request(
  ///     method: "GET", path: "/platforms", as: JSONValue.self)
  /// ```
  ///
  /// - Parameter unwrapData: peel a `{"data": ...}` envelope before decoding.
  public func request<Response: Decodable & Sendable>(
    method: String,
    path: String,
    body: (any Encodable & Sendable)? = nil,
    query: [String: String] = [:],
    unwrapData: Bool = true,
    as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      makeRequest(method: method, path: path, body: body, query: query, unwrap: unwrapData),
      as: Response.self)
  }

  /// Sends an authenticated request and discards the response body.
  public func request(
    method: String,
    path: String,
    body: (any Encodable & Sendable)? = nil,
    query: [String: String] = [:]
  ) async throws {
    try await transport.send(
      makeRequest(method: method, path: path, body: body, query: query, unwrap: false))
  }

  private func makeRequest(
    method: String, path: String, body: (any Encodable & Sendable)?, query: [String: String],
    unwrap: Bool
  ) throws -> HTTPRequest {
    var request = HTTPRequest(
      method: method.uppercased(), path: path, query: Query(query).items, unwrap: unwrap)
    if let body {
      do {
        request.body = try Coding.encoder.encode(body)
        request.contentType = "application/json"
      } catch {
        throw FoPostError.encoding(message: "Could not encode the request body: \(error)")
      }
    }
    return request
  }
}

extension String {
  var nilIfEmpty: String? { isEmpty ? nil : self }
}
