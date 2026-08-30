import Foundation

/// One action in an automation, in position order.
public struct AutomationStep: Codable, Sendable, Hashable {
  public var id: Int?
  public var position: Int?
  public var actionType: AutomationAction
  public var actionConfig: [String: JSONValue]?

  public init(
    actionType: AutomationAction, actionConfig: [String: JSONValue]? = nil,
    position: Int? = nil, id: Int? = nil
  ) {
    self.id = id
    self.position = position
    self.actionType = actionType
    self.actionConfig = actionConfig
  }
}

/// One trigger and the steps behind it.
public struct Automation: Codable, Sendable, Hashable {
  public let id: String
  public let workspaceId: String?
  public let name: String?
  public let triggerType: AutomationTrigger?
  public let triggerConfig: [String: JSONValue]?
  public let active: Bool?
  public let lastTriggeredAt: Date?
  public let runCount: Int?
  public let steps: [AutomationStep]?
  /// Returned once, by create, for an `api_webhook` trigger.
  public let secret: String?
  public let createdAt: Date?
  public let updatedAt: Date?
}

/// The body of ``AutomationsResource/create(_:)``.
public struct CreateAutomationRequest: Codable, Sendable {
  public var workspaceId: String
  public var name: String
  public var triggerType: AutomationTrigger
  public var triggerConfig: [String: JSONValue]?
  public var steps: [AutomationStep]
  public var active: Bool?

  public init(
    workspaceId: String, name: String, triggerType: AutomationTrigger,
    steps: [AutomationStep], triggerConfig: [String: JSONValue]? = nil, active: Bool? = nil
  ) {
    self.workspaceId = workspaceId
    self.name = name
    self.triggerType = triggerType
    self.triggerConfig = triggerConfig
    self.steps = steps
    self.active = active
  }
}

/// The body of ``AutomationsResource/update(_:_:)``. Only the fields you set
/// are sent, but `steps` replaces the whole list when given.
public struct UpdateAutomationRequest: Codable, Sendable {
  public var name: String?
  public var triggerConfig: [String: JSONValue]?
  public var steps: [AutomationStep]?
  public var active: Bool?

  public init(
    name: String? = nil, triggerConfig: [String: JSONValue]? = nil,
    steps: [AutomationStep]? = nil, active: Bool? = nil
  ) {
    self.name = name
    self.triggerConfig = triggerConfig
    self.steps = steps
    self.active = active
  }
}

/// An automation's active flag after toggling.
public struct ToggleResult: Codable, Sendable, Hashable {
  public let id: String
  public let active: Bool?
}

/// One step's log line within a run.
public struct AutomationRunLog: Codable, Sendable, Hashable {
  public let id: Int?
  public let stepPosition: Int?
  public let status: String?
  public let inputSnapshot: [String: JSONValue]?
  public let outputSnapshot: [String: JSONValue]?
  public let startedAt: Date?
  public let completedAt: Date?
  public let durationMs: Int?
  public let errorMessage: String?
}

/// One execution of an automation.
public struct AutomationRun: Codable, Sendable, Hashable {
  public let id: Int
  public let automationId: String?
  public let status: String?
  public let currentStep: Int?
  public let triggerEvent: [String: JSONValue]?
  public let context: [String: JSONValue]?
  public let startedAt: Date?
  public let completedAt: Date?
  public let errorMessage: String?
  public let logs: [AutomationRunLog]?
}

/// The run a webhook trigger started.
public struct TriggerResult: Codable, Sendable, Hashable {
  public let runId: Int?
  public let triggered: Bool?
}

/// The roll-up behind the automations dashboard.
public struct AutomationStats: Codable, Sendable, Hashable {
  public struct RecentRun: Codable, Sendable, Hashable {
    public let id: Int?
    public let automationId: String?
    public let status: String?
    public let startedAt: Date?
    public let completedAt: Date?
  }

  public let totalAutomations: Int?
  public let activeAutomations: Int?
  public let totalRuns24h: Int?
  public let runsByStatus: [String: Int]?
  public let recentRuns: [RecentRun]?
}
