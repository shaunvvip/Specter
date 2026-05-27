import XCTest
@testable import Specter

final class ConfigModelAccessorsTests: XCTestCase {
    func test_string_returnsValueWhenSet() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        XCTAssertEqual(m.string(for: "theme"), "Mocha")
    }

    func test_string_returnsDefaultWhenUnset() {
        let m = ConfigModel(initialValues: [:])
        XCTAssertEqual(m.string(for: "theme", default: "fallback"), "fallback")
    }

    func test_string_returnsDefaultWhenWrongType() {
        let m = ConfigModel(initialValues: ["theme": .integer(5)])
        XCTAssertEqual(m.string(for: "theme", default: "fallback"), "fallback")
    }

    func test_integer_returnsValueWhenSet() {
        let m = ConfigModel(initialValues: ["font-size": .integer(18)])
        XCTAssertEqual(m.integer(for: "font-size"), 18)
    }

    func test_integer_returnsDefault() {
        let m = ConfigModel(initialValues: [:])
        XCTAssertEqual(m.integer(for: "font-size", default: 14), 14)
    }

    func test_double_returnsValueWhenSet() {
        let m = ConfigModel(initialValues: ["background-opacity": .double(0.78)])
        XCTAssertEqual(m.double(for: "background-opacity"), 0.78, accuracy: 0.0001)
    }

    func test_bool_returnsValueWhenSet() {
        let m = ConfigModel(initialValues: ["cursor-style-blink": .bool(false)])
        XCTAssertFalse(m.bool(for: "cursor-style-blink", default: true))
    }

    func test_appliedValue_returnsLastCommitted() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        XCTAssertEqual(m.appliedValue(for: "theme"), .string("Mocha"))
        m.commit()
        XCTAssertEqual(m.appliedValue(for: "theme"), .string("TokyoNight"))
    }
}
