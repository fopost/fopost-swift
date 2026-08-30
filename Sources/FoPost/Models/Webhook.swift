import Foundation

/// One webhook subscription.
public struct Webhook: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let url: String?
  public let events: [WebhookEvent]?
  public let active: Bool?
  public let lastTriggeredAt: Date?
  public let failureCount: Int?
  public let createdAt: Date?
}

/// A new subscription. `secret` is shown once, at creation, and signs every
/// delivery — store it now.
public struct CreatedWebhook: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let url: String?
  public let secret: String?
  public let events: [WebhookEvent]?
  public let active: Bool?
  public let createdAt: Date?
}

/// The body of ``WebhooksResource/create(_:)``.
public struct CreateWebhookRequest: Codable, Sendable {
  public var workspaceId: String
  public var url: String
  public var events: [WebhookEvent]

  public init(workspaceId: String, url: String, events: [WebhookEvent]) {
    self.workspaceId = workspaceId
    self.url = url
    self.events = events
  }
}

/// The body of ``WebhooksResource/update(_:_:)``. Only the fields you set are
/// sent.
public struct UpdateWebhookRequest: Codable, Sendable {
  public var url: String?
  public var events: [WebhookEvent]?
  public var active: Bool?

  public init(url: String? = nil, events: [WebhookEvent]? = nil, active: Bool? = nil) {
    self.url = url
    self.events = events
    self.active = active
  }
}
