import XCTest
@testable import Specter

final class ConfigValueTests: XCTestCase {
    func test_stringRoundTrip() {
        let v = ConfigValue.string("hello")
        XCTAssertEqual(v.stringRepresentation, "hello")
        XCTAssertEqual(ConfigValue.parse("hello", as: .string), .string("hello"))
    }

    func test_integerRoundTrip() {
        XCTAssertEqual(ConfigValue.integer(14).stringRepresentation, "14")
        XCTAssertEqual(ConfigValue.parse("14", as: .integer(range: 8...72)), .integer(14))
        XCTAssertNil(ConfigValue.parse("not-a-number", as: .integer(range: 8...72)))
        XCTAssertNil(ConfigValue.parse("100", as: .integer(range: 8...72)), "out-of-range integer should fail")
    }

    func test_doubleRoundTrip() {
        XCTAssertEqual(ConfigValue.double(0.78).stringRepresentation, "0.78")
        XCTAssertEqual(ConfigValue.parse("0.78", as: .double(range: 0...1)), .double(0.78))
        XCTAssertNil(ConfigValue.parse("2.0", as: .double(range: 0...1)))
    }

    func test_boolRoundTrip() {
        XCTAssertEqual(ConfigValue.bool(true).stringRepresentation, "true")
        XCTAssertEqual(ConfigValue.parse("true", as: .bool), .bool(true))
        XCTAssertEqual(ConfigValue.parse("false", as: .bool), .bool(false))
        XCTAssertNil(ConfigValue.parse("maybe", as: .bool))
    }

    func test_enumerationParse() {
        let type = OptionType.enumeration(["block", "bar", "underline"])
        XCTAssertEqual(ConfigValue.parse("block", as: type), .string("block"))
        XCTAssertNil(ConfigValue.parse("triangle", as: type))
    }
}
