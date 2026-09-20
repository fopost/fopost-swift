import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// One prepared call, held so a retry can replay it byte for byte.
struct HTTPRequest: Sendable {
  var method: String
  var path: String
  var query: [URLQueryItem] = []
  var body: Data?
  var contentType: String?
  /// Peel a `{"data": ...}` envelope off the response before decoding.
  var unwrap: Bool = true
}

/// Signs, sends, retries, and decodes. Every resource goes through it.
final class Transport: @unchecked Sendable {
  private let apiKey: String
  private let configuration: FoPostConfiguration
  private let session: URLSession

  init(apiKey: String, configuration: FoPostConfiguration, session: URLSession) {
    self.apiKey = apiKey
    self.configuration = configuration
    self.session = session
  }

  var baseURL: URL { configuration.baseURL }

  @discardableResult
  func send<Response: Decodable>(_ request: HTTPRequest, as type: Response.Type) async throws
    -> Response
  {
    let (data, response) = try await perform(request)
    return try decode(Response.self, from: data, response: response, unwrap: request.unwrap)
  }

  func send(_ request: HTTPRequest) async throws {
    _ = try await perform(request)
  }

  /// Sends bytes to a URL outside the API, unsigned and unretried, as a
  /// presigned upload needs.
  func putRaw(to url: URL, method: String, headers: [String: String], body: Data) async throws
  {
    var urlRequest = URLRequest(url: url, timeoutInterval: configuration.timeout)
    urlRequest.httpMethod = method
    urlRequest.httpBody = body
    for (name, value) in headers {
      urlRequest.setValue(value, forHTTPHeaderField: name)
    }
    urlRequest.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
    do {
      let (data, response) = try await session.data(for: urlRequest)
      guard let http = response as? HTTPURLResponse else {
        throw FoPostError.decoding(message: "The response was not an HTTP response.", body: data)
      }
      guard (200...299).contains(http.statusCode) else {
        throw Transport.error(from: http, body: data)
      }
    } catch let error as URLError {
      if error.code == .cancelled { throw CancellationError() }
      throw FoPostError.transport(error)
    }
  }

  // MARK: - Sending

  private func perform(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
    let url = try buildURL(path: request.path, query: request.query)
    var attempt = 1

    while true {
      try Task.checkCancellation()

      var urlRequest = URLRequest(url: url, timeoutInterval: configuration.timeout)
      urlRequest.httpMethod = request.method
      urlRequest.httpBody = request.body
      urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
      urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
      urlRequest.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
      if let contentType = request.contentType {
        urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
      }

      do {
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
          throw FoPostError.decoding(
            message: "The response was not an HTTP response.", body: data)
        }
        guard (200...299).contains(http.statusCode) else {
          let error = Transport.error(from: http, body: data)
          guard attempt < configuration.maxAttempts,
            Transport.isRetryable(status: http.statusCode)
          else { throw error }
          try await sleep(
            seconds: Transport.retryDelay(
              attempt: attempt, retryAfter: error.retryAfter,
              base: configuration.retryBaseDelay,
              cap: configuration.retryMaximumDelay))
          attempt += 1
          continue
        }
        return (data, http)
      } catch let error as FoPostError {
        throw error
      } catch let error as URLError {
        // A cancelled request is the caller's decision, not a blip.
        if error.code == .cancelled { throw CancellationError() }
        guard attempt < configuration.maxAttempts else { throw FoPostError.transport(error) }
        try await sleep(
          seconds: Transport.retryDelay(
            attempt: attempt, retryAfter: nil, base: configuration.retryBaseDelay,
            cap: configuration.retryMaximumDelay))
        attempt += 1
      } catch is CancellationError {
        throw CancellationError()
      }
    }
  }

  private func buildURL(path: String, query: [URLQueryItem]) throws -> URL {
    let base = configuration.baseURL.absoluteString.trimmingTrailingSlashes()
    let suffix = path.hasPrefix("/") ? path : "/" + path
    guard var components = URLComponents(string: base + suffix) else {
      throw FoPostError.configuration(message: "Could not build a URL for \(path).")
    }
    if !query.isEmpty {
      components.queryItems = (components.queryItems ?? []) + query
    }
    guard let url = components.url else {
      throw FoPostError.configuration(message: "Could not build a URL for \(path).")
    }
    return url
  }

  // MARK: - Decoding

  private func decode<Response: Decodable>(
    _ type: Response.Type, from data: Data, response: HTTPURLResponse, unwrap: Bool
  ) throws -> Response {
    if data.isEmpty || response.statusCode == 204 {
      if let empty = Empty() as? Response { return empty }
      throw FoPostError.decoding(message: "The API answered with an empty body.", body: data)
    }
    do {
      if unwrap, let probe = try? Coding.decoder.decode(EnvelopeProbe.self, from: data),
        probe.isEnveloped
      {
        return try Coding.decoder.decode(DataEnvelope<Response>.self, from: data).data
      }
      return try Coding.decoder.decode(Response.self, from: data)
    } catch let error as DecodingError {
      throw FoPostError.decoding(
        message: "Could not decode \(Response.self): \(error)", body: data)
    }
  }

  static func error(from response: HTTPURLResponse, body: Data) -> FoPostError {
    var code: String?
    var message: String?
    if let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
      code = object["error"] as? String
      message = object["message"] as? String
    }
    let details = FoPostAPIErrorDetails(
      status: response.statusCode,
      code: code,
      message: message ?? code
        ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
      body: body,
      rateLimit: RateLimit.from(headers: response.allHeaderFields),
      retryAfter: retryAfter(headers: response.allHeaderFields)
        ?? numericRetryAfter(body: body)
    )
    return FoPostError.from(status: response.statusCode, details: details)
  }

  /// `Retry-After` arrives as delta-seconds or as an HTTP date.
  private static func retryAfter(headers: [AnyHashable: Any]) -> TimeInterval? {
    guard let raw = headers.headerString("Retry-After") else { return nil }
    if let seconds = Double(raw) { return seconds > 0 ? seconds : nil }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    guard let target = formatter.date(from: raw) else { return nil }
    let wait = target.timeIntervalSinceNow
    return wait > 0 ? wait : nil
  }

  /// Analytics collection reports its throttle in the body instead.
  private static func numericRetryAfter(body: Data) -> TimeInterval? {
    guard let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
      let seconds = object["retryAfter"] as? NSNumber
    else { return nil }
    return seconds.doubleValue > 0 ? seconds.doubleValue : nil
  }

  // MARK: - Retrying

  static func isRetryable(status: Int) -> Bool { status == 429 || status >= 500 }

  /// Exponential backoff, unless the API named a wait of its own.
  static func retryDelay(
    attempt: Int, retryAfter: TimeInterval?,
    base: TimeInterval = FoPostConfiguration.baseRetryDelay,
    cap: TimeInterval = FoPostConfiguration.maximumRetryDelay
  ) -> TimeInterval {
    if let retryAfter, retryAfter > 0 { return min(retryAfter, cap) }
    return min(base * pow(2, Double(attempt - 1)), cap)
  }

  private func sleep(seconds: TimeInterval) async throws {
    guard seconds > 0 else { return }
    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
  }
}
