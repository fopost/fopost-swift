import Foundation

/// Shared plumbing for the namespaced resources hanging off ``FoPostClient``.
protocol Resource: Sendable {
  var transport: Transport { get }
}

extension Resource {
  func httpGet<Response: Decodable>(
    _ path: String, query: Query = Query(), unwrap: Bool = true, as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      HTTPRequest(method: "GET", path: path, query: query.items, unwrap: unwrap),
      as: Response.self)
  }

  func httpPost<Response: Decodable>(
    _ path: String, body: (any Encodable & Sendable)? = nil, query: Query = Query(),
    unwrap: Bool = true, as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      try request(method: "POST", path: path, body: body, query: query, unwrap: unwrap),
      as: Response.self)
  }

  func httpPut<Response: Decodable>(
    _ path: String, body: (any Encodable & Sendable)? = nil, unwrap: Bool = true,
    as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      try request(method: "PUT", path: path, body: body, query: Query(), unwrap: unwrap),
      as: Response.self)
  }

  func httpPatch<Response: Decodable>(
    _ path: String, body: (any Encodable & Sendable)? = nil, query: Query = Query(),
    unwrap: Bool = true, as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      try request(method: "PATCH", path: path, body: body, query: query, unwrap: unwrap),
      as: Response.self)
  }

  func httpDelete(_ path: String) async throws {
    try await transport.send(HTTPRequest(method: "DELETE", path: path, unwrap: false))
  }

  func httpDelete<Response: Decodable>(
    _ path: String, query: Query = Query(), as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      HTTPRequest(method: "DELETE", path: path, query: query.items, unwrap: true),
      as: Response.self)
  }

  /// A DELETE that carries a body, for routes whose scope travels in one.
  func httpDelete<Response: Decodable>(
    _ path: String, body: (any Encodable & Sendable)?, query: Query = Query(),
    as type: Response.Type
  ) async throws -> Response {
    try await transport.send(
      try request(method: "DELETE", path: path, body: body, query: query, unwrap: true),
      as: Response.self)
  }

  func httpUpload<Response: Decodable>(_ path: String, form: MultipartForm, as type: Response.Type)
    async throws -> Response
  {
    try await transport.send(
      HTTPRequest(
        method: "POST", path: path, body: form.encoded(), contentType: form.contentType,
        unwrap: true),
      as: Response.self)
  }

  private func request(
    method: String, path: String, body: (any Encodable & Sendable)?, query: Query, unwrap: Bool
  ) throws -> HTTPRequest {
    var request = HTTPRequest(
      method: method, path: path, query: query.items, unwrap: unwrap)
    if let body {
      do {
        request.body = try Coding.encoder.encode(body)
      } catch {
        throw FoPostError.encoding(message: "Could not encode the request body: \(error)")
      }
    } else {
      request.body = Data("{}".utf8)
    }
    request.contentType = "application/json"
    return request
  }
}

/// Percent-encodes an id for use in a path segment.
func escapePath(_ value: String) -> String {
  value.addingPercentEncoding(withAllowedCharacters: .fopostPathSegment) ?? value
}

extension CharacterSet {
  static let fopostPathSegment: CharacterSet = {
    var allowed = CharacterSet.urlPathAllowed
    allowed.remove(charactersIn: "/")
    return allowed
  }()
}
