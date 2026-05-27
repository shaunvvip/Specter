import XCTest
import SwiftUI
import AppKit
@testable import Specter

final class ColorMixTests: XCTestCase {
    func test_hexStringInit_withHash() {
        let c = Color(hexString: "#ff8040")
        XCTAssertEqual(rgb(c).r, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgb(c).g, 128.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(rgb(c).b, 64.0 / 255.0, accuracy: 0.01)
    }

    func test_hexStringInit_withoutHash() {
        let c = Color(hexString: "ff8040")
        XCTAssertEqual(rgb(c).r, 1.0, accuracy: 0.01)
    }

    func test_hexStringInit_malformedReturnsFallback() {
        let fallback = Color(hex: 0xabcdef)
        let c = Color(hexString: "not a hex", fallback: fallback)
        XCTAssertEqual(rgb(c).r, rgb(fallback).r, accuracy: 0.01)
    }

    func test_lightened_movesTowardWhite() {
        let dark = Color(hex: 0x101010)
        let lighter = dark.lightened(0.5)
        XCTAssertGreaterThan(rgb(lighter).r, rgb(dark).r)
    }

    func test_darkened_movesTowardBlack() {
        let light = Color(hex: 0xeeeeee)
        let darker = light.darkened(0.5)
        XCTAssertLessThan(rgb(darker).r, rgb(light).r)
    }

    func test_mix_amountZero_returnsSelf() {
        let original = Color(hex: 0x336699)
        let mixed = original.mix(toward: .white, amount: 0)
        XCTAssertEqual(rgb(mixed).r, rgb(original).r, accuracy: 0.01)
    }

    func test_mix_amountOne_returnsTarget() {
        let mixed = Color(hex: 0x336699).mix(toward: .white, amount: 1.0)
        XCTAssertEqual(rgb(mixed).r, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgb(mixed).g, 1.0, accuracy: 0.01)
        XCTAssertEqual(rgb(mixed).b, 1.0, accuracy: 0.01)
    }

    private func rgb(_ c: Color) -> (r: Double, g: Double, b: Double) {
        let ns = NSColor(c).usingColorSpace(.sRGB)!
        return (Double(ns.redComponent), Double(ns.greenComponent), Double(ns.blueComponent))
    }
}
