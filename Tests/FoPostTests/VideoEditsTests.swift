import Foundation
import XCTest

@testable import FoPost

/// Video edits: paths, bodies, the bare job object, and the snake_case fields.
final class VideoEditsTests: XCTestCase {
  private static let job = """
    {"id":"job_1","status":"succeeded","progress":1,"source_media_id":"med_1",
     "operations":[{"op":"trim","params":{"start":1.5,"end":10}}],
     "result_media_id":"med_2","result_media":{"id":"med_2",
     "preview_url":"https://api.fopost.test/v1/media/med_2/file","mime_type":"video/mp4"},
     "extra_outputs":[{"media_id":"med_3","label":"Clip 1","mime":"video/mp4","preview_url":null}],
     "result":null,"error":null,"created_at":"2026-11-01T00:00:00.000Z",
     "updated_at":"2026-11-01T00:01:00.000Z","completed_at":"2026-11-01T00:01:00.000Z"}
    """

  func testOpsDecodesAvailabilityAndAIUse() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":[{"name":"trim","available":true,"uses_ai":false},{"name":"subtitles","available":false,"uses_ai":true}]}"#
      )
    ])
    let client = try makeStubClient()

    let ops = try await client.videoEdits.ops()

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/video-edits/ops")
    XCTAssertEqual(ops.map(\.name), [.trim, .subtitles])
    XCTAssertEqual(ops.last?.available, false)
    XCTAssertEqual(ops.last?.usesAI, true)
  }

  func testListSendsTheFilters() async throws {
    StubURLProtocol.script([.json("{\"data\":[\(Self.job)]}")])
    let client = try makeStubClient()

    let jobs = try await client.videoEdits.list(workspaceID: "ws_1", mediaID: "med_1", limit: 5)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/video-edits")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["media_id"], "med_1")
    XCTAssertEqual(request.query["limit"], "5")
    XCTAssertEqual(jobs.first?.id, "job_1")
  }

  func testCreateSendsTheOperationsAndDecodesTheBareJob() async throws {
    StubURLProtocol.script([.json(Self.job, status: 201)])
    let client = try makeStubClient()

    let job = try await client.videoEdits.create(
      CreateVideoEditRequest(
        mediaID: "med_1",
        operations: [
          VideoEditOperation(op: .trim, params: ["start": 1.5, "end": 10]),
          VideoEditOperation(op: .removeSilence),
        ],
        workspaceID: "ws_1"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/video-edits")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["media_id"] as? String, "med_1")
    XCTAssertEqual(body["workspace_id"] as? String, "ws_1")
    let operations = try XCTUnwrap(body["operations"] as? [[String: Any]])
    XCTAssertEqual(operations.first?["op"] as? String, "trim")
    XCTAssertEqual((operations.first?["params"] as? [String: Any])?["end"] as? Int, 10)
    XCTAssertEqual(operations.last?["op"] as? String, "remove_silence")
    XCTAssertNil(operations.last?["params"])

    XCTAssertEqual(job.status, .succeeded)
    XCTAssertEqual(job.sourceMediaID, "med_1")
    XCTAssertEqual(job.resultMedia?.mimeType, "video/mp4")
    XCTAssertEqual(job.extraOutputs?.first?.label, "Clip 1")
    XCTAssertEqual(job.operations?.first?.params?["start"]?.doubleValue, 1.5)
    XCTAssertNotNil(job.completedAt)
  }

  func testGetReadsOneJob() async throws {
    StubURLProtocol.script([.json(Self.job)])
    let client = try makeStubClient()

    let job = try await client.videoEdits.get("job_1", workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/video-edits/job_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(job.resultMediaID, "med_2")
  }
}
