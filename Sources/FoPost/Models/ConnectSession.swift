import Foundation

/// Where a connect session stands.
public struct ConnectSessionStatus: FoPostStringEnum {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }

  public static let pending: Self = "pending"
  public static let used: Self = "used"
  public static let expired: Self = "expired"

  /// Every value the SDK knows about at this version.
  public static let known: [Self] = [.pending, .used, .expired]
}

/// The name and logo shown on the hosted connect page.
public struct ConnectSessionBranding: Codable, Sendable, Hashable {
  public let name: String?
  public let logoURL: String?

  enum CodingKeys: String, CodingKey {
    case name
    case logoURL = "logo_url"
  }
}

/// A hosted connect link: a one-time page where one of your users connects
/// a social account into your workspace without a FoPost login.
public struct ConnectSession: Codable, Sendable, Hashable {
  public let id: String
  public let status: ConnectSessionStatus?
  /// Your own id for the user, echoed back once the account connects.
  public let externalUserID: String?
  public let platforms: [Platform]?
  public let redirectURL: String?
  public let branding: ConnectSessionBranding?
  /// The account the session connected, once `status` is `used`.
  public let accountID: String?
  /// The page to send the user to.
  public let url: String?
  public let expiresAt: Date?
  public let usedAt: Date?
  public let createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, status, platforms, branding, url
    case externalUserID = "external_user_id"
    case redirectURL = "redirect_url"
    case accountID = "account_id"
    case expiresAt = "expires_at"
    case usedAt = "used_at"
    case createdAt = "created_at"
  }
}

/// The branding on a new connect session.
public struct CreateConnectSessionBranding: Codable, Sendable {
  public var name: String?
  public var logoURL: String?

  public init(name: String? = nil, logoURL: String? = nil) {
    self.name = name
    self.logoURL = logoURL
  }

  enum CodingKeys: String, CodingKey {
    case name
    case logoURL = "logoUrl"
  }
}

/// The body of ``ConnectSessionsResource/create(_:)``.
public struct CreateConnectSessionRequest: Codable, Sendable {
  public var workspaceID: String?
  /// Your own id for the user who will connect.
  public var externalUserID: String
  /// The networks the page offers.
  public var platforms: [Platform]
  /// Where the user lands after connecting.
  public var redirectURL: String?
  public var branding: CreateConnectSessionBranding?

  public init(
    externalUserID: String, platforms: [Platform], workspaceID: String? = nil,
    redirectURL: String? = nil, branding: CreateConnectSessionBranding? = nil
  ) {
    self.workspaceID = workspaceID
    self.externalUserID = externalUserID
    self.platforms = platforms
    self.redirectURL = redirectURL
    self.branding = branding
  }

  enum CodingKeys: String, CodingKey {
    case platforms, branding
    case workspaceID = "workspaceId"
    case externalUserID = "externalUserId"
    case redirectURL = "redirectUrl"
  }
}
