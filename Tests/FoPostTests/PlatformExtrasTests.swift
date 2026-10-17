import Foundation
import XCTest

@testable import FoPost

final class PlatformExtrasTests: XCTestCase {
  func testCreatePinterestBoardOmitsTheOptionalsItWasNotGiven() async throws {
    StubURLProtocol.script([
      .json("{\"data\":{\"id\":\"b1\",\"name\":\"Recipes\",\"privacy\":\"PUBLIC\"}}", status: 201)
    ])
    let client = try makeStubClient()

    let board = try await client.accounts.createPinterestBoard(
      "acc_1", CreatePinterestBoardRequest(name: "Recipes"))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/pinterest/boards")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["name"] as? String, "Recipes")
    XCTAssertNil(body["description"])
    XCTAssertNil(body["privacy"])
    XCTAssertEqual(board.id, "b1")
  }

  func testSetDefaultYouTubePlaylistSendsNullToClearIt() async throws {
    StubURLProtocol.script([.json("{\"data\":{\"playlist_id\":null}}")])
    let client = try makeStubClient()

    let stored = try await client.accounts.setDefaultYouTubePlaylist("acc_1", playlistID: nil)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PUT")
    XCTAssertTrue(try request.bodyJSON()["playlist_id"] is NSNull)
    XCTAssertNil(stored)
  }

  func testPlaylistsMarkTheStoredDefault() async throws {
    StubURLProtocol.script([
      .json("{\"data\":[{\"id\":\"PL1\",\"title\":\"Tutorials\",\"is_default\":true}]}")
    ])
    let client = try makeStubClient()

    let playlists = try await client.accounts.youtubePlaylists("acc_1")

    XCTAssertEqual(playlists.first?.isDefault, true)
  }

  func testBlueskyLanguagesRoundTrip() async throws {
    StubURLProtocol.script([.json("{\"data\":{\"languages\":[\"en\",\"pt-BR\"]}}")])
    let client = try makeStubClient()

    let result = try await client.accounts.setBlueskyLanguages("acc_1", ["en", "pt-BR"])

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PUT")
    XCTAssertEqual(try request.bodyJSON()["languages"] as? [String], ["en", "pt-BR"])
    XCTAssertEqual(result.languages, ["en", "pt-BR"])
  }

  func testTikTokCreatorInfoReportsTheAccountsOwnSwitches() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"privacy_level_options\":[\"PUBLIC_TO_EVERYONE\"],"
          + "\"comment_disabled\":false,\"duet_disabled\":true,\"stitch_disabled\":false,"
          + "\"max_video_post_duration_sec\":600}}")
    ])
    let client = try makeStubClient()

    let info = try await client.accounts.tiktokCreatorInfo("acc_1")

    XCTAssertEqual(info.duetDisabled, true)
    XCTAssertEqual(info.stitchDisabled, false)
    XCTAssertEqual(info.maxVideoPostDurationSec, 600)
  }

  func testTikTokMusicSearchPassesTheQueryThrough() async throws {
    StubURLProtocol.script([
      .json("{\"data\":[{\"id\":\"m1\",\"title\":\"Sunrise\",\"author\":\"Kite\"}]}")
    ])
    let client = try makeStubClient()

    let tracks = try await client.accounts.tiktokMusic("acc_1", query: "sunrise", limit: 5)

    XCTAssertEqual(tracks.first?.id, "m1")
    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/accounts/acc_1/tiktok/music")
    XCTAssertEqual(StubURLProtocol.requests[0].query["q"], "sunrise")
    XCTAssertEqual(StubURLProtocol.requests[0].query["limit"], "5")
  }

  func testTikTokVideoLookupReturnsTheAddressARepurposeRunReads() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":{\"video_id\":\"7300000000000000000\","
          + "\"download_url\":\"https://www.tiktok.com/@a/video/7300000000000000000\"}}")
    ])
    let client = try makeStubClient()

    let video = try await client.accounts.tiktokVideoLookup(
      "acc_1", url: "https://www.tiktok.com/@a/video/7300000000000000000")

    XCTAssertEqual(StubURLProtocol.requests[0].method, "POST")
    XCTAssertEqual(video.videoID, "7300000000000000000")
    XCTAssertNotNil(video.downloadURL)
  }

  func testInstagramStoriesAskForInsightsOnlyWhenRequested() async throws {
    StubURLProtocol.script([
      .json("{\"data\":[{\"id\":\"s1\",\"media_type\":\"IMAGE\"}]}"),
      .json("{\"data\":[{\"id\":\"s1\",\"media_type\":\"IMAGE\",\"insights\":{\"views\":40}}]}"),
    ])
    let client = try makeStubClient()

    _ = try await client.accounts.instagramStories("acc_1")
    XCTAssertTrue(StubURLProtocol.requests[0].query.isEmpty)

    let stories = try await client.accounts.instagramStories("acc_1", insights: true)
    XCTAssertEqual(StubURLProtocol.requests[1].query["insights"], "true")
    XCTAssertEqual(stories.first?.insights?["views"], 40)
  }

  func testLinkedInMentionsCarryTheAnnotationToPaste() async throws {
    StubURLProtocol.script([
      .json(
        "{\"data\":[{\"urn\":\"urn:li:organization:2414183\",\"name\":\"Devtestco\","
          + "\"annotation\":\"@[Devtestco](urn:li:organization:2414183)\"}]}")
    ])
    let client = try makeStubClient()

    let mentions = try await client.accounts.linkedinMentions("acc_1", query: "devtestco")

    XCTAssertEqual(StubURLProtocol.requests[0].path, "/v1/accounts/acc_1/linkedin/mentions")
    XCTAssertEqual(StubURLProtocol.requests[0].query["q"], "devtestco")
    XCTAssertEqual(mentions.first?.annotation, "@[Devtestco](urn:li:organization:2414183)")
  }
}
