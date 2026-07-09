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
    /// Color vision deficiency simulated across the whole app UI (.normal = off).
    @Published var previewCVD: CVDType = .normal

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

    var body: some View {
        ZStack(alignment: .top) {
            // The whole app, rendered through the active color-vision simulation.
            splitView

            // Swatches in flight from an "add" button to the Palette sidebar row.
            ForEach(fly.flights) { flight in
                FlyingSwatch(flight: flight, target: fly.target) { fly.finish(flight.id) }
            }

            // Kept outside the simulated layer so it stays truthful and legible.
            if appState.previewCVD != .normal {
                CVDPreviewBanner(type: appState.previewCVD) {
                    appState.previewCVD = .normal
                }
            }
        }
        .background(CVDWindowFilter(type: appState.previewCVD))
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
            ToolbarItem {
                Menu {
                    Picker("Color vision preview", selection: $appState.previewCVD) {
                        ForEach(CVDType.allCases) { type in
                            Text(LocalizedStringKey(type.rawValue)).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Color vision preview",
                          systemImage: appState.previewCVD == .normal
                            ? "eye" : "eye.trianglebadge.exclamationmark.fill")
                }
                .help("Preview the whole app as someone with color vision deficiency sees it")
            }
        }
    }

    private var sidebar: some View {
        // Each row is a plain Button that sets the section directly. This does
        // not rely on List/NavigationSplitView selection binding (which was
        // silently swallowing clicks) — a plain Button reliably fires on click.
        List {
            ForEach(AppSection.allCases) { section in
                Button {
                    appState.section = section
                } label: {
                    HStack {
                        Label {
                            Text(LocalizedStringKey(section.rawValue))
                        } icon: {
                            Image(systemName: section.icon)
                        }
                        Spacer()
                        if section == .palette, store.unseenCount > 0 {
                            Text("\(store.unseenCount)")
                                .font(.caption.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.accentColor, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    appState.section == section
                        ? Color.accentColor.opacity(0.18)
                        : Color.clear
                )
                .background(paletteAnchor(for: section))
            }
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
