import Foundation

/// Broadcasts: one message into every conversation the workspace already has
/// with a segment of its contacts.
///
/// A broadcast is not a post and not a cold DM — every message lands in a
/// direct-message thread the contact already started.
///
/// Nothing is sent into a closed messaging window. Messenger and Instagram take
/// a business-initiated message only within 24 hours of the contact's last one,
/// so recipients outside it come back ``RecipientStatus/skipped`` with
/// ``SkipReason/windowClosed`` and nothing is attempted — which is why the
/// number sent is often lower than the audience. Telegram, Slack, Bluesky and
/// Reddit have no window.
///
/// Reading needs the `inbox` scope; ``send(_:)`` and ``cancel(_:)`` also need
/// `publish`.
public struct BroadcastsResource: Resource {
  let transport: Transport

  /// One page of broadcasts, newest first.
  ///
  /// Leave `workspaceID` unset to span every workspace the key can reach; each
  /// broadcast then carries one.
  public func list(
    workspaceID: String? = nil, status: String? = nil, page: Int? = nil, perPage: Int? = nil
  ) async throws -> BroadcastPage {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("status", status)
    query.add("page", page)
    query.add("per_page", perPage)
    // `unwrap: false`: the pagination block sits beside `data`.
    return try await httpGet("/broadcasts", query: query, unwrap: false, as: BroadcastPage.self)
  }

  /// One broadcast.
  ///
  /// A broadcast in a workspace the key cannot reach answers `404`, exactly as
  /// an id that never existed does.
  public func get(_ id: String) async throws -> Broadcast {
    try await httpGet("/broadcasts/\(escapePath(id))", as: Broadcast.self)
  }

  /// Writes a broadcast without sending it.
  ///
  /// Set `scheduledAt` to have it go out on its own at that time; otherwise
  /// call ``send(_:)``.
  public func create(_ body: CreateBroadcastRequest) async throws -> Broadcast {
    try await httpPost("/broadcasts", body: body, as: Broadcast.self)
  }

  /// Changes a broadcast. Only a draft or scheduled broadcast can be edited.
  public func update(_ id: String, _ body: UpdateBroadcastRequest) async throws -> Broadcast {
    try await httpPatch("/broadcasts/\(escapePath(id))", body: body, as: Broadcast.self)
  }

  /// Freezes the audience into a recipient list and starts sending.
  ///
  /// The returned `recipients` is how many contacts matched, not how many will
  /// be messaged — the messaging window decides that. Needs the `publish`
  /// scope as well as `inbox`.
  public func send(_ id: String) async throws -> BroadcastSent {
    try await httpPost("/broadcasts/\(escapePath(id))/send", as: BroadcastSent.self)
  }

  /// Stops a broadcast where it stands.
  ///
  /// Anyone not yet written to stays unsent; messages already delivered are not
  /// recalled. Needs the `publish` scope.
  public func cancel(_ id: String) async throws -> Broadcast {
    try await httpPost("/broadcasts/\(escapePath(id))/cancel", as: Broadcast.self)
  }

  /// One row per contact, with what became of their message. A skipped row
  /// carries its reason.
  public func recipients(
    _ id: String, status: String? = nil, page: Int? = nil, perPage: Int? = nil
  ) async throws -> RecipientPage {
    var query = Query()
    query.add("status", status)
    query.add("page", page)
    query.add("per_page", perPage)
    return try await httpGet(
      "/broadcasts/\(escapePath(id))/recipients", query: query, unwrap: false,
      as: RecipientPage.self)
  }

  /// Removes a broadcast and its recipient records. Messages already sent stay
  /// in the conversations they went to.
  public func delete(_ id: String) async throws {
    try await httpDelete("/broadcasts/\(escapePath(id))")
  }
}

/// Drip sequences: a series of messages, each a delay after the one before,
/// walked per enrolled contact.
///
/// The messaging window applies to every step. A step that comes due outside it
/// is skipped rather than sent, and the enrollment carries on — so someone can
/// complete a sequence having received only some of its messages.
///
/// Reading needs the `inbox` scope; ``enroll(_:_:)`` and ``unenroll(_:_:)``
/// also need `publish`.
public struct SequencesResource: Resource {
  let transport: Transport

  /// One page of sequences.
  public func list(
    workspaceID: String? = nil, page: Int? = nil, perPage: Int? = nil
  ) async throws -> SequencePage {
    var query = Query()
    query.add("workspace_id", workspaceID)
    query.add("page", page)
    query.add("per_page", perPage)
    return try await httpGet("/sequences", query: query, unwrap: false, as: SequencePage.self)
  }

  /// One sequence.
  public func get(_ id: String) async throws -> Sequence {
    try await httpGet("/sequences/\(escapePath(id))", as: Sequence.self)
  }

  /// Writes a sequence. Creating one enrolls nobody.
  public func create(_ body: CreateSequenceRequest) async throws -> Sequence {
    try await httpPost("/sequences", body: body, as: Sequence.self)
  }

  /// Changes a sequence.
  ///
  /// Pausing stops every enrollment from firing without ending any of them;
  /// resuming picks them up where they stood.
  public func update(_ id: String, _ body: UpdateSequenceRequest) async throws -> Sequence {
    try await httpPatch("/sequences/\(escapePath(id))", body: body, as: Sequence.self)
  }

  /// Puts contacts on the sequence, by id or by audience.
  ///
  /// Re-enrolling someone restarts their walk from the first step rather than
  /// running two in parallel. Needs `publish` as well as `inbox`.
  public func enroll(_ id: String, _ body: EnrollRequest) async throws -> Enrolled {
    try await httpPost("/sequences/\(escapePath(id))/enroll", body: body, as: Enrolled.self)
  }

  /// Takes contacts off the sequence. Nothing further fires for them. Needs the
  /// `publish` scope.
  public func unenroll(_ id: String, _ contactIDs: [String]) async throws -> Unenrolled {
    try await httpPost(
      "/sequences/\(escapePath(id))/unenroll", body: UnenrollRequest(contactIDs: contactIDs),
      as: Unenrolled.self)
  }

  /// Who is on the sequence, what step they are at, and when the next one is
  /// due.
  public func enrollments(
    _ id: String, page: Int? = nil, perPage: Int? = nil
  ) async throws -> EnrollmentPage {
    var query = Query()
    query.add("page", page)
    query.add("per_page", perPage)
    return try await httpGet(
      "/sequences/\(escapePath(id))/enrollments", query: query, unwrap: false,
      as: EnrollmentPage.self)
  }

  /// Removes a sequence and every enrollment on it.
  public func delete(_ id: String) async throws {
    try await httpDelete("/sequences/\(escapePath(id))")
  }
}
