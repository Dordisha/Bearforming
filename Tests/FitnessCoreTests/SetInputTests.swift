import XCTest
@testable import FitnessCore

final class SetInputTests: XCTestCase {
    func testBlankAndMalformedEditsPreserveLastValidValue() {
        var set = LoggedSet(); set.weight = 60
        for text in ["", " ", "abc", "-1", "NaN", "inf", "1e2", "2..5", ".", "1,000"] {
            let parsed = SetInput.parse(text, maximum: 9999, integerOnly: false)
            XCTAssertNil(parsed, text)
            if let parsed { set.weight = parsed }
            XCTAssertEqual(set.weight, 60, text)
        }
    }
    func testExplicitZeroAndWeightBounds() {
        XCTAssertEqual(SetInput.parse("0", maximum: 9999, integerOnly: false), 0)
        XCTAssertEqual(SetInput.parse("9999", maximum: 9999, integerOnly: false), 9999)
        XCTAssertNil(SetInput.parse("9999.1", maximum: 9999, integerOnly: false))
        XCTAssertEqual(SetInput.parse("60.", maximum: 9999, integerOnly: false), 60)
        XCTAssertEqual(SetInput.parse("60.5", maximum: 9999, integerOnly: false), 60.5)
    }
    func testRepsRequireWholeNumberWithinBounds() {
        XCTAssertEqual(SetInput.parse("8", maximum: 999, integerOnly: true), 8)
        XCTAssertEqual(SetInput.parse("0", maximum: 999, integerOnly: true), 0)
        XCTAssertEqual(SetInput.parse("999", maximum: 999, integerOnly: true), 999)
        XCTAssertNil(SetInput.parse("8.5", maximum: 999, integerOnly: true))
        XCTAssertNil(SetInput.parse("1000", maximum: 999, integerOnly: true))
    }
    func testLocalizedDecimalsAndSavedValuesSurviveRoundTrip() throws {
        var state = FitnessState()
        var set = LoggedSet()
        set.weight = try XCTUnwrap(SetInput.parse("60,5", maximum: 9999, integerOnly: false, decimalSeparator: ","))
        XCTAssertEqual(set.weight, 60.5)
        XCTAssertNil(SetInput.parse("60,5.2", maximum: 9999, integerOnly: false, decimalSeparator: ","))
        state.active = Workout(exercises: [Exercise(name: "Seated row", sets: [set])])
        let restored = try JSONDecoder().decode(FitnessState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored, state)
    }
}
