import Foundation
import SwiftUI
import AppKit

// MARK: - RGB

struct RGB: Equatable, Codable {
    var r: Double // 0...255
    var g: Double // 0...255
    var b: Double // 0...255

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        guard h.count == 6, let value = UInt32(h, radix: 16) else { return nil }
        r = Double((value >> 16) & 0xFF)
        g = Double((value >> 8) & 0xFF)
        b = Double(value & 0xFF)
    }

    var hexString: String {
        String(
            format: "#%02X%02X%02X",
            Int(r.rounded().clamped(0, 255)),
            Int(g.rounded().clamped(0, 255)),
            Int(b.rounded().clamped(0, 255))
        )
    }

    // MARK: HSL conversion

    var hsl: HSL {
        let rr = r / 255, gg = g / 255, bb = b / 255
        let mx = max(rr, gg, bb), mn = min(rr, gg, bb)
        let l = (mx + mn) / 2
        var h = 0.0, s = 0.0
        if mx != mn {
            let d = mx - mn
            s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
            switch mx {
            case rr: h = (gg - bb) / d + (gg < bb ? 6 : 0)
            case gg: h = (bb - rr) / d + 2
            default: h = (rr - gg) / d + 4
            }
            h /= 6
        }
        return HSL(h: h * 360, s: s * 100, l: l * 100)
    }

    // MARK: WCAG relative luminance

    var luminance: Double {
        func channel(_ v: Double) -> Double {
            let c = v / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}

// MARK: - HSL

struct HSL {
    var h: Double // 0...360
    var s: Double // 0...100
    var l: Double // 0...100

    var rgb: RGB {
        let hh = h / 360
        let ss = (s / 100).clamped(0, 1)
        let ll = (l / 100).clamped(0, 1)
        if ss == 0 {
            let v = ll * 255
            return RGB(r: v, g: v, b: v)
        }
        let q = ll < 0.5 ? ll * (1 + ss) : ll + ss - ll * ss
        let p = 2 * ll - q
        func hue(_ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }
        return RGB(
            r: hue(hh + 1 / 3) * 255,
            g: hue(hh) * 255,
            b: hue(hh - 1 / 3) * 255
        )
    }
}

// MARK: - Contrast

enum WCAG {
    static func contrast(_ a: RGB, _ b: RGB) -> Double {
        let l1 = a.luminance, l2 = b.luminance
        let hi = max(l1, l2), lo = min(l1, l2)
        return (hi + 0.05) / (lo + 0.05)
    }

    static func contrast(hex a: String, hex b: String) -> Double {
        guard let ca = RGB(hex: a), let cb = RGB(hex: b) else { return 1 }
        return contrast(ca, cb)
    }
}

// MARK: - Helpers

extension Double {
    func clamped(_ lo: Double, _ hi: Double) -> Double {
        Swift.min(Swift.max(self, lo), hi)
    }
}

extension Color {
    init(hex: String) {
        let rgb = RGB(hex: hex) ?? RGB(r: 0, g: 0, b: 0)
        self.init(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255)
    }
}

extension NSColor {
    var hexString: String? {
        guard let srgb = usingColorSpace(.sRGB) else { return nil }
        return RGB(
            r: Double(srgb.redComponent) * 255,
            g: Double(srgb.greenComponent) * 255,
            b: Double(srgb.blueComponent) * 255
        ).hexString
    }
}
