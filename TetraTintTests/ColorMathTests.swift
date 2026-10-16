import XCTest

final class ColorMathTests: XCTestCase {

    func testHexParsingAcceptsCommonForms() {
        XCTAssertEqual(RGB(hex: "#007AFF"), RGB(r: 0, g: 122, b: 255))
        XCTAssertEqual(RGB(hex: "007aff"), RGB(r: 0, g: 122, b: 255))
        XCTAssertEqual(RGB(hex: "  #fff \n"), RGB(r: 255, g: 255, b: 255))
    }

    func testHexParsingRejectsGarbage() {
        XCTAssertNil(RGB(hex: ""))
        XCTAssertNil(RGB(hex: "#12345"))
        XCTAssertNil(RGB(hex: "#GGGGGG"))
        XCTAssertNil(RGB(hex: "#1234567"))
    }

    func testHexStringRoundTripsAndClamps() {
        XCTAssertEqual(RGB(hex: "#5AC8FA")?.hexString, "#5AC8FA")
        XCTAssertEqual(RGB(r: -20, g: 300, b: 127.6).hexString, "#00FF80")
    }

    func testHSLRoundTripKeepsTheColor() {
        for hex in ["#007AFF", "#FF3B30", "#34C759", "#AF52DE", "#808080", "#000000", "#FFFFFF"] {
            let rgb = RGB(hex: hex)!
            XCTAssertEqual(rgb.hsl.rgb.hexString, hex, "HSL round trip changed \(hex)")
        }
    }

    func testWCAGContrastMatchesKnownValues() {
        // Black on white is the maximum, 21:1.
        XCTAssertEqual(WCAG.contrast(hex: "#000000", hex: "#FFFFFF"), 21, accuracy: 0.001)
        // Contrast is symmetric and a color against itself is 1:1.
        XCTAssertEqual(WCAG.contrast(hex: "#007AFF", hex: "#FFFFFF"),
                       WCAG.contrast(hex: "#FFFFFF", hex: "#007AFF"), accuracy: 1e-9)
        XCTAssertEqual(WCAG.contrast(hex: "#777777", hex: "#777777"), 1, accuracy: 1e-9)
        // #767676 on white is the well-known 4.54:1 boundary gray.
        XCTAssertEqual(WCAG.contrast(hex: "#767676", hex: "#FFFFFF"), 4.54, accuracy: 0.01)
        // Unparsable input is treated as "no contrast" rather than crashing.
        XCTAssertEqual(WCAG.contrast(hex: "nope", hex: "#FFFFFF"), 1)
    }

    func testColorNamesFollowHueAndLightness() {
        XCTAssertEqual("#FF0000".colorName, "Red")
        XCTAssertEqual("#000000".colorName, "Black")
        XCTAssertEqual("#FFFFFF".colorName, "White")
        XCTAssertEqual("#00008B".colorName, "Dark Blue")
        XCTAssertEqual("not a color".colorName, "not a color")
    }
}

final class VariantDeriverTests: XCTestCase {

    private let white = RGB(r: 255, g: 255, b: 255)
    private let black = RGB(r: 0, g: 0, b: 0)

    func testLightVariantIsTheBaseColor() {
        XCTAssertEqual(VariantDeriver.derive(fromLight: "#007aff").light, "#007AFF")
    }

    /// The promise of the Generator: the high-contrast variants always clear
    /// 4.5:1 on white (light) and 7:1 on black (dark), whatever the base color.
    func testHighContrastVariantsMeetTheirThresholds() {
        let bases = ["#007AFF", "#FFCC00", "#34C759", "#FF2D55", "#5AC8FA", "#FFFFFF",
                     "#000000", "#808080", "#F2F2F7", "#1C1C1E", "#AF52DE", "#00C7BE"]
        for base in bases {
            let set = VariantDeriver.derive(fromLight: base)
            let lightHC = RGB(hex: set.lightHighContrast)!
            let darkHC = RGB(hex: set.darkHighContrast)!
            XCTAssertGreaterThanOrEqual(WCAG.contrast(lightHC, white), 4.5, "Light HC of \(base) = \(set.lightHighContrast)")
            XCTAssertGreaterThanOrEqual(WCAG.contrast(darkHC, black), 7, "Dark HC of \(base) = \(set.darkHighContrast)")
        }
    }

    func testDarkVariantIsNotDarkerThanTheBase() {
        for base in ["#007AFF", "#FF3B30", "#34C759"] {
            let set = VariantDeriver.derive(fromLight: base)
            XCTAssertGreaterThanOrEqual(RGB(hex: set.dark)!.hsl.l, RGB(hex: base)!.hsl.l - 0.5)
        }
    }

    func testInvalidBaseFallsBackToBlackAndWhite() {
        let set = VariantDeriver.derive(fromLight: "oops")
        XCTAssertEqual(set, AppearanceSet(light: "#000000", lightHighContrast: "#000000",
                                          dark: "#FFFFFF", darkHighContrast: "#FFFFFF"))
    }

    func testSubscriptReadsAndWritesEachAppearance() {
        var set = VariantDeriver.derive(fromLight: "#007AFF")
        set[.darkHighContrast] = "#123456"
        XCTAssertEqual(set.darkHighContrast, "#123456")
        XCTAssertEqual(set[.light], set.light)
    }
}

final class CVDSimulationTests: XCTestCase {

    func testNormalVisionIsIdentity() {
        let c = RGB(hex: "#FF3B30")!
        XCTAssertEqual(CVDSimulator.simulate(c, type: .normal), c)
    }

    func testGrayscaleProducesNeutralGrayWithSameLuminance() {
        let c = RGB(hex: "#34C759")!
        let g = CVDSimulator.simulate(c, type: .grayscale)
        XCTAssertEqual(g.r, g.g, accuracy: 1e-9)
        XCTAssertEqual(g.g, g.b, accuracy: 1e-9)
        XCTAssertEqual(g.luminance, c.luminance, accuracy: 0.001)
    }

    func testSimulationKeepsBlackAndWhite() {
        for type in CVDType.allCases {
            XCTAssertEqual(CVDSimulator.simulate(RGB(hex: "#000000")!, type: type).hexString, "#000000", "\(type)")
            XCTAssertEqual(CVDSimulator.simulate(RGB(hex: "#FFFFFF")!, type: type).hexString, "#FFFFFF", "\(type)")
        }
    }

    /// Red and green are the classic pair that protan and deutan viewers confuse:
    /// they must end up much closer together than they are for normal vision.
    func testRedGreenCollapsesForProtanAndDeutan() {
        let red = RGB(hex: "#D55E00")!, green = RGB(hex: "#009E73")!
        let normal = LabColor.deltaE(red, green)
        for type in [CVDType.protanopia, .deuteranopia] {
            let d = LabColor.deltaE(CVDSimulator.simulate(red, type: type),
                                    CVDSimulator.simulate(green, type: type))
            XCTAssertLessThan(d, normal * 0.8, "\(type)")
        }
    }

    func testDeltaEIsZeroForSameColorAndSymmetric() {
        let a = RGB(hex: "#4477AA")!, b = RGB(hex: "#EE6677")!
        XCTAssertEqual(LabColor.deltaE(a, a), 0, accuracy: 1e-9)
        XCTAssertEqual(LabColor.deltaE(a, b), LabColor.deltaE(b, a), accuracy: 1e-9)
    }

    func testSafePalettesAreAllValidHex() {
        for palette in SafePalette.all {
            for hex in palette.hexes { XCTAssertNotNil(RGB(hex: hex), "\(palette.name): \(hex)") }
        }
    }
}

final class ExportTests: XCTestCase {

    /// The .colorset must be valid JSON with the four appearances Xcode expects.
    func testContentsJSONIsValidAssetCatalogColorSet() throws {
        let set = VariantDeriver.derive(fromLight: "#007AFF")
        let data = try XCTUnwrap(Exporters.contentsJSON(for: set).data(using: .utf8))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let colors = try XCTUnwrap(json["colors"] as? [[String: Any]])
        XCTAssertEqual(colors.count, 4)

        let first = try XCTUnwrap(colors.first?["color"] as? [String: Any])
        let comps = try XCTUnwrap(first["components"] as? [String: String])
        XCTAssertEqual(comps["red"], "0x00")
        XCTAssertEqual(comps["green"], "0x7A")
        XCTAssertEqual(comps["blue"], "0xFF")
    }
}

@MainActor
final class PaletteStoreTests: XCTestCase {
    private let key = "tetratint.palette.v1"

    override func setUp() async throws {
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: key)
    }

    func testNamesAreDeduplicatedSoExportsNeverCollide() {
        let store = PaletteStore()
        let set = VariantDeriver.derive(fromLight: "#007AFF")
        store.add(name: "brand", set: set)
        store.add(name: "brand", set: set)
        store.add(name: "brand", set: set)
        XCTAssertEqual(store.items.map(\.name), ["brand", "brand2", "brand3"])
    }

    func testBlankNameGetsAPlaceholder() {
        let store = PaletteStore()
        store.add(name: "   ", set: VariantDeriver.derive(fromLight: "#FF3B30"))
        XCTAssertEqual(store.items.first?.name, "Color1")
        XCTAssertEqual(store.unseenCount, 1)
    }

    func testPalettePersistsAcrossLaunches() {
        let first = PaletteStore()
        first.add(name: "accent", set: VariantDeriver.derive(fromLight: "#34C759"))
        let second = PaletteStore()
        XCTAssertEqual(second.items, first.items)
        second.remove(second.items[0])
        XCTAssertTrue(PaletteStore().items.isEmpty)
    }
}
