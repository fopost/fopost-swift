import Foundation
import XCTest

@testable import FoPost

/// A second ad network behind the same endpoints.
final class AdsNetworksTests: XCTestCase {
  func testAuthorizeReachesWhicheverNetworkTheRegistryNamed() async throws {
    StubURLProtocol.script([.json(#"{"data":{"url":"https://www.linkedin.com/oauth"}}"#)])
    let client = try makeStubClient()

    let authorization = try await client.ads.authorize(
      "linkedin", ConnectMetaAdsRequest(workspaceId: "ws_1", returnTo: "/ads"))

    XCTAssertEqual(authorization.url, "https://www.linkedin.com/oauth")
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/connections/linkedin/authorize")
    let body = try request.bodyJSON()
    XCTAssertEqual(body["workspaceId"] as? String, "ws_1")
    XCTAssertEqual(body["returnTo"] as? String, "/ads")
  }

  func testProvidersCarryWhatEachNetworkSupports() async throws {
    StubURLProtocol.script([
      .json(
        """
        {"data":[{"id":"linkedin","name":"LinkedIn Ads","configured":false,"connectMethods":[],
        "capabilities":{"conversions":true},"targetingFacets":["country","job_title"],
        "trackingMacros":[{"token":"{{LINKEDIN_CAMPAIGN_ID}}","description":"Campaign"}]}]}
        """)
    ])
    let client = try makeStubClient()

    let providers = try await client.ads.providers()

    XCTAssertEqual(providers.count, 1)
    XCTAssertEqual(providers[0].configured, false)
    XCTAssertEqual(providers[0].capabilities?["conversions"], true)
    XCTAssertEqual(providers[0].targetingFacets, ["country", "job_title"])
    XCTAssertEqual(providers[0].trackingMacros?.first?.token, "{{LINKEDIN_CAMPAIGN_ID}}")
  }

  func testCompanyRowsTravelWithTheRequest() async throws {
    StubURLProtocol.script([.json(#"{"data":{"added":2}}"#)])
    let client = try makeStubClient()

    let added = try await client.ads.addAudienceCompanies(
      "urn:li:adSegment:44",
      companies: [
        AdCompany(domain: "northwind.example"),
        AdCompany(name: "Contoso"),
      ],
      workspaceID: "ws_1", connectionID: "conn_1")

    XCTAssertEqual(added.added, 2)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(request.path, "/v1/ads/audiences/urn%3Ali%3AadSegment%3A44/companies")
    let body = try request.bodyJSON()
    let companies = try XCTUnwrap(body["companies"] as? [[String: Any]])
    XCTAssertEqual(companies.first?["domain"] as? String, "northwind.example")
  }

  func testConversionEventsSendTheIdentityTheAPIHashes() async throws {
    StubURLProtocol.script([.json(#"{"data":{"accepted":1}}"#)])
    let client = try makeStubClient()

    let accepted = try await client.ads.sendConversionEvents(
      "urn:li:conversion:9",
      events: [ConversionEvent(happenedAt: 1_758_326_400_000, email: "buyer@example.test")],
      workspaceID: "ws_1", connectionID: "conn_1")

    XCTAssertEqual(accepted.accepted, 1)
    let request = try XCTUnwrap(StubURLProtocol.requests.first)
    XCTAssertEqual(
      request.path, "/v1/ads/linkedin/conversion-rules/urn%3Ali%3Aconversion%3A9/events")
    XCTAssertEqual(request.query["connection_id"], "conn_1")
  }
}
