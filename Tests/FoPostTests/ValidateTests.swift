import Foundation
import XCTest

@testable import FoPost

final class ValidateTests: XCTestCase {
  func testPostSendsTheBodyAndDecodesPerPlatformReadiness() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"ready":false,"platforms":[
        {"platform":"twitter","ready":false,"issues":["Text exceeds the platform limit"],"score":42,
        "signals":[{"level":"warn","code":"over_length","message":"Too long"}]},
        {"platform":"linkedin","ready":true,"issues":[],"signals":[]}]}}
        """)
    ])
    let client = try makeStubClient()

    let result = try await client.validate.post(
      ValidatePostRequest(
        content: "Ship day",
        media: [
          ValidateMediaItem(
            url: "https://yourbrand.com/chart.png", mimeType: "image/png", size: 1024)
        ],
        platforms: [.twitter, .linkedin]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/validate/post")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["content"] as? String, "Ship day")
    XCTAssertEqual(body["platforms"] as? [String], ["twitter", "linkedin"])
    let media = try XCTUnwrap(body["media"] as? [[String: Any]])
    XCTAssertEqual(media.count, 1)
    XCTAssertEqual(media[0]["url"] as? String, "https://yourbrand.com/chart.png")
    XCTAssertEqual(media[0]["mime_type"] as? String, "image/png")
    XCTAssertEqual(media[0]["size"] as? Int, 1024)

    XCTAssertEqual(result.ready, false)
    XCTAssertEqual(result.platforms?.count, 2)
    XCTAssertEqual(result.platforms?[0].platform, "twitter")
    XCTAssertEqual(result.platforms?[0].issues, ["Text exceeds the platform limit"])
    XCTAssertEqual(result.platforms?[0].score, 42)
    XCTAssertEqual(result.platforms?[0].signals?.first?.code, "over_length")
    XCTAssertEqual(result.platforms?[1].ready, true)
    XCTAssertNil(result.platforms?[1].score)
  }

  func testLengthSendsTheBodyAndDecodesLimits() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"ok":false,"platforms":[
        {"platform":"twitter","length":300,"limit":280,"unit":"chars","ok":false,
        "signals":[{"level":"warn","code":"over_length","message":"Over by 20"}]},
        {"platform":"bluesky","length":300,"limit":null,"unit":"bytes","ok":true,"signals":[]}]}}
        """)
    ])
    let client = try makeStubClient()

    let result = try await client.validate.length(
      ValidateLengthRequest(text: "Ship day", platforms: [.twitter, .bluesky]))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/validate/length")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["text"] as? String, "Ship day")
    XCTAssertEqual(body["platforms"] as? [String], ["twitter", "bluesky"])

    XCTAssertEqual(result.ok, false)
    XCTAssertEqual(result.platforms?[0].length, 300)
    XCTAssertEqual(result.platforms?[0].limit, 280)
    XCTAssertEqual(result.platforms?[0].unit, "chars")
    XCTAssertEqual(result.platforms?[0].ok, false)
    XCTAssertNil(result.platforms?[1].limit)
    XCTAssertEqual(result.platforms?[1].unit, "bytes")
  }

  func testMediaSendsTheURLAndDecodesTheReport() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":{"ok":true,"issues":[],"name":"chart.png","size":2048,"mime_type":"image/png","type":"image"}}"#
      )
    ])
    let client = try makeStubClient()

    let result = try await client.validate.media(
      ValidateMediaRequest(url: "https://yourbrand.com/chart.png"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/validate/media")
    XCTAssertEqual(try request.bodyJSON()["url"] as? String, "https://yourbrand.com/chart.png")

    XCTAssertEqual(result.ok, true)
    XCTAssertEqual(result.issues, [])
    XCTAssertEqual(result.name, "chart.png")
    XCTAssertEqual(result.size, 2048)
    XCTAssertEqual(result.mimeType, "image/png")
    XCTAssertEqual(result.type, "image")
  }
}
