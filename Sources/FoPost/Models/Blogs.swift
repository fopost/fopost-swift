import Foundation

/// A blog on a connected site. `id` is the platform's own id, never a FoPost id.
///
/// A Shopify store reports every blog it has; WordPress has one implicit blog and
/// reports it under the id `default`, so both answer the same shape.
public struct RemoteBlog: Codable, Sendable, Hashable {
  public let id: String
  public let title: String
  public let handle: String?
  public let url: String?
}

/// What state an article is in on the site it lives on.
public enum RemoteArticleStatus: String, Codable, Sendable, Hashable {
  case published, draft, pending, scheduled
}

/// An article that already lives on a connected site, addressed by the platform's
/// own id rather than a FoPost id.
public struct RemoteArticle: Codable, Sendable, Hashable {
  public let id: String
  public let blogID: String?
  public let title: String
  public let bodyHTML: String?
  public let excerpt: String?
  public let status: RemoteArticleStatus
  public let authorName: String?
  public let tags: [String]
  public let imageURL: String?
  public let url: String?
  public let publishedAt: Date?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, title, excerpt, status, tags, url
    case blogID = "blog_id"
    case bodyHTML = "body_html"
    case authorName = "author_name"
    case imageURL = "image_url"
    case publishedAt = "published_at"
    case updatedAt = "updated_at"
  }
}

/// Whether a product is live on the store.
public enum RemoteProductStatus: String, Codable, Sendable, Hashable {
  case active, draft, archived
}

/// A product on a connected store. `price` is the lowest variant price, as a
/// decimal string.
public struct RemoteProduct: Codable, Sendable, Hashable {
  public let id: String
  public let title: String
  public let handle: String?
  public let status: RemoteProductStatus
  public let description: String?
  public let vendor: String?
  public let productType: String?
  public let tags: [String]
  public let imageURL: String?
  public let url: String?
  public let price: String?
  public let currency: String?
  public let updatedAt: Date?

  enum CodingKeys: String, CodingKey {
    case id, title, handle, status, description, vendor, tags, url, price, currency
    case productType = "product_type"
    case imageURL = "image_url"
    case updatedAt = "updated_at"
  }
}

/// The body of ``BlogsResource/createArticle(accountID:blogID:_:)`` and
/// ``BlogsResource/updateArticle(accountID:blogID:articleID:_:)``.
///
/// Only what is set travels, so on an update an omitted field keeps whatever the
/// site already had. A create needs at least `title` and `body`.
public struct ArticleRequest: Codable, Sendable {
  public var title: String?
  /// FoPost body markup; the site's own format is rendered from it.
  public var body: String?
  public var excerpt: String?
  public var status: RemoteArticleStatus?
  public var tags: [String]?
  public var authorName: String?
  /// Public http(s) URL of the featured image.
  public var imageURL: String?

  public init(
    title: String? = nil, body: String? = nil, excerpt: String? = nil,
    status: RemoteArticleStatus? = nil, tags: [String]? = nil, authorName: String? = nil,
    imageURL: String? = nil
  ) {
    self.title = title
    self.body = body
    self.excerpt = excerpt
    self.status = status
    self.tags = tags
    self.authorName = authorName
    self.imageURL = imageURL
  }

  enum CodingKeys: String, CodingKey {
    case title, body, excerpt, status, tags
    case authorName = "author_name"
    case imageURL = "image_url"
  }
}

/// The body of ``BlogsResource/updateProduct(accountID:productID:_:)``. Only what
/// is set travels; set at least one field.
public struct ProductRequest: Codable, Sendable {
  public var title: String?
  /// Body markup, rendered to HTML on the store.
  public var description: String?
  public var status: RemoteProductStatus?
  public var tags: [String]?
  public var productType: String?
  public var vendor: String?

  public init(
    title: String? = nil, description: String? = nil, status: RemoteProductStatus? = nil,
    tags: [String]? = nil, productType: String? = nil, vendor: String? = nil
  ) {
    self.title = title
    self.description = description
    self.status = status
    self.tags = tags
    self.productType = productType
    self.vendor = vendor
  }

  enum CodingKeys: String, CodingKey {
    case title, description, status, tags, vendor
    case productType = "product_type"
  }
}
