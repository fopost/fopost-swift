import Foundation

/// Manage a connected Google Business Profile location: the profile itself,
/// attributes, food menus, services, photos, place action links, verification
/// and performance.
///
/// Google grants Business Profile API access per project. Until that grant
/// lands on a deployment every call here throws a 503 `configuration_error`.
///
/// Responses relay Google's own shape, field for field, so they come back as
/// ``JSONValue`` rather than models we would have to keep chasing.
public struct GoogleBusinessResource: Resource {
  let transport: Transport

  /// The daily metrics fetched when a caller names none.
  public static let defaultDailyMetrics = [
    "BUSINESS_IMPRESSIONS_DESKTOP_MAPS",
    "BUSINESS_IMPRESSIONS_DESKTOP_SEARCH",
    "BUSINESS_IMPRESSIONS_MOBILE_MAPS",
    "BUSINESS_IMPRESSIONS_MOBILE_SEARCH",
    "CALL_CLICKS",
    "WEBSITE_CLICKS",
    "BUSINESS_DIRECTION_REQUESTS",
  ]

  // MARK: - Location

  /// The connected location, in the Business Information shape.
  public func location(_ id: String) async throws -> JSONValue {
    try await httpGet(path(id, "/location"), as: JSONValue.self)
  }

  /// Patches the profile. Only the keys `fields` carries change, and a
  /// `.null` value clears that field. Keys are the API's own snake_case
  /// names: `title`, `description`, `website_uri`, `primary_phone`,
  /// `additional_phones`, `store_code` and `regular_hours`.
  @discardableResult
  public func updateLocation(_ id: String, fields: [String: JSONValue]) async throws -> JSONValue {
    try await httpPatch(path(id, "/location"), body: fields, as: JSONValue.self)
  }

  // MARK: - Attributes

  /// The attribute values set on the location, or, with `available`, the
  /// attributes Google offers for its category and region.
  public func attributes(
    _ id: String, available: Bool = false, categoryName: String? = nil, regionCode: String? = nil,
    languageCode: String? = nil
  ) async throws -> JSONValue {
    var query = Query()
    if available { query.add("available", true) }
    query.add("category_name", categoryName)
    query.add("region_code", regionCode)
    query.add("language_code", languageCode)
    return try await httpGet(path(id, "/attributes"), query: query, as: JSONValue.self)
  }

  /// Changes only the named attributes; every other one is left alone.
  @discardableResult
  public func updateAttributes(_ id: String, attributes: [JSONValue]) async throws -> JSONValue {
    try await httpPatch(
      path(id, "/attributes"), body: ["attributes": JSONValue.array(attributes)],
      as: JSONValue.self)
  }

  // MARK: - Food menus and services

  /// The location's food menus.
  public func menus(_ id: String) async throws -> JSONValue {
    try await httpGet(path(id, "/menus"), as: JSONValue.self)
  }

  /// Google has no per-section patch, so the whole menu set is replaced.
  @discardableResult
  public func replaceMenus(_ id: String, menus: [JSONValue]) async throws -> JSONValue {
    try await httpPut(path(id, "/menus"), body: ["menus": JSONValue.array(menus)], as: JSONValue.self)
  }

  /// The location's service list.
  public func services(_ id: String) async throws -> JSONValue {
    try await httpGet(path(id, "/services"), as: JSONValue.self)
  }

  /// Replaces the whole service list.
  @discardableResult
  public func replaceServices(_ id: String, serviceItems: [JSONValue]) async throws -> JSONValue {
    try await httpPut(
      path(id, "/services"), body: ["service_items": JSONValue.array(serviceItems)],
      as: JSONValue.self)
  }

  // MARK: - Photos

  /// The photos on the location.
  public func media(_ id: String, pageSize: Int? = nil, pageToken: String? = nil) async throws
    -> JSONValue
  {
    var query = Query()
    query.add("page_size", pageSize)
    query.add("page_token", pageToken)
    return try await httpGet(path(id, "/media"), query: query, as: JSONValue.self)
  }

  /// Adds a photo from the media library. The asset has to be in a workspace
  /// the caller can reach, and JPEG or PNG.
  @discardableResult
  public func addMedia(
    _ id: String, mediaID: String, category: String = "ADDITIONAL", description: String? = nil
  ) async throws -> JSONValue {
    var body: [String: JSONValue] = [
      "media_id": .string(mediaID),
      "category": .string(category),
    ]
    if let description { body["description"] = .string(description) }
    return try await httpPost(path(id, "/media"), body: body, as: JSONValue.self)
  }

  /// Removes a photo by the media key Google returned.
  @discardableResult
  public func deleteMedia(_ id: String, mediaKey: String) async throws -> JSONValue {
    try await httpDelete(path(id, "/media/\(escapePath(mediaKey))"), as: JSONValue.self)
  }

  // MARK: - Place action links

  /// The Book, Order and Reserve links on the listing.
  public func placeActions(_ id: String) async throws -> JSONValue {
    try await httpGet(path(id, "/place-actions"), as: JSONValue.self)
  }

  /// Adds an action link to the listing.
  @discardableResult
  public func createPlaceAction(
    _ id: String, uri: String, placeActionType: String, isPreferred: Bool? = nil
  ) async throws -> JSONValue {
    var body: [String: JSONValue] = [
      "uri": .string(uri),
      "place_action_type": .string(placeActionType),
    ]
    if let isPreferred { body["is_preferred"] = .bool(isPreferred) }
    return try await httpPost(path(id, "/place-actions"), body: body, as: JSONValue.self)
  }

  /// Patches one action link; a nil argument is left alone.
  @discardableResult
  public func updatePlaceAction(
    _ id: String, linkID: String, uri: String? = nil, isPreferred: Bool? = nil
  ) async throws -> JSONValue {
    var body: [String: JSONValue] = [:]
    if let uri { body["uri"] = .string(uri) }
    if let isPreferred { body["is_preferred"] = .bool(isPreferred) }
    return try await httpPatch(
      path(id, "/place-actions/\(escapePath(linkID))"), body: body, as: JSONValue.self)
  }

  /// Removes one action link.
  @discardableResult
  public func deletePlaceAction(_ id: String, linkID: String) async throws -> JSONValue {
    try await httpDelete(path(id, "/place-actions/\(escapePath(linkID))"), as: JSONValue.self)
  }

  // MARK: - Verification

  /// The ways Google will let this location be verified.
  public func verificationOptions(_ id: String, languageCode: String? = nil) async throws
    -> JSONValue
  {
    var query = Query()
    query.add("language_code", languageCode)
    return try await httpGet(path(id, "/verification"), query: query, as: JSONValue.self)
  }

  /// Starts a verification. `method` is `ADDRESS`, `EMAIL`, `PHONE_CALL`,
  /// `SMS`, `AUTO` or `VETTED_PARTNER`; the response names the pending
  /// verification to complete with the PIN.
  @discardableResult
  public func startVerification(
    _ id: String, method: String, languageCode: String? = nil, phoneNumber: String? = nil,
    emailAddress: String? = nil, mailerContactName: String? = nil
  ) async throws -> JSONValue {
    var body: [String: JSONValue] = ["method": .string(method)]
    if let languageCode { body["language_code"] = .string(languageCode) }
    if let phoneNumber { body["phone_number"] = .string(phoneNumber) }
    if let emailAddress { body["email_address"] = .string(emailAddress) }
    if let mailerContactName { body["mailer_contact_name"] = .string(mailerContactName) }
    return try await httpPost(path(id, "/verification/start"), body: body, as: JSONValue.self)
  }

  /// Completes a pending verification with the PIN Google sent.
  @discardableResult
  public func completeVerification(_ id: String, verificationName: String, pin: String) async throws
    -> JSONValue
  {
    let body: [String: JSONValue] = [
      "verification_name": .string(verificationName),
      "pin": .string(pin),
    ]
    return try await httpPost(path(id, "/verification/complete"), body: body, as: JSONValue.self)
  }

  // MARK: - Performance

  /// Daily impressions, calls, direction requests and clicks for the range.
  /// An empty `dailyMetrics` leaves the API's own default set.
  public func performance(
    _ id: String, startDate: String, endDate: String, dailyMetrics: [String] = []
  ) async throws -> JSONValue {
    var query = Query()
    query.add("start_date", startDate)
    query.add("end_date", endDate)
    for metric in dailyMetrics { query.add("daily_metrics", metric) }
    return try await httpGet(path(id, "/performance"), query: query, as: JSONValue.self)
  }

  /// The search terms people used to find the listing, by month.
  public func searchKeywords(
    _ id: String, startDate: String, endDate: String, pageToken: String? = nil
  ) async throws -> JSONValue {
    var query = Query()
    query.add("keywords", true)
    query.add("start_date", startDate)
    query.add("end_date", endDate)
    query.add("page_token", pageToken)
    return try await httpGet(path(id, "/performance"), query: query, as: JSONValue.self)
  }

  // MARK: - Workspace assignment

  /// Hands the location to another workspace the caller owns. The connection
  /// and every row keyed to it move in one transaction.
  @discardableResult
  public func assign(_ id: String, workspaceID: String) async throws -> MovedAccount {
    try await httpPost(
      path(id, "/assign"), body: MoveAccountRequest(workspaceID: workspaceID),
      as: MovedAccount.self)
  }

  private func path(_ id: String, _ suffix: String) -> String {
    "/accounts/\(escapePath(id))/gbp\(suffix)"
  }
}
