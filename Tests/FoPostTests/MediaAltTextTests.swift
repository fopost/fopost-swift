import Foundation
import XCTest

@testable import FoPost

/// Generated alt text: the path and the snake_case answer.
final class MediaAltTextTests: XCTestCase {
  func testGenerateAltTextPostsToTheMediaPath() async throws {
    StubURLProtocol.script([
      .json(#"{"alt_text":"A red bicycle by a wall.","alt_text_source":"ai","tags":["bicycle"]}"#)
    ])
    let client = try makeStubClient()

    let alt = try await client.media.generateAltText("med_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/media/med_1/alt-text")
    XCTAssertEqual(alt.altText, "A red bicycle by a wall.")
    XCTAssertEqual(alt.altTextSource, "ai")
    XCTAssertEqual(alt.tags, ["bicycle"])
  }
}
