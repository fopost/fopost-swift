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

/// Whether a delivery attempt reached the endpoint.
public struct WebhookDeliveryStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let success: Self = "success"
  public static let failed: Self = "failed"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.success, .failed]
}

/// One attempt to send an event to the endpoint. Every attempt of one event
/// shares a `deliveryKey`.
public struct WebhookDelivery: Codable, Sendable, Hashable {
  public let id: String
  public let webhookID: String?
  public let event: WebhookEvent?
  public let deliveryKey: String?
  public let attempt: Int?
  public let status: WebhookDeliveryStatus?
  public let responseStatus: Int?
  public let responseSnippet: String?
  public let durationMs: Int?
  public let payloadHash: String?
  public let nextRetryAt: Date?
  public let createdAt: Date?
  /// The event body as sent; only on ``WebhooksResource/delivery(_:deliveryID:)``.
  public let payload: [String: JSONValue]?

  enum CodingKeys: String, CodingKey {
    case id, event, attempt, status, payload
    case webhookID = "webhook_id"
    case deliveryKey = "delivery_key"
    case responseStatus = "response_status"
    case responseSnippet = "response_snippet"
    case durationMs = "duration_ms"
    case payloadHash = "payload_hash"
    case nextRetryAt = "next_retry_at"
    case createdAt = "created_at"
  }
}
