import XCTest
@testable import Specter

final class ConfigTokenizerTests: XCTestCase {
    func test_emptyInput() {
        XCTAssertEqual(ConfigTokenizer.tokenize(""), [])
    }

    func test_singleEntry() {
        let tokens = ConfigTokenizer.tokenize("theme = Mocha")
        XCTAssertEqual(tokens, [.entry(key: "theme", raw: "Mocha", recognized: true)])
    }

    func test_entryWithSpacesAroundEquals() {
        let tokens = ConfigTokenizer.tokenize("font-size  =  14")
        XCTAssertEqual(tokens, [.entry(key: "font-size", raw: "14", recognized: true)])
    }

    func test_commentLine() {
        let tokens = ConfigTokenizer.tokenize("# this is a comment")
        XCTAssertEqual(tokens, [.comment("# this is a comment")])
    }

    func test_blankLine() {
        let tokens = ConfigTokenizer.tokenize("\n")
        XCTAssertEqual(tokens, [.blank])
    }

    func test_malformedLine() {
        let tokens = ConfigTokenizer.tokenize("garbage no equals here")
        XCTAssertEqual(tokens, [.malformed("garbage no equals here")])
    }

    func test_mixedFile() {
        let input = """
        # heading
        theme = Mocha

        font-size = 14
        garbage
        """
        let tokens = ConfigTokenizer.tokenize(input)
        XCTAssertEqual(tokens, [
            .comment("# heading"),
            .entry(key: "theme", raw: "Mocha", recognized: true),
            .blank,
            .entry(key: "font-size", raw: "14", recognized: true),
            .malformed("garbage")
        ])
    }

    func test_serialize_roundTrip() {
        let input = """
        # h
        theme = Mocha

        garbage
        """
        let tokens = ConfigTokenizer.tokenize(input)
        let out = ConfigTokenizer.serialize(tokens)
        XCTAssertEqual(out, input + "\n")
    }

    func test_serialize_patchesDirtyKey() {
        let tokens = ConfigTokenizer.tokenize("theme = Mocha\nfont-size = 14")
        let out = ConfigTokenizer.serialize(tokens, patching: ["theme": .string("TokyoNight")])
        XCTAssertTrue(out.contains("theme = TokyoNight"))
        XCTAssertTrue(out.contains("font-size = 14"))
        XCTAssertFalse(out.contains("Mocha"))
    }

    func test_serialize_appendsNewKey() {
        let tokens = ConfigTokenizer.tokenize("theme = Mocha")
        let out = ConfigTokenizer.serialize(
            tokens,
            patching: ["theme": .string("Mocha")],
            appending: ["font-size": .integer(16)]
        )
        XCTAssertTrue(out.contains("theme = Mocha"))
        XCTAssertTrue(out.contains("# Added by Specter"))
        XCTAssertTrue(out.contains("font-size = 16"))
    }

    func test_serialize_preservesCommentsAndBlanks() {
        let input = """
        # heading 1
        theme = Mocha

        # heading 2
        font-size = 14
        """
        let tokens = ConfigTokenizer.tokenize(input)
        let out = ConfigTokenizer.serialize(tokens, patching: ["theme": .string("TokyoNight")])
        XCTAssertTrue(out.contains("# heading 1"))
        XCTAssertTrue(out.contains("# heading 2"))
        // The blank line between headings should still be there
        XCTAssertTrue(out.contains("\n\n"))
    }
}
