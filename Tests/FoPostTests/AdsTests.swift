import Foundation
import XCTest

@testable import FoPost

final class AdsTests: XCTestCase {
  func testBoostSendsCamelCaseBodyAndDecodesTheAd() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":{"id":"ad_1","workspaceId":"ws_1","kind":"boost","name":"Autumn drop boost",
        "goal":"engagement","status":"paused","effectiveStatus":"PAUSED","connectionId":"conn_1",
        "accountId":"acc_1","platform":"facebook","adAccountId":"act_123","sourcePostId":"post_1",
        "budgetMinor":2000,"budgetType":"daily","currency":"USD",
        "targeting":{"countries":["US","CA"],"ageMin":21,"ageMax":45,"gender":"all"},
        "insights":{"impressions":0,"reach":0,"clicks":0,"spendMinor":0},
        "createdAt":"2026-09-19T10:00:00.000Z"}}
        """, status: 201)
    ])
    let client = try makeStubClient()

    let ad = try await client.ads.boost(
      BoostPostRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "act_123", postId: "post_1",
        accountId: "acc_1", name: "Autumn drop boost", goal: .engagement,
        budget: AdBudget(minor: 2000, type: .daily),
        targeting: AdTargeting(countries: ["US", "CA"], ageMin: 21, ageMax: 45)))

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/ads/boost")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["connectionId"] as? String, "conn_1")
    XCTAssertEqual(body["adAccountId"] as? String, "act_123")
    XCTAssertEqual(body["postId"] as? String, "post_1")
    XCTAssertEqual(body["accountId"] as? String, "acc_1")
    XCTAssertEqual(body["goal"] as? String, "engagement")
    XCTAssertNil(body["paused"])
    let budget = try XCTUnwrap(body["budget"] as? [String: Any])
    XCTAssertEqual(budget["minor"] as? Int, 2000)
    XCTAssertEqual(budget["type"] as? String, "daily")
    let targeting = try XCTUnwrap(body["targeting"] as? [String: Any])
    XCTAssertEqual(targeting["countries"] as? [String], ["US", "CA"])
    XCTAssertEqual(targeting["ageMin"] as? Int, 21)
    XCTAssertEqual(targeting["gender"] as? String, "all")

    XCTAssertEqual(ad.id, "ad_1")
    XCTAssertEqual(ad.kind, .boost)
    XCTAssertEqual(ad.status, .paused)
    XCTAssertEqual(ad.budgetType, .daily)
    XCTAssertEqual(ad.targeting?.countries, ["US", "CA"])
    XCTAssertEqual(ad.insights?.spendMinor, 0)
    XCTAssertEqual(ad.createdAt, Timestamps.parse("2026-09-19T10:00:00.000Z"))
  }

  func testWorkspaceScopedCallsCarryTheQueryParameter() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([.json(#"{"data":{"id":"ad_1","status":"active"}}"#)])
    let resumed = try await client.ads.setStatus("ad_1", workspaceID: "ws_1", status: .active)
    XCTAssertEqual(resumed.status, .active)
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/ads/ad_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(try request.bodyJSON()["status"] as? String, "active")

    StubURLProtocol.script([.json(#"{"data":{"id":"ad_1","effectiveStatus":"ACTIVE"}}"#)])
    _ = try await client.ads.refresh("ad_1", workspaceID: "ws_1")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "POST")
    XCTAssertEqual(request.path, "/v1/ads/ad_1/refresh")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")

    StubURLProtocol.script([.json(#"{"message":"Ad deleted"}"#)])
    let deleted = try await client.ads.delete("ad_1", workspaceID: "ws_1")
    XCTAssertEqual(deleted.message, "Ad deleted")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/ads/ad_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")

    StubURLProtocol.script([.json(#"{"message":"Connection removed"}"#)])
    _ = try await client.ads.deleteConnection("conn_1", workspaceID: "ws_1")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/ads/connections/conn_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")

    StubURLProtocol.script([.json(#"{"data":[]}"#)])
    _ = try await client.ads.external(workspaceID: "ws_1")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/external")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
  }

  func testAuthorizeMetaReturnsTheLoginURL() async throws {
    StubURLProtocol.script([.json(#"{"data":{"url":"https://example.invalid/login"}}"#)])
    let client = try makeStubClient()

    let authorization = try await client.ads.authorizeMeta(
      ConnectMetaAdsRequest(workspaceId: "ws_1", method: .business))

    XCTAssertEqual(authorization.url, "https://example.invalid/login")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/connections/meta/authorize")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["method"] as? String, "business")
  }

  func testAudiencesTargetingAndLeadsBuildTheirQueries() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(
        #"{"data":{"audiences":[{"id":"aud_1","name":"Buyers","subtype":"CUSTOM","sizeLower":1000}],"pixels":[{"id":"px_1","name":"Site"}],"workspaceId":"ws_1"}}"#
      )
    ])
    let audiences = try await client.ads.audiences(
      AudiencesParams(connectionID: "conn_1", adAccountID: "act_123", workspaceID: "ws_1"))
    XCTAssertEqual(audiences.audiences?.first?.name, "Buyers")
    XCTAssertEqual(audiences.pixels?.first?.id, "px_1")
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/audiences")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
    XCTAssertEqual(request.query["ad_account_id"], "act_123")

    StubURLProtocol.script([.json(#"{"data":{"id":"aud_2","added":2}}"#, status: 201)])
    let created = try await client.ads.createAudience(
      CreateAudienceRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "act_123", name: "Lookalike",
        spec: .lookalike(originAudienceId: "aud_1", country: "US", ratio: 0.05)))
    XCTAssertEqual(created.added, 2)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    let spec = try XCTUnwrap(try request.bodyJSON()["spec"] as? [String: Any])
    XCTAssertEqual(spec["subtype"] as? String, "LOOKALIKE")
    XCTAssertEqual(spec["originAudienceId"] as? String, "aud_1")
    XCTAssertEqual(spec["country"] as? String, "US")

    StubURLProtocol.script([
      .json(#"{"data":[{"id":"6003","name":"Coffee","detail":"Interest"}]}"#)
    ])
    let options = try await client.ads.searchTargeting(
      TargetingSearchParams(connectionID: "conn_1", type: .interest, q: "coffee"))
    XCTAssertEqual(options.first?.name, "Coffee")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/targeting/search")
    XCTAssertEqual(request.query["type"], "interest")
    XCTAssertEqual(request.query["q"], "coffee")

    StubURLProtocol.script([.json(#"{"data":{"id":"form_1"}}"#, status: 201)])
    let form = try await client.ads.createLeadForm(
      CreateLeadFormRequest(
        workspaceId: "ws_1", connectionId: "conn_1", pageId: "page_1", name: "Newsletter",
        questions: [.email, .fullName], privacyPolicyUrl: "https://yourbrand.com/privacy",
        thankYouMessage: "Thanks!"))
    XCTAssertEqual(form.id, "form_1")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/lead-forms")
    XCTAssertEqual(try request.bodyJSON()["questions"] as? [String], ["EMAIL", "FULL_NAME"])

    StubURLProtocol.script([
      .json(
        #"{"data":{"leads":[{"id":"lead_1","fields":[{"name":"full_name","values":["Jordan Vale"]}],"isOrganic":false}],"nextCursor":"abc"}}"#
      )
    ])
    let leads = try await client.ads.leads(
      formID: "form_1", LeadsParams(connectionID: "conn_1", pageID: "page_1", after: "xyz"))
    XCTAssertEqual(leads.leads?.first?.fields?.first?.name, "full_name")
    XCTAssertEqual(leads.nextCursor, "abc")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/lead-forms/form_1/leads")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
    XCTAssertEqual(request.query["page_id"], "page_1")
    XCTAssertEqual(request.query["after"], "xyz")
  }

  func testAccountTreeNestsAdSetsAndAdsUnderCampaigns() async throws {
    StubURLProtocol.script([
      .json(
        #"{"data":{"adAccountId":"act_123","currency":"USD","workspaceId":"ws_1","campaigns":[{"id":"c_1","name":"Launch","status":"ACTIVE","budgetMinor":null,"adSets":[{"id":"s_1","name":"US","campaignId":"c_1","status":"PAUSED","budgetMinor":2000,"budgetType":"daily","ads":[{"id":"a_1","name":"Morning","adSetId":"s_1","creativeId":"cr_1","status":"PAUSED"}]}]}]}}"#
      )
    ])
    let client = try makeStubClient()

    let tree = try await client.ads.accountTree(
      "act_123", connectionID: "conn_1", workspaceID: "ws_1")

    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "GET")
    XCTAssertEqual(request.path, "/v1/ads/accounts/act_123/tree")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    let campaign = try XCTUnwrap(tree.campaigns?.first)
    XCTAssertNil(campaign.budgetMinor)
    let adSet = try XCTUnwrap(campaign.adSets?.first)
    XCTAssertEqual(adSet.budgetType, .daily)
    XCTAssertEqual(adSet.ads?.first?.creativeId, "cr_1")
  }

  func testCampaignWritesCarryWorkspaceAndConnection() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([.json(#"{"data":{"id":"c_1","status":"ACTIVE"}}"#)])
    _ = try await client.ads.updateCampaign(
      "c_1", UpdateAdCampaignRequest(status: .active), workspaceID: "ws_1",
      connectionID: "conn_1")
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "PATCH")
    XCTAssertEqual(request.path, "/v1/ads/campaigns/c_1")
    XCTAssertEqual(request.query["workspace_id"], "ws_1")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
    XCTAssertEqual(try request.bodyJSON() as NSDictionary, ["status": "active"])

    StubURLProtocol.script([.json(#"{"data":{"id":"c_2"}}"#, status: 201)])
    let copy = try await client.ads.duplicateCampaign(
      "c_1", workspaceID: "ws_1", connectionID: "conn_1", paused: false)
    XCTAssertEqual(copy.id, "c_2")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/campaigns/c_1/duplicate")
    XCTAssertEqual(try request.bodyJSON()["paused"] as? Bool, false)

    StubURLProtocol.script([
      .json(
        #"{"data":[{"id":"c_1","level":"campaign","ok":true,"error":null},{"id":"a_1","level":"ad","ok":false,"error":"Not found"}]}"#
      )
    ])
    let results = try await client.ads.bulkSetStatus(
      BulkAdStatusRequest(
        workspaceId: "ws_1", connectionId: "conn_1", status: .paused,
        objects: [AdObjectRef(id: "c_1", level: .campaign), AdObjectRef(id: "a_1", level: .ad)]))
    XCTAssertEqual(results.last?.ok, false)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/status")
    let objects = try XCTUnwrap(try request.bodyJSON()["objects"] as? [[String: Any]])
    XCTAssertEqual(objects.last?["level"] as? String, "ad")
  }

  func testInsightsSendTheRangeBreakdownAndDailyFlag() async throws {
    let report =
      #"{"data":{"objectId":"c_1","currency":"USD","since":"2026-09-01","until":"2026-09-07","breakdownBy":"age","totals":{"impressions":1000,"reach":800,"clicks":25,"spendMinor":1200,"ctr":2.5,"leads":3},"breakdown":[{"key":"25-34","metrics":{"impressions":600}}],"timeline":[{"date":"2026-09-01","metrics":{"spendMinor":150}}]}}"#
    let client = try makeStubClient()

    StubURLProtocol.script([.json(report)])
    let insights = try await client.ads.insights(
      InsightsParams(
        connectionID: "conn_1", objectID: "c_1", since: "2026-09-01", until: "2026-09-07",
        breakdown: .age, daily: true))
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/insights")
    XCTAssertEqual(
      request.query,
      [
        "connection_id": "conn_1", "object_id": "c_1", "since": "2026-09-01",
        "until": "2026-09-07", "breakdown": "age", "daily": "true",
      ])
    XCTAssertEqual(insights.totals?.ctr, 2.5)
    XCTAssertEqual(insights.breakdownBy, .age)
    XCTAssertEqual(insights.timeline?.first?.metrics?.spendMinor, 150)

    StubURLProtocol.script([.json(report)])
    _ = try await client.ads.adInsights(
      "ad_1", AdInsightsParams(workspaceID: "ws_1", since: "2026-09-01", until: "2026-09-07"))
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/ad_1/insights")
    XCTAssertEqual(
      request.query, ["workspace_id": "ws_1", "since": "2026-09-01", "until": "2026-09-07"])
  }

  func testLeadsFeedPassesTheCursorBack() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(
        #"{"data":{"leads":[{"id":"l_1","leadId":"m_1","pageId":"1234","formId":"form_1","isOrganic":false,"fields":[{"name":"email","values":["sam@yourbrand.com"]}],"submittedAt":"2026-09-10T12:00:00.000Z"}],"nextCursor":"cur_2"}}"#
      )
    ])
    let first = try await client.ads.leadsFeed(
      LeadsFeedParams(workspaceID: "ws_1", formID: "form_1", limit: 50))
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/leads")
    XCTAssertEqual(request.query, ["workspace_id": "ws_1", "form_id": "form_1", "limit": "50"])
    XCTAssertEqual(first.leads?.first?.leadId, "m_1")
    XCTAssertEqual(first.leads?.first?.submittedAt, Timestamps.parse("2026-09-10T12:00:00.000Z"))

    StubURLProtocol.script([.json(#"{"data":{"leads":[],"nextCursor":null}}"#)])
    let second = try await client.ads.leadsFeed(
      LeadsFeedParams(workspaceID: "ws_1", formID: "form_1", cursor: first.nextCursor, limit: 50))
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.query["cursor"], "cur_2")
    XCTAssertEqual(second.leads, [])
    XCTAssertNil(second.nextCursor)
  }

  func testCreativeUrlTagsAndLeadPages() async throws {
    let client = try makeStubClient()

    StubURLProtocol.script([
      .json(
        #"{"data":{"id":"cr_1","name":"Carousel","format":"carousel","callToAction":"SHOP_NOW","urlTags":"utm_source=meta"}}"#,
        status: 201)
    ])
    let creative = try await client.ads.createCreative(
      CreateAdCreativeRequest(
        workspaceId: "ws_1", connectionId: "conn_1", adAccountId: "act_123", pageId: "1234",
        name: "Carousel", format: .carousel, text: "Hi", callToAction: .shopNow,
        urlTags: "utm_source=meta",
        cards: [
          AdCreativeCard(mediaUrl: "https://cdn.yourbrand.com/1.png"),
          AdCreativeCard(mediaUrl: "https://cdn.yourbrand.com/2.png"),
        ]))
    XCTAssertEqual(creative.format, .carousel)
    var request = try XCTUnwrap(StubURLProtocol.requests.first)
    var body = try request.bodyJSON()
    XCTAssertEqual(body["urlTags"] as? String, "utm_source=meta")
    XCTAssertEqual(body["callToAction"] as? String, "SHOP_NOW")
    XCTAssertEqual((body["cards"] as? [Any])?.count, 2)

    StubURLProtocol.script([.json(#"{"data":{"pageId":"1234","backfilled":7}}"#, status: 201)])
    let page = try await client.ads.subscribeLeadPage(
      SubscribeLeadPageRequest(workspaceId: "ws_1", connectionId: "conn_1", pageId: "1234"))
    XCTAssertEqual(page.backfilled, 7)

    StubURLProtocol.script([.json(#"{"message":"Unsubscribed"}"#)])
    _ = try await client.ads.unsubscribeLeadPage("1234", workspaceID: "ws_1", connectionID: "conn_1")
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.method, "DELETE")
    XCTAssertEqual(request.path, "/v1/ads/lead-pages/1234")
    XCTAssertEqual(request.query["connection_id"], "conn_1")

    StubURLProtocol.script([.json(#"{"data":{"added":2}}"#)])
    let added = try await client.ads.addAudienceUsers(
      "aud_1", emails: ["a@yourbrand.com", "b@yourbrand.com"], workspaceID: "ws_1",
      connectionID: "conn_1")
    XCTAssertEqual(added.added, 2)
    request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/audiences/aud_1/users")
    body = try request.bodyJSON()
    XCTAssertEqual((body["emails"] as? [String])?.count, 2)
  }
}
