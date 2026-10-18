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

/// A node named in a version's change summary.
public struct AutomationVersionNodeRef: Codable, Sendable, Hashable {
  public let id: String
  public let kind: String?
  public let label: String?
}

/// Who saved a version.
public struct AutomationVersionAuthor: Codable, Sendable, Hashable {
  public let name: String?
}

/// One saved version of an automation, as listed: what changed, not the graph.
public struct AutomationVersionSummary: Codable, Sendable, Hashable {
  public let version: Int
  public let note: String?
  public let createdBy: AutomationVersionAuthor?
  public let createdAt: Date?
  public let nodeCount: Int?
  public let nodesAdded: [AutomationVersionNodeRef]?
  public let nodesRemoved: [AutomationVersionNodeRef]?

  enum CodingKeys: String, CodingKey {
    case version, note
    case createdBy = "created_by"
    case createdAt = "created_at"
    case nodeCount = "node_count"
    case nodesAdded = "nodes_added"
    case nodesRemoved = "nodes_removed"
  }
}

/// The page counters on a version list.
public struct AutomationVersionPageMeta: Codable, Sendable, Hashable {
  public let page: Int?
  public let perPage: Int?
  public let total: Int?
  public let totalPages: Int?

  enum CodingKeys: String, CodingKey {
    case page, total
    case perPage = "per_page"
    case totalPages = "total_pages"
  }
}

/// One page of an automation's versions, newest first.
public struct AutomationVersionList: Codable, Sendable, Hashable {
  public let data: [AutomationVersionSummary]
  public let meta: AutomationVersionPageMeta?
}

/// Where a node sits on the canvas.
public struct AutomationNodeLayout: Codable, Sendable, Hashable {
  public let x: Double?
  public let y: Double?
}

/// One node in a version's graph.
public struct AutomationGraphNode: Codable, Sendable, Hashable {
  public let id: String
  public let kind: String?
  public let label: String?
  /// Node settings, echoed back exactly as authored.
  public let config: [String: JSONValue]?
  public let position: Int?
  public let layout: AutomationNodeLayout?
}

/// One edge in a version's graph.
public struct AutomationGraphEdge: Codable, Sendable, Hashable {
  public let id: String
  public let source: String?
  public let sourceHandle: String?
  public let target: String?

  enum CodingKeys: String, CodingKey {
    case id, source, target
    case sourceHandle = "source_handle"
  }
}

/// The nodes and edges a version holds.
public struct AutomationGraph: Codable, Sendable, Hashable {
  public let nodes: [AutomationGraphNode]?
  public let edges: [AutomationGraphEdge]?
}

/// One saved version of an automation, with its graph.
public struct AutomationVersion: Codable, Sendable, Hashable {
  public let version: Int
  public let note: String?
  public let createdBy: AutomationVersionAuthor?
  public let createdAt: Date?
  public let graph: AutomationGraph?

  enum CodingKeys: String, CodingKey {
    case version, note, graph
    case createdBy = "created_by"
    case createdAt = "created_at"
  }
}

/// One step as compiled from a restored graph.
public struct AutomationVersionStep: Codable, Sendable, Hashable {
  public let position: Int?
  public let nodeID: String?
  public let actionType: String?
  public let actionConfig: [String: JSONValue]?

  enum CodingKeys: String, CodingKey {
    case position
    case nodeID = "node_id"
    case actionType = "action_type"
    case actionConfig = "action_config"
  }
}

/// The automation after a restore: the new version, its graph and steps.
public struct RestoredAutomationVersion: Codable, Sendable, Hashable {
  public let version: Int
  public let graph: AutomationGraph?
  public let steps: [AutomationVersionStep]?
}
