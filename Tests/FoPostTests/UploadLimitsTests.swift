import Foundation
import XCTest

@testable import FoPost

final class UploadLimitsTests: XCTestCase {
  private let limitsJSON = """
    {"data":{"maxFileBytes":419430400,"source":"accounts","connectedAccounts":5,
    "largeUploadsEnabled":false,"nextTier":{"upToAccounts":15,"maxFileBytes":2147483648},
    "multipartMaxFileBytes":104857600,"maxFilesPerUpload":5,"directUploadAvailable":true,
    "allowedTypes":["image/png","video/mp4"]}}
    """

  private let postJSON = #"{"data":{"id":"post_1","workspace_id":"ws_1","status":"draft"}}"#

  func testLimitsCallShape() async throws {
    StubURLProtocol.script([.json(limitsJSON)])
    let client = try makeStubClient()

    let limits = try await client.media.limits(workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/media/limits")
    XCTAssertEqual(request.query["workspaceId"], "ws_1")
    XCTAssertEqual(limits.maxFileBytes, 419_430_400)
    XCTAssertEqual(limits.multipartMaxFileBytes, 104_857_600)
    XCTAssertEqual(limits.source, "accounts")
    XCTAssertEqual(limits.nextTier?.upToAccounts, 15)
    XCTAssertEqual(limits.nextTier?.maxFileBytes, 2_147_483_648)
    XCTAssertEqual(limits.allowedTypes, ["image/png", "video/mp4"])
  }

  func testCreateWithSmallFilesSendsOneMultipartRequest() async throws {
    StubURLProtocol.script([.json(limitsJSON), .json(postJSON, status: 201)])
    let client = try makeStubClient()

    let post = try await client.posts.create(
      CreatePostRequest(workspaceID: "ws_1", accounts: ["acc_1"], content: .text("Numbers")),
      files: [UploadFile(name: "chart.png", data: Data("PNGBYTES".utf8))])

    XCTAssertEqual(post.id, "post_1")
    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.count, 2)
    XCTAssertEqual(requests[0].path, "/v1/media/limits")

    let create = requests[1]
    XCTAssertEqual(create.method, "POST")
    XCTAssertEqual(create.path, "/v1/posts")
    XCTAssertTrue(create.headers["Content-Type"]?.hasPrefix("multipart/form-data") ?? false)
    let body = create.bodyString
    XCTAssertTrue(body.contains("name=\"post\""))
    XCTAssertTrue(body.contains("\"workspace_id\":\"ws_1\""))
    XCTAssertTrue(body.contains("name=\"files\"; filename=\"chart.png\""))
    XCTAssertTrue(body.contains("Content-Type: image/png"))
    XCTAssertTrue(body.contains("PNGBYTES"))
  }

  func testCreateWithLargeFileUploadsDirectAndAttachesByURL() async throws {
    let smallCeiling = limitsJSON.replacingOccurrences(
      of: "\"multipartMaxFileBytes\":104857600", with: "\"multipartMaxFileBytes\":4")
    StubURLProtocol.script([
      .json(smallCeiling),
      .json(
        #"{"data":{"uploadId":"up_1","uploadUrl":"https://bucket.fopost.test/up_1","method":"PUT","headers":{"Content-Type":"video/mp4"},"maxFileBytes":419430400}}"#,
        status: 201),
      StubResponse(status: 200, headers: [:], body: Data()),
      .json(
        #"{"data":{"id":"med_1","type":"video","name":"clip.mp4","url":"https://cdn.fopost.test/clip.mp4","size":9}}"#,
        status: 201),
      .json(postJSON, status: 201),
    ])
    let client = try makeStubClient()

    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("fopost-\(UUID().uuidString).mp4")
    try Data("MP4BYTES!".utf8).write(to: fileURL)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    _ = try await client.posts.create(
      CreatePostRequest(workspaceID: "ws_1", accounts: ["acc_1"], content: .text("Clip")),
      files: [UploadFile(contentsOf: fileURL)])

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.map(\.path), [
      "/v1/media/limits", "/v1/media/presign", "/up_1", "/v1/media/presign/up_1/complete",
      "/v1/posts",
    ])

    let presign = try requests[1].bodyJSON()
    XCTAssertEqual(presign["size"] as? Int, 9)
    XCTAssertEqual(presign["mimeType"] as? String, "video/mp4")

    let put = requests[2]
    XCTAssertEqual(put.method, "PUT")
    XCTAssertEqual(put.headers["Content-Length"], "9")
    XCTAssertEqual(put.bodyString, "MP4BYTES!")

    let create = requests[4]
    XCTAssertEqual(create.method, "POST")
    XCTAssertEqual(create.headers["Content-Type"], "application/json")
    let body = try create.bodyJSON()
    let content = try XCTUnwrap(body["content"] as? [[String: Any]])
    let media = try XCTUnwrap(content[0]["media"] as? [[String: Any]])
    XCTAssertEqual(media.count, 1)
    XCTAssertEqual(media[0]["type"] as? String, "video")
    XCTAssertEqual(media[0]["url"] as? String, "https://cdn.fopost.test/clip.mp4")
    XCTAssertEqual(media[0]["name"] as? String, "clip.mp4")
    XCTAssertEqual(media[0]["size"] as? Double, 9)
  }

  func testUpdateWithLargeFileKeepsExistingContent() async throws {
    let smallCeiling = limitsJSON.replacingOccurrences(
      of: "\"multipartMaxFileBytes\":104857600", with: "\"multipartMaxFileBytes\":4")
    StubURLProtocol.script([
      .json(smallCeiling),
      .json(
        #"{"data":{"id":"post_1","workspace_id":"ws_1","content":[{"text":"Keep me","media":[{"type":"image","url":"https://cdn.fopost.test/old.png"}]}]}}"#
      ),
      .json(
        #"{"data":{"uploadId":"up_1","uploadUrl":"https://bucket.fopost.test/up_1","method":"PUT","headers":{}}}"#,
        status: 201),
      StubResponse(status: 200, headers: [:], body: Data()),
      .json(
        #"{"data":{"id":"med_2","type":"image","name":"new.png","url":"https://cdn.fopost.test/new.png","size":8}}"#,
        status: 201),
      .json(postJSON),
    ])
    let client = try makeStubClient()

    _ = try await client.posts.update(
      "post_1", UpdatePostRequest(title: "Retitled"),
      files: [UploadFile(name: "new.png", data: Data("PNGBYTES".utf8))])

    let requests = StubURLProtocol.requests
    XCTAssertEqual(requests.map(\.path), [
      "/v1/media/limits", "/v1/posts/post_1", "/v1/media/presign", "/up_1",
      "/v1/media/presign/up_1/complete", "/v1/posts/post_1",
    ])
    XCTAssertEqual(requests[1].method, "GET")
    XCTAssertEqual(try requests[2].bodyJSON()["workspaceId"] as? String, "ws_1")

    let update = requests[5]
    XCTAssertEqual(update.method, "PUT")
    let body = try update.bodyJSON()
    XCTAssertEqual(body["title"] as? String, "Retitled")
    let content = try XCTUnwrap(body["content"] as? [[String: Any]])
    XCTAssertEqual(content[0]["text"] as? String, "Keep me")
    let media = try XCTUnwrap(content[0]["media"] as? [[String: Any]])
    XCTAssertEqual(media.map { $0["url"] as? String }, [
      "https://cdn.fopost.test/old.png", "https://cdn.fopost.test/new.png",
    ])
  }

  func testFileTooLargeSurfacesAs413WithMaxFileBytes() async throws {
    StubURLProtocol.script([
      .json(
        #"{"error":"file_too_large","message":"\"clip.mp4\" is 2 GB, but your account allows files up to 400 MB.","max_file_bytes":419430400,"file_bytes":2147483648,"upgrade_url":"https://app.fopost.test/settings/billing"}"#,
        status: 413)
    ])
    let client = try makeStubClient()

    do {
      _ = try await client.media.presign(
        workspaceID: "ws_1", filename: "clip.mp4", mimeType: "video/mp4", size: 2_147_483_648)
      XCTFail("Expected a 413 to throw")
    } catch let error as FoPostError {
      XCTAssertEqual(error.status, 413)
      XCTAssertEqual(error.code, "file_too_large")
      XCTAssertEqual(error.maxFileBytes, 419_430_400)
      XCTAssertEqual(error.details?.field("file_bytes", as: Int64.self), 2_147_483_648)
      XCTAssertEqual(
        error.upgradeURL, URL(string: "https://app.fopost.test/settings/billing"))
    }
    XCTAssertEqual(StubURLProtocol.requests.count, 1)
    XCTAssertEqual(try StubURLProtocol.requests[0].bodyJSON()["size"] as? Int64, 2_147_483_648)
  }

  func testPresignCarriesTheOptionalPlacementFields() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":{"uploadId":"up_1","uploadUrl":"https://bucket.fopost.test/up_1","maxFileBytes":5368709120}}"#,
        status: 201)
    ])
    let client = try makeStubClient()

    let presigned = try await client.media.presign(
      workspaceID: "ws_1", filename: "me.png", mimeType: "image/png", size: 10,
      options: PresignOptions(
        folderID: "fld_1", origin: "chat", brandRole: "person", brandVoiceID: "bv_1",
        personConsent: PersonConsent(subject: "Our founder", statement: "Agreed on 1 Oct")))

    XCTAssertEqual(presigned.maxFileBytes, 5_368_709_120)
    let body = try StubURLProtocol.requests[0].bodyJSON()
    XCTAssertEqual(body["folderId"] as? String, "fld_1")
    XCTAssertEqual(body["origin"] as? String, "chat")
    XCTAssertEqual(body["brandRole"] as? String, "person")
    XCTAssertEqual(body["brandVoiceId"] as? String, "bv_1")
    let consent = try XCTUnwrap(body["personConsent"] as? [String: Any])
    XCTAssertEqual(consent["subject"] as? String, "Our founder")
    XCTAssertEqual(consent["statement"] as? String, "Agreed on 1 Oct")
  }
}
