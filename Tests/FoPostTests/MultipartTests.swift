import Foundation
import XCTest

@testable import FoPost

final class MultipartTests: XCTestCase {
  func testFormShape() {
    var form = MultipartForm(boundary: "TESTBOUNDARY")
    form.addField("workspaceId", "ws_1")
    form.addField("skipped", nil)
    form.addFile(field: "files", filename: "chart.png", data: Data("PNGBYTES".utf8))

    XCTAssertEqual(form.contentType, "multipart/form-data; boundary=TESTBOUNDARY")
    XCTAssertEqual(
      String(data: form.encoded(), encoding: .utf8),
      """
      --TESTBOUNDARY\r
      Content-Disposition: form-data; name="workspaceId"\r
      \r
      ws_1\r
      --TESTBOUNDARY\r
      Content-Disposition: form-data; name="files"; filename="chart.png"\r
      Content-Type: image/png\r
      \r
      PNGBYTES\r
      --TESTBOUNDARY--\r\n
      """)
  }

  func testMediaUploadPostsMultipart() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":[{"id":"med_1","type":"image","name":"chart.png","url":"https://cdn.fopost.test/chart.png","size":8}]}"#
      )
    ])
    let client = try makeStubClient()

    let uploaded = try await client.media.upload(
      workspaceID: "ws_1",
      file: UploadFile(name: "chart.png", data: Data("PNGBYTES".utf8)))

    XCTAssertEqual(uploaded.id, "med_1")
    XCTAssertEqual(uploaded.asMediaItem().url, "https://cdn.fopost.test/chart.png")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/media/upload")
    let contentType = try XCTUnwrap(request.headers["Content-Type"])
    XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))
    XCTAssertTrue(request.bodyString.contains(#"name="workspaceId""#))
    XCTAssertTrue(request.bodyString.contains(#"name="files"; filename="chart.png""#))
    XCTAssertTrue(request.bodyString.contains("Content-Type: image/png"))
    XCTAssertTrue(request.bodyString.contains("PNGBYTES"))
  }

  func testBulkImportUploadsTheCSVUnderFile() async throws {
    StubURLProtocol.script([
      .json(#"{"total_rows":2,"valid_rows":2,"invalid_rows":0,"rows":[]}"#)
    ])
    let client = try makeStubClient()

    let validation = try await client.posts.validateBulkImport(
      workspaceID: "ws_1", csv: Data("content,schedule_at\nHello,2026-09-01 10:00\n".utf8))

    XCTAssertEqual(validation.totalRows, 2)
    let body = try XCTUnwrap(StubURLProtocol.requests.first).bodyString
    XCTAssertTrue(body.contains(#"name="workspace_id""#))
    XCTAssertTrue(body.contains(#"name="file"; filename="posts.csv""#))
    XCTAssertTrue(body.contains("Content-Type: text/csv"))
  }
}
