import Foundation

// MARK: - Human-readable color names
//
// A color-blind (or screen-reader) user can't rely on the swatch alone, so
// every swatch also carries a spoken name. We derive a coarse but reliable
// name from HSL: neutrals by lightness, hues by a 12-way wheel, with a
// light/dark/pale qualifier. Names are localized (English keys → ko.lproj).

extension RGB {
    /// A short, localized color name such as "Dark blue" / "어두운 파랑".
    var colorName: String {
        let c = hsl

        // Near-neutral: name by lightness, ignore hue.
        if c.s < 12 {
            switch c.l {
            case ..<10:  return String(localized: "Black")
            case ..<35:  return String(localized: "Dark gray")
            case ..<70:  return String(localized: "Gray")
            case ..<92:  return String(localized: "Light gray")
            default:     return String(localized: "White")
            }
        }

        let hue: String
        switch c.h {
        case ..<15, 345...: hue = String(localized: "Red")
        case ..<45:         hue = String(localized: "Orange")
        case ..<66:         hue = String(localized: "Yellow")
        case ..<90:         hue = String(localized: "Lime")
        case ..<150:        hue = String(localized: "Green")
        case ..<185:        hue = String(localized: "Teal")
        case ..<205:        hue = String(localized: "Sky blue")
        case ..<250:        hue = String(localized: "Blue")
        case ..<270:        hue = String(localized: "Indigo")
        case ..<300:        hue = String(localized: "Purple")
        case ..<330:        hue = String(localized: "Magenta")
        default:            hue = String(localized: "Pink")
        }

        // Lightness qualifier. Low saturation + high lightness reads as "pale".
        let qualifier: String?
        switch c.l {
        case ..<30:  qualifier = String(localized: "Dark")
        case 80...:  qualifier = c.s < 45 ? String(localized: "Pale") : String(localized: "Light")
        default:     qualifier = nil
        }

        if let q = qualifier { return "\(q) \(hue)" }
        return hue
    }
}

extension String {
    /// Color name for a hex string, falling back to the raw string if unparsable.
    var colorName: String { RGB(hex: self)?.colorName ?? self }
}
