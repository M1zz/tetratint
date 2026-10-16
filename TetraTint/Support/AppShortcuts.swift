import AppIntents

// MARK: - 단축어 · Spotlight
//
// 앱을 연 뒤 하는 첫 동작 두 가지를 단축어로 바로 부른다.
// 두 동작 모두 앱 창이 필요하므로 앱을 열고(openAppWhenRun) 그 안에서 실행한다.

/// 화면에서 색을 집어 작업 색으로 — TetraTint 의 가장 흔한 시작.
struct PickColorFromScreenIntent: AppIntent {
    static var title: LocalizedStringResource = "Pick Color from Screen"
    static var description = IntentDescription("Opens TetraTint and starts the eyedropper so you can pick any color on screen.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.pickFromScreen(switchToColor: true)
        return .result()
    }
}

/// 사이드바 화면 하나를 곧장 연다.
struct OpenTetraTintSectionIntent: AppIntent {
    static var title: LocalizedStringResource = "Open in TetraTint"
    static var description = IntentDescription("Opens a TetraTint screen: Color, Dynamic Type, System colors, or Palette.")
    static var openAppWhenRun = true

    @Parameter(title: "Screen")
    var section: AppSectionEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.section = section.appSection
        return .result()
    }
}

enum AppSectionEntity: String, AppEnum {
    case color, dynamicType, systemColors, palette

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Screen"
    static var caseDisplayRepresentations: [AppSectionEntity: DisplayRepresentation] = [
        .color: DisplayRepresentation(title: "Color", image: .init(systemName: "paintbrush.pointed.fill")),
        .dynamicType: DisplayRepresentation(title: "Dynamic Type", image: .init(systemName: "textformat.size")),
        .systemColors: DisplayRepresentation(title: "System colors", image: .init(systemName: "paintpalette")),
        .palette: DisplayRepresentation(title: "Palette", image: .init(systemName: "square.grid.2x2")),
    ]

    var appSection: AppSection {
        switch self {
        case .color: return .color
        case .dynamicType: return .dynamicType
        case .systemColors: return .systemColors
        case .palette: return .palette
        }
    }
}

struct TetraTintShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PickColorFromScreenIntent(),
            phrases: [
                "Pick a color with \(.applicationName)",
                "Pick a color from screen in \(.applicationName)",
            ],
            shortTitle: "Pick Color",
            systemImageName: "eyedropper"
        )
        AppShortcut(
            intent: OpenTetraTintSectionIntent(),
            phrases: [
                "Open \(\.$section) in \(.applicationName)",
                "Show \(.applicationName) \(\.$section)",
            ],
            shortTitle: "Open Screen",
            systemImageName: "sidebar.left"
        )
    }
}
