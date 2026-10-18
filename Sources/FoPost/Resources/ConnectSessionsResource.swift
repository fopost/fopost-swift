import Foundation

/// Hosted connect links: one-time pages where your own users connect a
/// social account into your workspace.
public struct ConnectSessionsResource: Resource {
  let transport: Transport

  /// Creates a session and the page to send the user to. The link expires
  /// unused.
  public func create(_ body: CreateConnectSessionRequest) async throws -> ConnectSession {
    try await httpPost("/connect-sessions", body: body, as: ConnectSession.self)
  }

  /// One session; poll it to learn when the account connected.
  public func get(_ id: String) async throws -> ConnectSession {
    try await httpGet("/connect-sessions/\(escapePath(id))", as: ConnectSession.self)
  }
}
