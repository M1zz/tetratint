import Foundation

// MARK: - System color reference entry

struct SystemColorEntry: Identifiable {
    let id = UUID()
    let name: String          // e.g. "systemBlue"
    let swiftUIName: String   // e.g. "Color.blue"
    let set: AppearanceSet
}

/// Reference values from Apple's Human Interface Guidelines color tables.
/// These are for design reference only — Apple explicitly notes actual values
/// may fluctuate between OS releases, so shipping apps should always use the
/// UIColor / Color API rather than hard-coding.
enum SystemColorData {

    static let tints: [SystemColorEntry] = [
        SystemColorEntry(
            name: "systemRed", swiftUIName: "Color.red",
            set: AppearanceSet(light: "#FF3B30", lightHighContrast: "#D70015", dark: "#FF453A", darkHighContrast: "#FF6961")
        ),
        SystemColorEntry(
            name: "systemOrange", swiftUIName: "Color.orange",
            set: AppearanceSet(light: "#FF9500", lightHighContrast: "#C93400", dark: "#FF9F0A", darkHighContrast: "#FFB340")
        ),
        SystemColorEntry(
            name: "systemYellow", swiftUIName: "Color.yellow",
            set: AppearanceSet(light: "#FFCC00", lightHighContrast: "#B25000", dark: "#FFD60A", darkHighContrast: "#FFD426")
        ),
        SystemColorEntry(
            name: "systemGreen", swiftUIName: "Color.green",
            set: AppearanceSet(light: "#34C759", lightHighContrast: "#248A3D", dark: "#30D158", darkHighContrast: "#30DB5B")
        ),
        SystemColorEntry(
            name: "systemMint", swiftUIName: "Color.mint",
            set: AppearanceSet(light: "#00C7BE", lightHighContrast: "#0C817B", dark: "#63E6E2", darkHighContrast: "#66D4CF")
        ),
        SystemColorEntry(
            name: "systemTeal", swiftUIName: "Color.teal",
            set: AppearanceSet(light: "#30B0C7", lightHighContrast: "#008299", dark: "#40C8E0", darkHighContrast: "#5DE6FF")
        ),
        SystemColorEntry(
            name: "systemCyan", swiftUIName: "Color.cyan",
            set: AppearanceSet(light: "#32ADE6", lightHighContrast: "#0071A4", dark: "#64D2FF", darkHighContrast: "#70D7FF")
        ),
        SystemColorEntry(
            name: "systemBlue", swiftUIName: "Color.blue",
            set: AppearanceSet(light: "#007AFF", lightHighContrast: "#0040DD", dark: "#0A84FF", darkHighContrast: "#409CFF")
        ),
        SystemColorEntry(
            name: "systemIndigo", swiftUIName: "Color.indigo",
            set: AppearanceSet(light: "#5856D6", lightHighContrast: "#3634A3", dark: "#5E5CE6", darkHighContrast: "#7D7AFF")
        ),
        SystemColorEntry(
            name: "systemPurple", swiftUIName: "Color.purple",
            set: AppearanceSet(light: "#AF52DE", lightHighContrast: "#8944AB", dark: "#BF5AF2", darkHighContrast: "#DA8FFF")
        ),
        SystemColorEntry(
            name: "systemPink", swiftUIName: "Color.pink",
            set: AppearanceSet(light: "#FF2D55", lightHighContrast: "#D30F45", dark: "#FF375F", darkHighContrast: "#FF6482")
        ),
        SystemColorEntry(
            name: "systemBrown", swiftUIName: "Color.brown",
            set: AppearanceSet(light: "#A2845E", lightHighContrast: "#7F6545", dark: "#AC8E68", darkHighContrast: "#B59469")
        )
    ]

    static let grays: [SystemColorEntry] = [
        SystemColorEntry(
            name: "systemGray", swiftUIName: "Color(.systemGray)",
            set: AppearanceSet(light: "#8E8E93", lightHighContrast: "#6C6C70", dark: "#8E8E93", darkHighContrast: "#AEAEB2")
        ),
        SystemColorEntry(
            name: "systemGray2", swiftUIName: "Color(.systemGray2)",
            set: AppearanceSet(light: "#AEAEB2", lightHighContrast: "#8E8E93", dark: "#636366", darkHighContrast: "#7C7C80")
        ),
        SystemColorEntry(
            name: "systemGray3", swiftUIName: "Color(.systemGray3)",
            set: AppearanceSet(light: "#C7C7CC", lightHighContrast: "#AEAEB2", dark: "#48484A", darkHighContrast: "#545456")
        ),
        SystemColorEntry(
            name: "systemGray4", swiftUIName: "Color(.systemGray4)",
            set: AppearanceSet(light: "#D1D1D6", lightHighContrast: "#BCBCC0", dark: "#3A3A3C", darkHighContrast: "#444446")
        ),
        SystemColorEntry(
            name: "systemGray5", swiftUIName: "Color(.systemGray5)",
            set: AppearanceSet(light: "#E5E5EA", lightHighContrast: "#D8D8DC", dark: "#2C2C2E", darkHighContrast: "#363638")
        ),
        SystemColorEntry(
            name: "systemGray6", swiftUIName: "Color(.systemGray6)",
            set: AppearanceSet(light: "#F2F2F7", lightHighContrast: "#EBEBF0", dark: "#1C1C1E", darkHighContrast: "#242426")
        )
    ]
}
