import Foundation

// MARK: - Profile

/// The business profile on a WhatsApp number, plus how the platform rates it.
public struct WhatsappProfile: Codable, Sendable, Hashable {
  public let about: String?
  public let address: String?
  public let description: String?
  public let email: String?
  public let vertical: String?
  public let websites: [String]?
  public let profilePictureUrl: String?
  public let displayName: String?
  /// The platform's review state for the display name.
  public let displayNameStatus: String?
  public let username: String?
  public let qualityRating: String?
  public let messagingLimitTier: String?
}

/// A partial profile update: omitted fields keep their value.
public struct UpdateWhatsappProfileRequest: Codable, Sendable, Hashable {
  public var about: String?
  public var address: String?
  public var description: String?
  public var vertical: String?
  public var websites: [String]?
  /// A library media id, uploaded first.
  public var profilePictureMediaID: String?

  public init(
    about: String? = nil, address: String? = nil, description: String? = nil,
    vertical: String? = nil, websites: [String]? = nil, profilePictureMediaID: String? = nil
  ) {
    self.about = about
    self.address = address
    self.description = description
    self.vertical = vertical
    self.websites = websites
    self.profilePictureMediaID = profilePictureMediaID
  }

  enum CodingKeys: String, CodingKey {
    case about, address, description, vertical, websites
    case profilePictureMediaID = "profile_picture_media_id"
  }
}

// MARK: - Templates

/// A message template. `status` is the review outcome the platform assigned;
/// nothing marks a template approved but the platform.
public struct WhatsappTemplate: Codable, Sendable, Hashable {
  public let id: String
  public let name: String
  public let language: String
  public let category: String
  public let status: String
  public let rejectedReason: String?
  public let components: [JSONValue]?
  public let qualityScore: String?
}

/// Files a template for review.
public struct CreateWhatsappTemplateRequest: Codable, Sendable, Hashable {
  /// Lowercase letters, digits and underscores.
  public var name: String
  public var language: String
  /// `MARKETING`, `UTILITY` or `AUTHENTICATION`.
  public var category: String
  public var components: [JSONValue]
  /// Lets the platform re-file a template it judges to be another category.
  public var allowCategoryChange: Bool?

  public init(
    name: String, language: String, category: String, components: [JSONValue],
    allowCategoryChange: Bool? = nil
  ) {
    self.name = name
    self.language = language
    self.category = category
    self.components = components
    self.allowCategoryChange = allowCategoryChange
  }

  enum CodingKeys: String, CodingKey {
    case name, language, category, components
    case allowCategoryChange = "allow_category_change"
  }
}

/// Creates a template from one of the platform's library entries.
public struct ImportWhatsappTemplateRequest: Codable, Sendable, Hashable {
  public var libraryTemplateName: String
  public var name: String
  public var language: String
  public var category: String
  public var libraryTemplateButtonInputs: [JSONValue]?

  public init(
    libraryTemplateName: String, name: String, language: String, category: String,
    libraryTemplateButtonInputs: [JSONValue]? = nil
  ) {
    self.libraryTemplateName = libraryTemplateName
    self.name = name
    self.language = language
    self.category = category
    self.libraryTemplateButtonInputs = libraryTemplateButtonInputs
  }

  enum CodingKeys: String, CodingKey {
    case libraryTemplateName = "library_template_name"
    case name, language, category
    case libraryTemplateButtonInputs = "library_template_button_inputs"
  }
}

/// Edits a template. The name cannot change; create a new one instead.
public struct UpdateWhatsappTemplateRequest: Codable, Sendable, Hashable {
  public var category: String?
  public var components: [JSONValue]?

  public init(category: String? = nil, components: [JSONValue]? = nil) {
    self.category = category
    self.components = components
  }
}

// MARK: - Groups

/// A group on the business number. Participation is invite-only: no endpoint
/// adds anyone, so `inviteLink` is how they join.
public struct WhatsappGroup: Codable, Sendable, Hashable {
  public let id: String
  public let subject: String
  public let description: String?
  public let participantCount: Int?
  public let inviteLink: String?
  public let createdAt: Date?
}

/// Creates or updates a group.
public struct WhatsappGroupRequest: Codable, Sendable, Hashable {
  public var subject: String?
  public var description: String?

  public init(subject: String? = nil, description: String? = nil) {
    self.subject = subject
    self.description = description
  }
}

// MARK: - Blocking

/// What the platform took and what it refused.
public struct WhatsappBlockResult: Codable, Sendable, Hashable {
  public let blocked: [String]?
  public let unblocked: [String]?
  public let failed: [String]?
}

// MARK: - Commerce

/// Whether the cart and catalog show on the number.
public struct WhatsappCommerceSettings: Codable, Sendable, Hashable {
  public let cartEnabled: Bool?
  public let catalogVisible: Bool?
  public let catalogId: String?
}

/// Turns the cart or the catalog on or off.
public struct UpdateWhatsappCommerceRequest: Codable, Sendable, Hashable {
  public var cartEnabled: Bool?
  public var catalogVisible: Bool?

  public init(cartEnabled: Bool? = nil, catalogVisible: Bool? = nil) {
    self.cartEnabled = cartEnabled
    self.catalogVisible = catalogVisible
  }

  enum CodingKeys: String, CodingKey {
    case cartEnabled = "is_cart_enabled"
    case catalogVisible = "is_catalog_visible"
  }
}

// MARK: - Flows

/// One problem the platform found in a flow definition.
public struct WhatsappFlowValidationError: Codable, Sendable, Hashable {
  public let error: String
  public let message: String
}

/// An in-chat form. The platform validates it and owns its status.
public struct WhatsappFlow: Codable, Sendable, Hashable {
  public let id: String
  public let name: String
  /// `DRAFT`, `PUBLISHED`, `DEPRECATED` or `BLOCKED`.
  public let status: String
  public let categories: [String]?
  public let validationErrors: [WhatsappFlowValidationError]?
  public let endpointUri: String?
  public let jsonVersion: String?
  public let previewUrl: String?
  public let previewExpiresAt: Date?
}

/// Creates a draft flow; its screens are uploaded separately.
public struct CreateWhatsappFlowRequest: Codable, Sendable, Hashable {
  public var name: String
  public var categories: [String]
  /// Where the platform calls back for a flow that reads live data.
  public var endpointURI: String?
  public var cloneFlowID: String?

  public init(
    name: String, categories: [String], endpointURI: String? = nil, cloneFlowID: String? = nil
  ) {
    self.name = name
    self.categories = categories
    self.endpointURI = endpointURI
    self.cloneFlowID = cloneFlowID
  }

  enum CodingKeys: String, CodingKey {
    case name, categories
    case endpointURI = "endpoint_uri"
    case cloneFlowID = "clone_flow_id"
  }
}

/// Changes a flow's metadata, not its screens.
public struct UpdateWhatsappFlowRequest: Codable, Sendable, Hashable {
  public var name: String?
  public var categories: [String]?
  public var endpointURI: String?

  public init(name: String? = nil, categories: [String]? = nil, endpointURI: String? = nil) {
    self.name = name
    self.categories = categories
    self.endpointURI = endpointURI
  }

  enum CodingKeys: String, CodingKey {
    case name, categories
    case endpointURI = "endpoint_uri"
  }
}

/// The platform's verdict on an uploaded definition. It answers with the errors
/// rather than refusing the upload, so they arrive as data.
public struct WhatsappFlowJSONResult: Codable, Sendable, Hashable {
  public let success: Bool
  public let validationErrors: [WhatsappFlowValidationError]?
}

/// What one person submitted through a flow.
public struct WhatsappFlowResponse: Codable, Sendable, Hashable {
  public let messageId: String
  public let waId: String?
  public let flowToken: String?
  public let answers: JSONValue?
  public let respondedAt: Date?
}

/// Whether a business public key is registered. The key itself never comes back.
public struct WhatsappEncryptionKeyStatus: Codable, Sendable, Hashable {
  public let hasKey: Bool
  public let signatureStatus: String?
}

// MARK: - Sandbox

/// A sandbox invitation. Only the last four digits of the tester's number
/// travel; the number itself is never stored.
public struct WhatsappSandboxSession: Codable, Sendable, Hashable {
  public let id: String
  /// `invited`, `active` or `expired`.
  public let status: String
  public let phoneNumberLast4: String
  public let invitedAt: Date?
  public let activatedAt: Date?
  public let expiresAt: Date?
}
