import Foundation

// MARK: - Appearance variant

enum Appearance: String, CaseIterable, Identifiable, Codable {
    case light
    case lightHighContrast
    case dark
    case darkHighContrast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return String(localized: "Light (Any)")
        case .lightHighContrast: return String(localized: "Light High Contrast")
        case .dark: return String(localized: "Dark")
        case .darkHighContrast: return String(localized: "Dark High Contrast")
        }
    }

    /// Compact label for tight swatch columns.
    var shortLabel: String {
        switch self {
        case .light: return String(localized: "Light")
        case .lightHighContrast: return String(localized: "Light HC")
        case .dark: return String(localized: "Dark")
        case .darkHighContrast: return String(localized: "Dark HC")
        }
    }

    /// One-line explanation of when this variant is used.
    var roleDescription: String {
        switch self {
        case .light: return String(localized: "Light mode default (Any Appearance)")
        case .lightHighContrast: return String(localized: "Light with Increase Contrast on")
        case .dark: return String(localized: "Dark mode default")
        case .darkHighContrast: return String(localized: "Dark with Increase Contrast on")
        }
    }

    /// The system background this variant sits on (iOS systemBackground).
    var backgroundHex: String {
        switch self {
        case .light, .lightHighContrast: return "#FFFFFF"
        case .dark, .darkHighContrast: return "#000000"
        }
    }

    var secondaryBackgroundHex: String {
        switch self {
        case .light, .lightHighContrast: return "#F2F2F7"
        case .dark, .darkHighContrast: return "#1C1C1E"
        }
    }

    var isDark: Bool {
        self == .dark || self == .darkHighContrast
    }
}

// MARK: - AppearanceSet

struct AppearanceSet: Codable, Equatable {
    var light: String
    var lightHighContrast: String
    var dark: String
    var darkHighContrast: String

    subscript(_ appearance: Appearance) -> String {
        get {
            switch appearance {
            case .light: return light
            case .lightHighContrast: return lightHighContrast
            case .dark: return dark
            case .darkHighContrast: return darkHighContrast
            }
        }
        set {
            switch appearance {
            case .light: light = newValue
            case .lightHighContrast: lightHighContrast = newValue
            case .dark: dark = newValue
            case .darkHighContrast: darkHighContrast = newValue
            }
        }
    }
}

// MARK: - Derivation engine

/// Derives dark and high-contrast variants from a single light-mode color,
/// approximating the direction Apple's system colors move between appearances:
/// - Dark: slightly brighter and marginally more saturated (systemBlue #007AFF -> #0A84FF)
/// - Light HC: darker and more saturated until it clears 4.5:1 against white
/// - Dark HC: brighter until it clears 7:1 against black
enum VariantDeriver {

    static func derive(fromLight hex: String) -> AppearanceSet {
        guard let base = RGB(hex: hex) else {
            return AppearanceSet(light: "#000000", lightHighContrast: "#000000", dark: "#FFFFFF", darkHighContrast: "#FFFFFF")
        }
        let baseHSL = base.hsl
        let dark = deriveDark(from: baseHSL)
        return AppearanceSet(
            light: base.hexString,
            lightHighContrast: deriveLightHC(from: baseHSL, baseHex: base.hexString),
            dark: dark.rgb.hexString,
            darkHighContrast: deriveDarkHC(from: dark)
        )
    }

    private static func deriveDark(from hsl: HSL) -> HSL {
        HSL(
            h: hsl.h,
            s: (hsl.s + 3).clamped(0, 100),
            l: (hsl.l + 5).clamped(2, 96)
        )
    }

    private static func deriveLightHC(from hsl: HSL, baseHex: String) -> String {
        let white = RGB(r: 255, g: 255, b: 255)
        var l = hsl.l
        let s = (hsl.s + 8).clamped(0, 100)
        // Already accessible colors still get a small nudge, matching how
        // Apple's accessible variants are visibly stronger than the defaults.
        if WCAG.contrast(RGB(hex: baseHex)!, white) >= 4.5 {
            l = (l - 5).clamped(3, 100)
        }
        var candidate = HSL(h: hsl.h, s: s, l: l)
        var guardCount = 0
        while WCAG.contrast(candidate.rgb, white) < 4.5, l > 3, guardCount < 150 {
            l -= 1
            guardCount += 1
            candidate = HSL(h: hsl.h, s: s, l: l)
        }
        return candidate.rgb.hexString
    }

    private static func deriveDarkHC(from darkHSL: HSL) -> String {
        let black = RGB(r: 0, g: 0, b: 0)
        var l = darkHSL.l
        if WCAG.contrast(darkHSL.rgb, black) >= 7 {
            l = (l + 5).clamped(0, 97)
        }
        var candidate = HSL(h: darkHSL.h, s: darkHSL.s, l: l)
        var guardCount = 0
        while WCAG.contrast(candidate.rgb, black) < 7, l < 97, guardCount < 150 {
            l += 1
            guardCount += 1
            candidate = HSL(h: darkHSL.h, s: darkHSL.s, l: l)
        }
        return candidate.rgb.hexString
    }
}
