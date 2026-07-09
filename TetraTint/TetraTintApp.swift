import SwiftUI
import AppKit

// MARK: - Navigation sections

enum AppSection: String, CaseIterable, Identifiable {
    case color = "Color"
    case dynamicType = "Dynamic Type"
    case systemColors = "System colors"
    case palette = "Palette"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .color: return "paintbrush.pointed.fill"
        case .dynamicType: return "textformat.size"
        case .systemColors: return "paintpalette"
        case .palette: return "square.grid.2x2"
        }
    }
}

// MARK: - Shared working color

/// Single source of truth for the color the whole app is examining.
/// Every lens (Generator, Color vision, …) reads and edits the same color,
/// so picking or tweaking it in one place updates all the others.
@MainActor
final class AppState: ObservableObject {
    @Published var section: AppSection = .color
    @Published var set: AppearanceSet = VariantDeriver.derive(fromLight: "#007AFF")
    @Published var baseHex: String = "#007AFF"
    /// Export/asset name for the working color.
    @Published var colorName: String = "brandPrimary"
    /// True once any variant was hand-edited away from the derived value.
    @Published var hasManualEdits = false

    private let sampler = NSColorSampler()

    /// Re-derive all four variants from a single light-mode base color.
    func applyBase(_ hex: String) {
        guard let rgb = RGB(hex: hex) else { return }
        set = VariantDeriver.derive(fromLight: rgb.hexString)
        baseHex = rgb.hexString
        hasManualEdits = false
    }

    /// Sample any pixel on screen and make it the working color.
    func pickFromScreen(switchToColor: Bool = false) {
        sampler.show { [weak self] color in
            guard let color, let hex = color.hexString else { return }
            Task { @MainActor in
                self?.applyBase(hex)
                if switchToColor { self?.section = .color }
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

@main
struct TetraTintApp: App {
    @StateObject private var store = PaletteStore()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(appState)
                .frame(minWidth: 860, minHeight: 620)
        }
    }
}

// MARK: - Root navigation

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: PaletteStore
    @StateObject private var fly = FlyOverlayModel()

    private var selectionBinding: Binding<AppSection?> {
        Binding(
            get: { appState.section },
            set: { if let new = $0 { appState.section = new } }
        )
    }

    var body: some View {
        ZStack {
            splitView

            // Swatches in flight from an "add" button to the Palette sidebar row.
            ForEach(fly.flights) { flight in
                FlyingSwatch(flight: flight, target: fly.target) { fly.finish(flight.id) }
            }
        }
        .coordinateSpace(name: FlyOverlayModel.spaceName)
        .environmentObject(fly)
        .onPreferenceChange(PaletteAnchorKey.self) { fly.target = $0 }
        .onChange(of: appState.section) { newValue in
            // Clear the "new colors" badge once the user looks at the palette.
            if newValue == .palette { store.unseenCount = 0 }
        }
        // Scale every semantic text style up one step so the whole app reads larger.
        .dynamicTypeSize(.xLarge)
    }

    private var splitView: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItem {
                Button {
                    appState.pickFromScreen(switchToColor: true)
                } label: {
                    Label("Pick color from screen", systemImage: "eyedropper")
                }
                .help("Pick a color from anywhere on screen and make it the working color")
            }
        }
    }

    private var sidebar: some View {
        List(AppSection.allCases, selection: selectionBinding) { section in
            Label {
                Text(LocalizedStringKey(section.rawValue))
            } icon: {
                Image(systemName: section.icon)
            }
            .tag(section)
            .badge(section == .palette ? store.unseenCount : 0)
            .background(paletteAnchor(for: section))
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
    }

    @ViewBuilder
    private var detail: some View {
        switch appState.section {
        case .color: ColorWorkspaceView()
        case .dynamicType: DynamicTypeView()
        case .systemColors: SystemColorsView()
        case .palette: PaletteView()
        }
    }

    /// Publishes the Palette row's center so flights know where to land.
    @ViewBuilder
    private func paletteAnchor(for section: AppSection) -> some View {
        if section == .palette {
            GeometryReader { proxy in
                let f = proxy.frame(in: .named(FlyOverlayModel.spaceName))
                Color.clear.preference(
                    key: PaletteAnchorKey.self,
                    value: CGPoint(x: f.midX, y: f.midY)
                )
            }
        }
    }
}
