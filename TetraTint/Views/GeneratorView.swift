import SwiftUI

/// "Variants" lens: the four appearance variants of the working color plus
/// the export panel. The color itself is edited in the workspace header.
struct VariantsLens: View {
    @EnvironmentObject private var appState: AppState

    @State private var exportTab: ExportTab = .contentsJSON
    @State private var showCopied = false

    private var set: AppearanceSet { appState.set }

    private enum ExportTab: String, CaseIterable, Identifiable {
        case contentsJSON = "Contents.json"
        case uiKit = "UIKit"
        case swiftUIAsset = "SwiftUI (asset)"
        case swiftUICode = "SwiftUI (code)"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            variantGrid
            exportSection
        }
    }

    // MARK: Four-pane grid

    private var variantGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 300), spacing: 12)],
            spacing: 12
        ) {
            ForEach(Appearance.allCases) { appearance in
                VariantCard(
                    appearance: appearance,
                    hex: binding(for: appearance),
                    onManualEdit: { appState.hasManualEdits = true }
                )
            }
        }
    }

    private func binding(for appearance: Appearance) -> Binding<String> {
        Binding(
            get: { appState.set[appearance] },
            set: { newValue in
                appState.set[appearance] = newValue
                if appearance == .light {
                    appState.baseHex = newValue
                }
            }
        )
    }

    // MARK: Export

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Export")
                    .font(.title3.weight(.semibold))
                Picker("", selection: $exportTab) {
                    ForEach(ExportTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 440)

                Spacer()

                Button {
                    Exporters.copyToClipboard(exportText)
                    flashCopied()
                } label: {
                    Label(showCopied ? "Copied" : "Copy", systemImage: "doc.on.doc")
                }

                Button {
                    Exporters.exportColorSet(name: appState.colorName, set: set)
                } label: {
                    Label("Save .colorset", systemImage: "square.and.arrow.down")
                }
            }

            ScrollView(.horizontal) {
                Text(exportText)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 240)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private var exportText: String {
        switch exportTab {
        case .contentsJSON: return Exporters.contentsJSON(for: set)
        case .uiKit: return Exporters.uiKitCode(name: appState.colorName, set: set)
        case .swiftUIAsset: return Exporters.swiftUICode(name: appState.colorName, set: set)
        case .swiftUICode: return Exporters.swiftUIProgrammaticCode(name: appState.colorName, set: set)
        }
    }

    private func flashCopied() {
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showCopied = false
        }
    }
}
