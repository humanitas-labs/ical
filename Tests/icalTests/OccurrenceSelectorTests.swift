import XCTest
@testable import ical

final class OccurrenceSelectorTests: XCTestCase {
    func testTokenRoundTripsThroughDateInputParser() throws {
        let date = Date(timeIntervalSince1970: 1_793_714_400) // fixed instant
        let token = OccurrenceSelector.token(for: date, timeZone: TimeZone(identifier: "America/Los_Angeles")!)
        XCTAssertTrue(token.hasSuffix("-08:00") || token.hasSuffix("-07:00"), token)
        let parsed = try XCTUnwrap(DateInputParser().parse(token))
        XCTAssertEqual(parsed.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 0.5)
    }

    func testMatchSelectsListedInstanceOfRecurringSeries() {
        let base = Date(timeIntervalSince1970: 1_793_714_400)
        let day: TimeInterval = 86_400
        // A daily series shares one identifier; a different event sits at the same time.
        let candidates: [(id: String?, occurrenceDate: Date?)] = [
            (id: "series", occurrenceDate: base - day),
            (id: "other", occurrenceDate: base),
            (id: "series", occurrenceDate: base),
            (id: "series", occurrenceDate: base + day),
        ]
        XCTAssertEqual(OccurrenceSelector.matchIndex(id: "series", occurrence: base, candidates: candidates), 2)
        XCTAssertEqual(OccurrenceSelector.matchIndex(id: "series", occurrence: base + day, candidates: candidates), 3)
    }

    func testMatchReturnsNilWhenNoInstanceStartsAtOccurrence() {
        let base = Date(timeIntervalSince1970: 1_793_714_400)
        let candidates: [(id: String?, occurrenceDate: Date?)] = [(id: "series", occurrenceDate: base)]
        XCTAssertNil(OccurrenceSelector.matchIndex(id: "series", occurrence: base + 3600, candidates: candidates))
        XCTAssertNil(OccurrenceSelector.matchIndex(id: "missing", occurrence: base, candidates: candidates))
    }
}
