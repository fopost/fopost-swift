import Foundation

/// Outbound webhooks, the push counterpart to polling a post's deliveries.
public struct WebhooksResource: Resource {
  let transport: Transport

  /// The webhooks the key can reach.
  public func list() async throws -> [Webhook] {
    try await httpGet("/webhooks", as: [Webhook].self)
  }

  /// Subscribes an endpoint to a workspace's events. The response carries
  /// the signing secret once — store it now.
  public func create(_ body: CreateWebhookRequest) async throws -> CreatedWebhook {
    try await httpPost("/webhooks", body: body, as: CreatedWebhook.self)
  }

  /// Changes a subscription's endpoint, events, or active flag.
  public func update(_ id: String, _ body: UpdateWebhookRequest) async throws -> Webhook {
    try await httpPut("/webhooks/\(escapePath(id))", body: body, as: Webhook.self)
  }

  /// Removes a subscription.
  public func delete(_ id: String) async throws {
    try await httpDelete("/webhooks/\(escapePath(id))")
  }

  /// Sends a sample event to the subscribed endpoint.
  @discardableResult
  public func test(_ id: String) async throws -> MessageResponse {
    try await httpPost(
      "/webhooks/\(escapePath(id))/test", unwrap: false, as: MessageResponse.self)
  }

  /// A subscription's recent delivery attempts, newest first.
  public func deliveries(
    _ id: String, status: WebhookDeliveryStatus? = nil, limit: Int? = nil
  ) async throws -> [WebhookDelivery] {
    var query = Query()
    query.add("status", status?.rawValue)
    query.add("limit", limit)
    return try await httpGet(
      "/webhooks/\(escapePath(id))/deliveries", query: query, as: [WebhookDelivery].self)
  }

  /// One delivery attempt, with the payload that was sent.
  public func delivery(_ id: String, deliveryID: String) async throws -> WebhookDelivery {
    try await httpGet(
      "/webhooks/\(escapePath(id))/deliveries/\(escapePath(deliveryID))",
      as: WebhookDelivery.self)
  }

  /// Sends a delivery's payload again, as a new attempt under the same key.
  public func redeliver(_ id: String, deliveryID: String) async throws {
    _ = try await httpPost(
      "/webhooks/\(escapePath(id))/deliveries/\(escapePath(deliveryID))/redeliver",
      as: Empty.self)
  }
}
