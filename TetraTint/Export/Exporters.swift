import Foundation
import AppKit
import UniformTypeIdentifiers

enum Exporters {

    // MARK: - Contents.json (Xcode asset catalog color set)

    static func contentsJSON(for set: AppearanceSet) -> String {
        func components(_ hex: String) -> String {
            let rgb = RGB(hex: hex) ?? RGB(r: 0, g: 0, b: 0)
            func h(_ v: Double) -> String {
                String(format: "0x%02X", Int(v.rounded().clamped(0, 255)))
            }
            return """
                    "color-space" : "srgb",
                    "components" : {
                      "alpha" : "1.000",
                      "blue" : "\(h(rgb.b))",
                      "green" : "\(h(rgb.g))",
                      "red" : "\(h(rgb.r))"
                    }
            """
        }

        return """
        {
          "colors" : [
            {
              "color" : {
        \(components(set.light))
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "contrast",
                  "value" : "high"
                }
              ],
              "color" : {
        \(components(set.lightHighContrast))
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "color" : {
        \(components(set.dark))
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                },
                {
                  "appearance" : "contrast",
                  "value" : "high"
                }
              ],
              "color" : {
        \(components(set.darkHighContrast))
              },
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
    }

    // MARK: - UIKit dynamic provider code

    static func uiKitCode(name: String, set: AppearanceSet) -> String {
        func rgbCall(_ hex: String) -> String {
            let rgb = RGB(hex: hex) ?? RGB(r: 0, g: 0, b: 0)
            let r = String(format: "%.3f", rgb.r / 255)
            let g = String(format: "%.3f", rgb.g / 255)
            let b = String(format: "%.3f", rgb.b / 255)
            return "UIColor(red: \(r), green: \(g), blue: \(b), alpha: 1)"
        }
        return """
        extension UIColor {
            /// \(name): light \(set.light), lightHC \(set.lightHighContrast), dark \(set.dark), darkHC \(set.darkHighContrast)
            static let \(name) = UIColor { traits in
                let isDark = traits.userInterfaceStyle == .dark
                let isHigh = traits.accessibilityContrast == .high
                switch (isDark, isHigh) {
                case (false, false): return \(rgbCall(set.light))
                case (false, true):  return \(rgbCall(set.lightHighContrast))
                case (true, false):  return \(rgbCall(set.dark))
                case (true, true):   return \(rgbCall(set.darkHighContrast))
                }
            }
        }
        """
    }

    // MARK: - SwiftUI code (asset-backed)

    static func swiftUICode(name: String, set: AppearanceSet) -> String {
        """
        extension Color {
            /// Backed by the "\(name)" color set in the asset catalog.
            /// Add \(name).colorset (exported from TetraTint) to Assets.xcassets,
            /// and all four appearance variants resolve automatically:
            /// light \(set.light) / lightHC \(set.lightHighContrast) / dark \(set.dark) / darkHC \(set.darkHighContrast)
            static let \(name) = Color("\(name)")
        }
        """
    }

    // MARK: - SwiftUI code (self-contained, no asset catalog)

    static func swiftUIProgrammaticCode(name: String, set: AppearanceSet) -> String {
        func rgbCall(_ hex: String) -> String {
            let rgb = RGB(hex: hex) ?? RGB(r: 0, g: 0, b: 0)
            let r = String(format: "%.3f", rgb.r / 255)
            let g = String(format: "%.3f", rgb.g / 255)
            let b = String(format: "%.3f", rgb.b / 255)
            return "UIColor(red: \(r), green: \(g), blue: \(b), alpha: 1)"
        }
        return """
        import SwiftUI

        extension Color {
            /// \(name): self-contained — resolves all four variants without an
            /// asset catalog by bridging a UIColor dynamic provider (iOS 15+).
            static let \(name) = Color(uiColor: UIColor { traits in
                let isDark = traits.userInterfaceStyle == .dark
                let isHigh = traits.accessibilityContrast == .high
                switch (isDark, isHigh) {
                case (false, false): return \(rgbCall(set.light))
                case (false, true):  return \(rgbCall(set.lightHighContrast))
                case (true, false):  return \(rgbCall(set.dark))
                case (true, true):   return \(rgbCall(set.darkHighContrast))
                }
            })
        }
        """
    }

    // MARK: - File export

    /// Exports a single <name>.colorset folder via a save panel.
    @MainActor
    static func exportColorSet(name: String, set: AppearanceSet) {
        let panel = NSSavePanel()
        panel.title = "Export color set"
        panel.nameFieldStringValue = "\(name).colorset"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try writeColorSet(to: url, set: set)
        } catch {
            presentError(error)
        }
    }

    /// Exports every saved palette item as an .xcassets catalog.
    @MainActor
    static func exportAssetCatalog(items: [PaletteItem]) {
        guard !items.isEmpty else { return }
        let panel = NSSavePanel()
        panel.title = "Export asset catalog"
        panel.nameFieldStringValue = "Colors.xcassets"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let fm = FileManager.default
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
            let rootInfo = """
            {
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }
            """
            try rootInfo.write(to: url.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
            for item in items {
                let setURL = url.appendingPathComponent("\(item.name).colorset")
                try writeColorSet(to: setURL, set: item.set)
            }
        } catch {
            presentError(error)
        }
    }

    private static func writeColorSet(to url: URL, set: AppearanceSet) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        let json = contentsJSON(for: set)
        try json.write(to: url.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    }

    @MainActor
    private static func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Export failed"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }

    // MARK: - Clipboard

    static func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
}
