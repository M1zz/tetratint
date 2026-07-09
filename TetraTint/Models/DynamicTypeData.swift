import Foundation

// MARK: - Text style reference

struct TextStyleInfo: Identifiable {
    let id = UUID()
    let name: String          // display name
    let swiftUIStyle: String  // Font.TextStyle case
    let uiKitStyle: String    // UIFont.TextStyle case
    let weight: String
    /// Point sizes for the seven standard content size categories:
    /// xSmall, Small, Medium, Large (default), xLarge, xxLarge, xxxLarge
    let sizes: [Int]
}

enum DynamicTypeData {

    static let categories = ["xSmall", "Small", "Medium", "Large ✻", "xLarge", "xxLarge", "xxxLarge"]

    /// iOS default (Large) point sizes with per-category scaling,
    /// from Apple's HIG typography tables.
    static let styles: [TextStyleInfo] = [
        TextStyleInfo(name: "Large Title", swiftUIStyle: "largeTitle", uiKitStyle: "largeTitle", weight: "Regular", sizes: [31, 32, 33, 34, 36, 38, 40]),
        TextStyleInfo(name: "Title 1", swiftUIStyle: "title", uiKitStyle: "title1", weight: "Regular", sizes: [25, 26, 27, 28, 30, 32, 34]),
        TextStyleInfo(name: "Title 2", swiftUIStyle: "title2", uiKitStyle: "title2", weight: "Regular", sizes: [19, 20, 21, 22, 24, 26, 28]),
        TextStyleInfo(name: "Title 3", swiftUIStyle: "title3", uiKitStyle: "title3", weight: "Regular", sizes: [17, 18, 19, 20, 22, 24, 26]),
        TextStyleInfo(name: "Headline", swiftUIStyle: "headline", uiKitStyle: "headline", weight: "Semibold", sizes: [14, 15, 16, 17, 19, 21, 23]),
        TextStyleInfo(name: "Body", swiftUIStyle: "body", uiKitStyle: "body", weight: "Regular", sizes: [14, 15, 16, 17, 19, 21, 23]),
        TextStyleInfo(name: "Callout", swiftUIStyle: "callout", uiKitStyle: "callout", weight: "Regular", sizes: [13, 14, 15, 16, 18, 20, 22]),
        TextStyleInfo(name: "Subheadline", swiftUIStyle: "subheadline", uiKitStyle: "subheadline", weight: "Regular", sizes: [12, 13, 14, 15, 17, 19, 21]),
        TextStyleInfo(name: "Footnote", swiftUIStyle: "footnote", uiKitStyle: "footnote", weight: "Regular", sizes: [12, 12, 12, 13, 15, 17, 19]),
        TextStyleInfo(name: "Caption 1", swiftUIStyle: "caption", uiKitStyle: "caption1", weight: "Regular", sizes: [11, 11, 11, 12, 14, 16, 18]),
        TextStyleInfo(name: "Caption 2", swiftUIStyle: "caption2", uiKitStyle: "caption2", weight: "Regular", sizes: [11, 11, 11, 11, 13, 15, 17])
    ]

    /// Body sizes for the five accessibility categories (AX1–AX5),
    /// to show how far layouts must stretch.
    static let bodyAccessibilitySizes = [28, 33, 40, 47, 53]

    // MARK: - Code generation

    static func uiKitSnippet(fontName: String, style: TextStyleInfo, baseSize: Int) -> String {
        """
        // Custom font that scales with Dynamic Type (UIKit)
        // Base: \(baseSize)pt at the default (Large) category, tracking .\(style.uiKitStyle)
        let baseFont = UIFont(name: "\(fontName)", size: \(baseSize))
            ?? .systemFont(ofSize: \(baseSize))
        label.font = UIFontMetrics(forTextStyle: .\(style.uiKitStyle))
            .scaledFont(for: baseFont)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0   // never truncate scaled text

        // Respond to the Bold Text accessibility setting
        override func traitCollectionDidChange(_ previous: UITraitCollection?) {
            super.traitCollectionDidChange(previous)
            if traitCollection.legibilityWeight == .bold {
                // Swap in the bold cut of your custom font here
            }
        }
        """
    }

    static func swiftUISnippet(fontName: String, style: TextStyleInfo, baseSize: Int) -> String {
        """
        // Custom font that scales with Dynamic Type (SwiftUI)
        Text("Hello")
            .font(.custom("\(fontName)", size: \(baseSize), relativeTo: .\(style.swiftUIStyle)))

        // Scale spacing and icons together with the text;
        // fixed paddings break at accessibility sizes
        @ScaledMetric(relativeTo: .\(style.swiftUIStyle))
        private var iconSize: CGFloat = 24

        Image(systemName: "star.fill")
            .frame(width: iconSize, height: iconSize)

        // Cap runaway layouts only when truly necessary (iOS 15+)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)

        // Bold Text setting
        @Environment(\\.legibilityWeight) private var legibilityWeight
        """
    }

    static func layoutSnippet() -> String {
        """
        // Layouts that survive AX sizes: switch stacking direction
        // when the type gets large (iOS 16+)
        @Environment(\\.dynamicTypeSize) private var typeSize

        var body: some View {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading))
                : AnyLayout(HStackLayout())
            layout {
                Image(systemName: "clock")
                Text("Updated")
                Spacer()
                Text("9:41 AM")
            }
        }
        """
    }
}
