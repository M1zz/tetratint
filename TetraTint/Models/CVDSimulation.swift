import Foundation

// MARK: - Color vision deficiency types

enum CVDType: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case protanopia = "Protanopia"
    case deuteranopia = "Deuteranopia"
    case tritanopia = "Tritanopia"
    case grayscale = "Grayscale"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .normal: return String(localized: "Normal vision")
        case .protanopia: return String(localized: "Protan, about 1% of men")
        case .deuteranopia: return String(localized: "Deutan, about 1% of men")
        case .tritanopia: return String(localized: "Tritan, rare")
        case .grayscale: return String(localized: "Monochromacy")
        }
    }
}

// MARK: - Simulator

/// Simulates dichromatic color vision using the Machado et al. (2009)
/// severity-1.0 matrices, applied in linear sRGB.
enum CVDSimulator {

    private static let matrices: [CVDType: [[Double]]] = [
        .protanopia: [
            [0.152286, 1.052583, -0.204868],
            [0.114503, 0.786281, 0.099216],
            [-0.003882, -0.048116, 1.051998]
        ],
        .deuteranopia: [
            [0.367322, 0.860646, -0.227968],
            [0.280085, 0.672501, 0.047413],
            [-0.011820, 0.042940, 0.968881]
        ],
        .tritanopia: [
            [1.255528, -0.076749, -0.178779],
            [-0.078411, 0.930809, 0.147602],
            [0.004733, 0.691367, 0.303900]
        ]
    ]

    /// The Machado severity-1.0 matrix for a dichromacy type (nil for
    /// normal/grayscale, which aren't a linear 3×3 transform). Exposed so the
    /// live GPU preview uses the exact same math as the swatch simulation.
    static func matrix(for type: CVDType) -> [[Double]]? { matrices[type] }

    static func simulate(_ rgb: RGB, type: CVDType) -> RGB {
        switch type {
        case .normal:
            return rgb
        case .grayscale:
            let y = rgb.luminance
            let v = delinearize(y) * 255
            return RGB(r: v, g: v, b: v)
        default:
            guard let m = matrices[type] else { return rgb }
            let r = linearize(rgb.r / 255)
            let g = linearize(rgb.g / 255)
            let b = linearize(rgb.b / 255)
            let nr = m[0][0] * r + m[0][1] * g + m[0][2] * b
            let ng = m[1][0] * r + m[1][1] * g + m[1][2] * b
            let nb = m[2][0] * r + m[2][1] * g + m[2][2] * b
            return RGB(
                r: delinearize(nr.clamped(0, 1)) * 255,
                g: delinearize(ng.clamped(0, 1)) * 255,
                b: delinearize(nb.clamped(0, 1)) * 255
            )
        }
    }

    private static func linearize(_ c: Double) -> Double {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    private static func delinearize(_ c: Double) -> Double {
        c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055
    }
}

// MARK: - CIE Lab / delta E

enum LabColor {

    static func lab(from rgb: RGB) -> (l: Double, a: Double, b: Double) {
        func lin(_ c: Double) -> Double {
            let v = c / 255
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        let r = lin(rgb.r), g = lin(rgb.g), b = lin(rgb.b)
        let x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        let y = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 1.0
        let z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        func f(_ t: Double) -> Double {
            t > 0.008856 ? cbrt(t) : 7.787 * t + 16.0 / 116.0
        }
        let fx = f(x), fy = f(y), fz = f(z)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }

    /// CIE76 color difference. Below ~12 two colors become hard to tell
    /// apart at a glance; below ~6 they are effectively identical.
    static func deltaE(_ a: RGB, _ b: RGB) -> Double {
        let la = lab(from: a), lb = lab(from: b)
        let dl = la.l - lb.l, da = la.a - lb.a, db = la.b - lb.b
        return sqrt(dl * dl + da * da + db * db)
    }
}

// MARK: - Colorblind-safe reference palettes

struct SafePalette: Identifiable {
    let id = UUID()
    let name: String
    let source: String
    let hexes: [String]

    static let all: [SafePalette] = [
        SafePalette(
            name: "Okabe Ito",
            source: String(localized: "Scientific visualization standard, 8 colors"),
            hexes: ["#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"]
        ),
        SafePalette(
            name: "IBM Design",
            source: String(localized: "IBM accessibility palette, 5 colors"),
            hexes: ["#648FFF", "#785EF0", "#DC267F", "#FE6100", "#FFB000"]
        ),
        SafePalette(
            name: "Paul Tol Bright",
            source: String(localized: "Qualitative data visualization, 7 colors"),
            hexes: ["#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#BBBBBB"]
        )
    ]
}
