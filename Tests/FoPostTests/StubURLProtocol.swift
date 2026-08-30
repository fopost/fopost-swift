import Foundation
import XCTest

@testable import FoPost

/// One canned response, and the request that asked for it.
struct StubResponse {
  var status: Int = 200
  var headers: [String: String] = ["Content-Type": "application/json"]
  var body: Data = Data()
  /// Thrown instead of answering, to exercise the network-error path.
  var error: URLError?

  static func json(_ string: String, status: Int = 200, headers: [String: String] = [:])
    -> StubResponse
  {
    var merged = ["Content-Type": "application/json"]
    for (key, value) in headers { merged[key] = value }
    return StubResponse(status: status, headers: merged, body: Data(string.utf8))
  }

  static func failure(_ code: URLError.Code) -> StubResponse {
    StubResponse(error: URLError(code))
  }
}

/// A canned exchange: what came in, and what went back.
struct RecordedRequest {
  let method: String
  let url: URL
  let headers: [String: String]
  let body: Data?

  var path: String { url.path }
  var query: [String: String] {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    return Dictionary(items.compactMap { item in item.value.map { (item.name, $0) } }) {
      _, last in last
    }
  }

  var bodyString: String { body.flatMap { String(data: $0, encoding: .utf8) } ?? "" }

  func bodyJSON() throws -> [String: Any] {
    guard let body, let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    else { return [:] }
    return object
  }
}

/// Answers every request from a queued script, so the tests never touch a
/// network. Injected through `URLSessionConfiguration.protocolClasses`.
final class StubURLProtocol: URLProtocol {
  private static let state = State()

  final class State: @unchecked Sendable {
    private let lock = NSLock()
    private var queue: [StubResponse] = []
    private var recorded: [RecordedRequest] = []

    func script(_ responses: [StubResponse]) {
      lock.lock()
      defer { lock.unlock() }
      queue = responses
      recorded = []
    }

    func next() -> StubResponse {
      lock.lock()
      defer { lock.unlock() }
      guard !queue.isEmpty else {
        return StubResponse(status: 500, body: Data("{\"error\":\"no_stub\"}".utf8))
      }
      return queue.count == 1 ? queue[0] : queue.removeFirst()
    }

    func record(_ request: RecordedRequest) {
      lock.lock()
      defer { lock.unlock() }
      recorded.append(request)
    }

    var requests: [RecordedRequest] {
      lock.lock()
      defer { lock.unlock() }
      return recorded
    }
  }

  /// Queues the responses the next requests receive. The last one repeats.
  static func script(_ responses: [StubResponse]) { state.script(responses) }

  /// Every request the session sent since the last `script(_:)`.
  static var requests: [RecordedRequest] { state.requests }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    let body = request.httpBody ?? request.httpBodyStream.map(StubURLProtocol.drain)
    StubURLProtocol.state.record(
      RecordedRequest(
        method: request.httpMethod ?? "GET",
        url: request.url!,
        headers: request.allHTTPHeaderFields ?? [:],
        body: body))

    let stub = StubURLProtocol.state.next()
    if let error = stub.error {
      client?.urlProtocol(self, didFailWithError: error)
      return
    }
    let response = HTTPURLResponse(
      url: request.url!, statusCode: stub.status, httpVersion: "HTTP/1.1",
      headerFields: stub.headers)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: stub.body)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}

  private static func drain(_ stream: InputStream) -> Data {
    stream.open()
    defer { stream.close() }
    var data = Data()
    let size = 4096
    var buffer = [UInt8](repeating: 0, count: size)
    while stream.hasBytesAvailable {
      let read = stream.read(&buffer, maxLength: size)
      guard read > 0 else { break }
      data.append(buffer, count: read)
    }
    return data
  }
}

extension XCTestCase {
  /// A client wired to the stub, with retry waits short enough for a test.
  func makeStubClient(
    apiKey: String = "fp_test_key",
    maxAttempts: Int = FoPostConfiguration.defaultMaxAttempts
  ) throws -> FoPostClient {
    let sessionConfiguration = URLSessionConfiguration.ephemeral
    sessionConfiguration.protocolClasses = [StubURLProtocol.self]
    let configuration = FoPostConfiguration(
      baseURL: URL(string: "https://api.fopost.test/v1")!,
      maxAttempts: maxAttempts,
      retryBaseDelay: 0.001,
      retryMaximumDelay: 0.01)
    return try FoPostClient(
      apiKey: apiKey, configuration: configuration,
      session: URLSession(configuration: sessionConfiguration))
  }
}
