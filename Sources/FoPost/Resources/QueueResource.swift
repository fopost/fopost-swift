import Foundation

/// The posting queue: recurring slots a post lands in when it is created
/// with `schedule: "queue"` instead of a `scheduleAt`.
public struct QueueResource: Resource {
  let transport: Transport

  /// The slots a workspace has, workspace-wide and per account.
  public func listSlots(workspaceID: String) async throws -> [QueueSlot] {
    var query = Query()
    query.add("workspace_id", workspaceID)
    return try await httpGet("/queue/slots", query: query, as: [QueueSlot].self)
  }

  /// Adds a slot.
  public func createSlot(_ body: CreateQueueSlotRequest) async throws -> QueueSlot {
    try await httpPost("/queue/slots", body: body, as: QueueSlot.self)
  }

  /// Changes a slot. Posts already queued into it move to the new time and
  /// come back in `moved`.
  public func updateSlot(_ id: String, _ body: UpdateQueueSlotRequest) async throws
    -> UpdatedQueueSlot
  {
    try await httpPut("/queue/slots/\(escapePath(id))", body: body, as: UpdatedQueueSlot.self)
  }

  /// Removes a slot. Posts queued into it move to the next free slot and come
  /// back in `moved`.
  @discardableResult
  public func deleteSlot(_ id: String) async throws -> DeletedQueueSlot {
    try await httpDelete("/queue/slots/\(escapePath(id))", as: DeletedQueueSlot.self)
  }

  /// The next free queue time, or `nil` when the workspace has no slots.
  public func next(workspaceID: String, accountID: String? = nil) async throws -> Date? {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("account_id", accountID)
    return try await httpGet("/queue/next", query: query, as: QueueNextResponse.self).next
  }

  /// The next `count` free queue times, soonest first.
  public func preview(workspaceID: String, accountID: String? = nil, count: Int? = nil)
    async throws -> [Date]
  {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("account_id", accountID)
    query.add("count", count)
    return try await httpGet("/queue/preview", query: query, as: [Date].self)
  }
}
