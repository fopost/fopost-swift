import Foundation
import XCTest

@testable import FoPost

final class CodingTests: XCTestCase {
  func testParsesEveryTimestampFormTheAPIUses() {
    XCTAssertNotNil(Timestamps.parse("2026-08-30T10:00:00Z"))
    XCTAssertNotNil(Timestamps.parse("2026-08-30T10:00:00.123Z"))
    XCTAssertNotNil(Timestamps.parse("2026-08-30T10:00:00+02:00"))
    XCTAssertNotNil(Timestamps.parse("2026-08-30 10:00:00"))
    XCTAssertNotNil(Timestamps.parse("2026-08-30"))
    XCTAssertNil(Timestamps.parse(""))
    XCTAssertNil(Timestamps.parse("never"))
  }

  func testFormatsRFC3339InUTC() {
    let date = Date(timeIntervalSince1970: 1_788_000_000)
    XCTAssertEqual(Timestamps.format(date), "2026-08-29T10:40:00Z")
  }

  func testJSONValueRoundTrips() throws {
    let value: JSONValue = [
      "twitter": ["thread": true, "replyTo": "123"],
      "counts": [1, 2, 3],
      "ratio": 0.5,
      "empty": nil,
    ]
    let data = try Coding.encoder.encode(value)
    let decoded = try Coding.decoder.decode(JSONValue.self, from: data)
    XCTAssertEqual(decoded, value)
    XCTAssertEqual(decoded["twitter"]?["thread"]?.boolValue, true)
    XCTAssertEqual(decoded["counts"]?[2]?.intValue, 3)
    XCTAssertEqual(decoded["ratio"]?.doubleValue, 0.5)
  }

  func testStringEnumsSurviveUnknownValues() throws {
    let data = Data(#"["twitter","some-network-from-2027"]"#.utf8)
    let platforms = try Coding.decoder.decode([Platform].self, from: data)
    XCTAssertEqual(platforms, [.twitter, Platform(rawValue: "some-network-from-2027")])
    XCTAssertEqual(
      String(data: try Coding.encoder.encode(platforms), encoding: .utf8),
      #"["twitter","some-network-from-2027"]"#)
  }

  func testEnvelopeProbeOnlyFiresOnAnObjectWithData() throws {
    XCTAssertTrue(
      try Coding.decoder.decode(EnvelopeProbe.self, from: Data(#"{"data":1}"#.utf8)).isEnveloped)
    XCTAssertFalse(
      try Coding.decoder.decode(EnvelopeProbe.self, from: Data(#"{"id":"1"}"#.utf8)).isEnveloped)
    XCTAssertFalse(try Coding.decoder.decode(EnvelopeProbe.self, from: Data("[]".utf8)).isEnveloped)
  }
}
