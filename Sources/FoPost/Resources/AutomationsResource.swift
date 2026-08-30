import Foundation

/// Automations: a trigger plus the steps it runs.
public struct AutomationsResource: Resource {
  let transport: Transport

  /// The automations the key can reach.
  public func list() async throws -> [Automation] {
    try await httpGet("/automations", as: [Automation].self)
  }

  /// One automation with its steps.
  public func get(_ id: String) async throws -> Automation {
    try await httpGet("/automations/\(escapePath(id))", as: Automation.self)
  }

  /// Adds an automation. For an `api_webhook` trigger, the response carries
  /// the signing secret once — store it now.
  public func create(_ body: CreateAutomationRequest) async throws -> Automation {
    try await httpPost("/automations", body: body, as: Automation.self)
  }

  /// Edits an automation.
  public func update(_ id: String, _ body: UpdateAutomationRequest) async throws -> Automation {
    try await httpPut("/automations/\(escapePath(id))", body: body, as: Automation.self)
  }

  /// Removes an automation.
  public func delete(_ id: String) async throws {
    try await httpDelete("/automations/\(escapePath(id))")
  }

  /// Switches an automation on or off.
  @discardableResult
  public func toggle(_ id: String) async throws -> ToggleResult {
    try await httpPost("/automations/\(escapePath(id))/toggle", as: ToggleResult.self)
  }

  /// An automation's executions. Nil page or perPage leaves the API's
  /// defaults in place.
  public func runs(_ id: String, page: Int? = nil, perPage: Int? = nil) async throws
    -> Page<AutomationRun>
  {
    var query = Query()
    query.add("page", page)
    query.add("per_page", perPage)
    return try await httpGet(
      "/automations/\(escapePath(id))/runs", query: query, unwrap: false,
      as: Page<AutomationRun>.self)
  }

  /// One execution, with a log per step.
  public func run(_ id: String, runID: Int) async throws -> AutomationRun {
    try await httpGet("/automations/\(escapePath(id))/runs/\(runID)", as: AutomationRun.self)
  }

  /// Fires an `api_webhook` automation with a payload its steps can read.
  @discardableResult
  public func trigger(_ id: String, payload: [String: JSONValue] = [:]) async throws
    -> TriggerResult
  {
    try await httpPost(
      "/automations/\(escapePath(id))/trigger", body: payload, as: TriggerResult.self)
  }

  /// Automation counts and recent runs.
  public func stats() async throws -> AutomationStats {
    try await httpGet("/automations/stats", as: AutomationStats.self)
  }
}
