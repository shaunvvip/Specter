import XCTest
@testable import Specter

final class OptionRegistryTests: XCTestCase {
    private func entry(_ key: String, doc: String = "", category: SettingCategory = .appearance, curated: Bool = true) -> OptionEntry {
        OptionEntry(
            key: key, type: .string, defaultValue: .string(""),
            docMarkdown: doc.isEmpty ? "doc for \(key)" : doc,
            category: category, isCurated: curated
        )
    }

    func test_findByKey_returnsEntry() {
        let r = OptionRegistry(entries: [entry("theme"), entry("font-size")], curated: [])
        XCTAssertNotNil(r.find("theme"))
        XCTAssertNil(r.find("nonexistent"))
    }

    func test_search_matchesKey() {
        let r = OptionRegistry(entries: [entry("font-size"), entry("font-family"), entry("theme")], curated: [])
        let hits = r.search("font")
        XCTAssertEqual(Set(hits.map(\.key)), ["font-size", "font-family"])
    }

    func test_search_emptyQueryReturnsAll() {
        let r = OptionRegistry(entries: [entry("a"), entry("b")], curated: [])
        XCTAssertEqual(r.search("").count, 2)
    }

    func test_search_matchesDocText() {
        let r = OptionRegistry(entries: [entry("background-opacity", doc: "Controls see-through level")], curated: [])
        XCTAssertEqual(r.search("see-through").count, 1)
    }

    func test_curatedEntries_filteredCorrectly() {
        let r = OptionRegistry(entries: [
            entry("theme", curated: true),
            entry("xx-deep-option", curated: false)
        ], curated: ["theme"])
        XCTAssertEqual(r.curatedEntries.count, 1)
        XCTAssertEqual(r.curatedEntries.first?.key, "theme")
    }
}
