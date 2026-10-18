import Foundation
import XCTest

@testable import FoPost

final class RedditTests: XCTestCase {
  func testSubredditsDecodePostingRightsAndTheDefault() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[
        {"name":"webdev","title":"Web Development","subscribers":2000000,"over18":false,
        "canPost":true,"flairEnabled":true,"iconUrl":null,"isDefault":true},
        {"name":"announcements","title":"Announcements","subscribers":1,"over18":false,
        "canPost":false,"flairEnabled":false,"iconUrl":null,"isDefault":false}]}
        """)
    ])
    let client = try makeStubClient()

    let subreddits = try await client.accounts.redditSubreddits("acc_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/reddit/subreddits")
    XCTAssertEqual(subreddits.count, 2)
    XCTAssertEqual(subreddits[0].name, "webdev")
    XCTAssertEqual(subreddits[0].canPost, true)
    XCTAssertEqual(subreddits[0].isDefault, true)
    XCTAssertEqual(subreddits[1].canPost, false)
  }

  func testRulesAndFlairsUnwrapTheSubredditEnvelope() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"subreddit":"webdev","rules":[
        {"name":"No self promotion","description":"Keep it useful","appliesTo":"link"}]}}
        """),
      .json(
        """
        {"data":{"subreddit":"webdev","flairs":[
        {"id":"flair_1","text":"Showoff Saturday","editable":false}]}}
        """),
    ])
    let client = try makeStubClient()

    let rules = try await client.accounts.redditSubredditRules("acc_1", subreddit: "webdev")
    let flairs = try await client.accounts.redditFlairs("acc_1", subreddit: "webdev")

    XCTAssertEqual(
      StubURLProtocol.requests[0].path, "/v1/accounts/acc_1/reddit/subreddits/webdev/rules")
    XCTAssertEqual(StubURLProtocol.requests[1].path, "/v1/accounts/acc_1/reddit/flairs")
    XCTAssertEqual(StubURLProtocol.requests[1].query["subreddit"], "webdev")
    XCTAssertEqual(rules.count, 1)
    XCTAssertEqual(rules[0].appliesTo, "link")
    XCTAssertEqual(flairs.count, 1)
    XCTAssertEqual(flairs[0].id, "flair_1")
    XCTAssertEqual(flairs[0].editable, false)
  }

  func testANilDefaultSubredditIsSentExplicitly() async throws {
    StubURLProtocol.script([.json(#"{"data":{"subreddit":"u_someone"}}"#)])
    let client = try makeStubClient()

    let now = try await client.accounts.setRedditDefaultSubreddit("acc_1", subreddit: nil)

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PUT")
    XCTAssertEqual(request.path, "/v1/accounts/acc_1/reddit/default-subreddit")
    let body = try request.bodyJSON()
    XCTAssertTrue(body.keys.contains("subreddit"))
    XCTAssertTrue(body["subreddit"] is NSNull)
    XCTAssertEqual(now, "u_someone")
  }

  func testAVoteSendsItsDirectionAndReadsTheVoteBack() async throws {
    StubURLProtocol.script([
      .json(#"{"data":{"id":"item_1","vote":"down","canVote":true,"liked":false}}"#)
    ])
    let client = try makeStubClient()

    let item = try await client.inbox.vote("item_1", direction: "down")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/inbox/item_1/vote")
    XCTAssertEqual(try request.bodyJSON()["direction"] as? String, "down")
    XCTAssertEqual(item.vote, "down")
    XCTAssertEqual(item.canVote, true)
    XCTAssertEqual(item.liked, false)
  }

  func testTheSubredditCheckPassesTheAccountAndName() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"subreddit":"webdev","exists":true,"can_post":false,"over_18":false,
        "flair_enabled":true,"ok":false}}
        """)
    ])
    let client = try makeStubClient()

    let result = try await client.validate.subreddit(accountId: "acc_1", name: "webdev")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/validate/subreddit")
    XCTAssertEqual(request.query["account_id"], "acc_1")
    XCTAssertEqual(request.query["name"], "webdev")
    XCTAssertEqual(result.exists, true)
    XCTAssertEqual(result.canPost, false)
    XCTAssertEqual(result.ok, false)
  }
}
