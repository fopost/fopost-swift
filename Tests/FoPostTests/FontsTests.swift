import Foundation
import XCTest

@testable import FoPost

/// Fonts: the list shape, the multipart upload fields, and the 204 delete.
final class FontsTests: XCTestCase {
  private static let uploaded = """
    {"id":"font_1","family":"Brand Sans","style":"italic","weight":700,"format":"woff2",
     "file_url":"https://api.fopost.test/v1/fonts/font_1/file","created_at":"2026-11-01T00:00:00.000Z"}
    """

  func testListReadsTheLibraryAndTheUploadedFonts() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"library":[{"slug":"geist","family":"Geist","category":"sans-serif","scripts":["latin"],
          "weights":[400,700],"files":[{"path":"geist/latin.woff2","subset":"latin","weight":400,
          "style":"normal","unicode_range":"U+0000-00FF"}]}],
         "uploaded":[\(Self.uploaded)]}
        """)
    ])
    let client = try makeStubClient()

    let fonts = try await client.fonts.list(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/fonts")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")

    XCTAssertEqual(fonts.library.first?.slug, "geist")
    XCTAssertEqual(fonts.library.first?.files?.first?.unicodeRange, "U+0000-00FF")
    XCTAssertEqual(fonts.uploaded.first?.style, .italic)
    XCTAssertEqual(fonts.uploaded.first?.weight, 700)
    XCTAssertEqual(
      fonts.uploaded.first?.fileURL, "https://api.fopost.test/v1/fonts/font_1/file")
  }

  func testListWithoutAWorkspaceSendsNoQuery() async throws {
    StubURLProtocol.script([.json(#"{"library":[],"uploaded":[]}"#)])
    let client = try makeStubClient()

    _ = try await client.fonts.list()

    XCTAssertTrue(try XCTUnwrap(StubURLProtocol.requests.first).query.isEmpty)
  }

  func testUploadSendsAMultipartFormWithTheFontFields() async throws {
    StubURLProtocol.script([.json(Self.uploaded, status: 201)])
    let client = try makeStubClient()

    let font = try await client.fonts.upload(
      workspaceID: "ws_1", filename: "brand.woff2", data: Data("wOF2".utf8),
      family: "Brand Sans", weight: 700, style: .italic)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/fonts")
    XCTAssertTrue(
      request.headers["Content-Type"]?.hasPrefix("multipart/form-data; boundary=") ?? false)
    let body = request.bodyString
    XCTAssertTrue(body.contains("name=\"workspace_id\"\r\n\r\nws_1\r\n"))
    XCTAssertTrue(body.contains("name=\"family\"\r\n\r\nBrand Sans\r\n"))
    XCTAssertTrue(body.contains("name=\"weight\"\r\n\r\n700\r\n"))
    XCTAssertTrue(body.contains("name=\"style\"\r\n\r\nitalic\r\n"))
    XCTAssertTrue(body.contains("name=\"file\"; filename=\"brand.woff2\""))
    XCTAssertTrue(body.contains("wOF2"))

    XCTAssertEqual(font.id, "font_1")
    XCTAssertEqual(font.family, "Brand Sans")
  }

  func testUploadFromDiskReadsTheFileAndLeavesOptionalFieldsOut() async throws {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("fopost-font-\(UUID().uuidString).ttf")
    try Data("ttf-bytes".utf8).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    StubURLProtocol.script([.json(Self.uploaded, status: 201)])
    let client = try makeStubClient()

    _ = try await client.fonts.upload(workspaceID: "ws_1", fileURL: url)

    let body = try XCTUnwrap(StubURLProtocol.requests.first).bodyString
    XCTAssertTrue(body.contains("filename=\"\(url.lastPathComponent)\""))
    XCTAssertTrue(body.contains("ttf-bytes"))
    XCTAssertFalse(body.contains("name=\"family\""))
    XCTAssertFalse(body.contains("name=\"weight\""))
    XCTAssertFalse(body.contains("name=\"style\""))
  }

  func testDeleteAcceptsANoContentAnswer() async throws {
    StubURLProtocol.script([StubResponse(status: 204)])
    let client = try makeStubClient()

    try await client.fonts.delete("font_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/fonts/font_1")
  }
}
