import SwiftUI
import AppKit

/// The color-first workspace: one working color pinned at the top, with a
/// lens switcher (Variants / Contrast / Color vision) that swaps only the
/// panel below. Switching perspective never navigates away from the color.
struct ColorWorkspaceView: View {
    @EnvironmentObject private var store: PaletteStore
    @EnvironmentObject private var appState: AppState

    @State private var lens: Lens = .variants
    private let purchases = PurchaseManager.shared
    /// Local editing buffer for the hex field, synced with the shared color.
    @State private var baseHexField: String = "#007AFF"

    enum Lens: String, CaseIterable, Identifiable {
        case variants = "Variants"
        case preview = "Preview"
        case contrast = "Contrast"
        case colorVision = "Color vision"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .variants: return "square.grid.2x2.fill"
            case .preview: return "macwindow"
            case .contrast: return "circle.lefthalf.filled"
            case .colorVision: return "eye.fill"
            }
        }

        /// Verb-form label shown on the lens tab (the action each lens performs).
        var title: LocalizedStringKey {
            switch self {
            case .variants: return "Generate variants"
            case .preview: return "Preview in use"
            case .contrast: return "Check contrast"
            case .colorVision: return "Simulate color vision"
            }
        }

        var purpose: LocalizedStringKey {
            switch self {
            case .variants: return "Generate and export light, dark, and high-contrast variants"
            case .preview: return "See the color in use, as it is and as people with color weakness or color blindness see it"
            case .contrast: return "Check the color against WCAG contrast thresholds"
            case .colorVision: return "Simulate how the color looks with color vision deficiency"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(20)

            Divider()

            lensSwitcher
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

            Divider()

            ScrollView {
                lensContent
                    .padding(20)
            }
        }
        .navigationTitle("Color")
        .onAppear { baseHexField = appState.baseHex }
        .onChange(of: appState.baseHex) { baseHexField = $0 }
        // 구독이 끝나 색각 렌즈가 다시 잠겼으면 열려 있던 렌즈를 닫는다.
        .onChange(of: purchases.allows(.colorVision)) { _, allowed in
            if !allowed, lens == .colorVision { lens = .variants }
        }
    }

    // MARK: Lens switcher

    private var lensSwitcher: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Lens.allCases) { option in
                    let lock = option == .colorVision ? purchases.lock(.colorVision) : nil
                    Button {
                        if let lock { appState.paywall = lock } else { lens = option }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: lock == nil ? option.icon : "lock.fill")
                            Text(option.title)
                        }
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity)
                        .background(lens == option ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(lens == option ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.primary.opacity(lens == option ? 0 : 0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(lens == option ? .isSelected : [])
                }
            }
            .frame(maxWidth: 820)

            Text(lens.purpose)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var lensContent: some View {
        switch lens {
        case .variants: VariantsLens()
        case .preview: PreviewLens()
        case .contrast: ContrastLens()
        case .colorVision: ColorVisionLens()
        }
    }

    // MARK: Pinned working-color header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ColorPicker(
                    "",
                    selection: Binding(
                        get: { Color(hex: appState.set.light) },
                        set: { if let hex = NSColor($0).hexString { appState.applyBase(hex) } }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
                .accessibilityLabel(Text("Working color"))
                .accessibilityValue(Text("\(appState.set.light.colorName), \(appState.set.light)"))

                Button {
                    appState.pickFromScreen()
                } label: {
                    Image(systemName: "eyedropper")
                }
                .help("Pick a color from anywhere on screen")
                .accessibilityLabel(Text("Pick a color from anywhere on screen"))
                .accessibilityInputLabels([Text("Pick color from screen"), Text("Eyedropper")])

                TextField("#007AFF", text: $baseHexField)
                    .accessibilityLabel(Text("Hex value"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.title3, design: .monospaced))
                    .frame(width: 120)
                    .onSubmit {
                        if RGB(hex: baseHexField) != nil {
                            appState.applyBase(baseHexField)
                        }
                    }

                TextField("Color name", text: $appState.colorName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)

                if appState.hasManualEdits {
                    Button("Regenerate all") {
                        appState.applyBase(appState.set.light)
                    }
                    .help("Discard manual edits and re-derive from the base color")
                }

                Spacer()

                let lock = purchases.paletteLock(existing: store.items.count)
                FlyingAddButton(color: Color(hex: appState.set.light), lock: lock) {
                    store.add(name: appState.colorName, set: appState.set)
                } label: {
                    Label("Save to palette", systemImage: lock == nil ? "square.grid.2x2" : "lock")
                }
            }

            presetRow
        }
    }

    private var presetRow: some View {
        HStack(spacing: 6) {
            Text("Presets")
                .font(.callout)
                .foregroundStyle(.secondary)
            ForEach(SystemColorData.tints) { entry in
                Button {
                    appState.applyBase(entry.set.light)
                } label: {
                    Circle()
                        .fill(Color(hex: entry.set.light))
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .help(Text(verbatim: "\(entry.name), \(entry.set.light.colorName)"))
                .accessibilityLabel(Text("Preset \(entry.name)"))
                .accessibilityValue(Text(verbatim: "\(entry.set.light.colorName), \(entry.set.light)"))
            }
        }
    }
}
