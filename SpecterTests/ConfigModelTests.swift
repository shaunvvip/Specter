import XCTest
@testable import Specter

final class ConfigModelTests: XCTestCase {
    func test_initWithApplied_noDirtyKeys() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        XCTAssertTrue(m.dirtyKeys.isEmpty)
        XCTAssertEqual(m.values["theme"], .string("Mocha"))
    }

    func test_setKey_marksDirty() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        XCTAssertEqual(m.dirtyKeys, ["theme"])
        XCTAssertEqual(m.values["theme"], .string("TokyoNight"))
    }

    func test_setBackToOriginal_clearsDirty() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        m.set("theme", .string("Mocha"))
        XCTAssertTrue(m.dirtyKeys.isEmpty)
    }

    func test_setNewKey_marksDirty() {
        let m = ConfigModel(initialValues: [:])
        m.set("font-size", .integer(15))
        XCTAssertEqual(m.dirtyKeys, ["font-size"])
    }

    func test_reset_restoresOriginal() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        m.reset("theme")
        XCTAssertEqual(m.values["theme"], .string("Mocha"))
        XCTAssertTrue(m.dirtyKeys.isEmpty)
    }

    func test_resetAddedKey_removesIt() {
        let m = ConfigModel(initialValues: [:])
        m.set("font-size", .integer(15))
        m.reset("font-size")
        XCTAssertNil(m.values["font-size"])
        XCTAssertTrue(m.dirtyKeys.isEmpty)
    }

    func test_commit_movesAppliedForward() {
        let m = ConfigModel(initialValues: ["theme": .string("Mocha")])
        m.set("theme", .string("TokyoNight"))
        m.commit()
        XCTAssertTrue(m.dirtyKeys.isEmpty)
        XCTAssertEqual(m.values["theme"], .string("TokyoNight"))
        m.reset("theme")
        XCTAssertEqual(m.values["theme"], .string("TokyoNight"))
    }
}
