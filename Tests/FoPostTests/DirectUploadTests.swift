import Foundation
import XCTest

@testable import FoPost

final class DirectUploadTests: XCTestCase {
  func testUploadDirectPresignsPutsAndCompletes() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":{"uploadId":"up_1","uploadUrl":"https://bucket.fopost.test/up_1?sig=abc","method":"PUT","headers":{"Content-Type":"image/png"},"expiresAt":"2026-09-19T12:00:00Z"}}"#,
        status: 201),
      StubResponse(status: 200, headers: [:], body: Data()),
      .json(
        #"{"data":{"id":"med_1","type":"image","name":"chart.png","url":"https://cdn.fopost.test/chart.png","previewUrl":"https://api.fopost.test/v1/media/med_1/file","size":8}}"#,
        status: 201),
    ])
    let client = try makeStubClient()

    let uploaded = try await client.media.uploadDirect(
      workspaceID: "ws_1", filename: "chart.png", mimeType: "image/png",
      data: Data("PNGBYTES".utf8))

    XCTAssertEqual(uploaded.id, "med_1")
    XCTAssertEqual(uploaded.asMediaItem().url, "https://cdn.fopost.test/chart.png")

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.count, 3)

    let presign = try XCTUnwrap(requests.first)
    XCTAssertEqual(presign.method, "POST")
    XCTAssertEqual(presign.path, "/v1/media/presign")
    XCTAssertEqual(presign.headers["X-API-Key"], "fp_test_key")
    let body = try presign.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["filename"] as? String, "chart.png")
    XCTAssertEqual(body["mimeType"] as? String, "image/png")
    XCTAssertEqual(body["size"] as? Int, 8)

    let put = requests[1]
    XCTAssertEqual(put.method, "PUT")
    XCTAssertEqual(put.url.absoluteString, "https://bucket.fopost.test/up_1?sig=abc")
    XCTAssertEqual(put.headers["Content-Type"], "image/png")
    XCTAssertEqual(put.headers["Content-Length"], "8")
    XCTAssertNil(put.headers["X-API-Key"])
    XCTAssertEqual(put.bodyString, "PNGBYTES")

    let complete = requests[2]
    XCTAssertEqual(complete.method, "POST")
    XCTAssertEqual(complete.path, "/v1/media/presign/up_1/complete")
    XCTAssertEqual(complete.headers["X-API-Key"], "fp_test_key")
  }

  func testUploadDirectThrowsWhenThePutIsRejected() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":{"uploadId":"up_1","uploadUrl":"https://bucket.fopost.test/up_1","method":"PUT","headers":{"Content-Type":"image/png"}}}"#,
        status: 201),
      StubResponse(status: 403, headers: [:], body: Data("AccessDenied".utf8)),
    ])
    let client = try makeStubClient()

    do {
      _ = try await client.media.uploadDirect(
        workspaceID: "ws_1", filename: "chart.png", mimeType: "image/png",
        data: Data("PNGBYTES".utf8))
      XCTFail("Expected the rejected PUT to throw")
    } catch let error as FoPostError {
      XCTAssertEqual(error.status, 403)
    }
    XCTAssertEqual(StubURLProtocol.requests.count, 2)
  }
}
