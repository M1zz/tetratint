import SwiftUI

struct PaletteView: View {
    @EnvironmentObject private var store: PaletteStore

    var body: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Palette")
        .toolbar {
            ToolbarItem {
                Button {
                    Exporters.exportAssetCatalog(items: store.items)
                } label: {
                    Label("Export .xcassets", systemImage: "square.and.arrow.down.on.square")
                }
                .disabled(store.items.isEmpty)
                .help("Export every saved color as one asset catalog")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No saved colors")
                .font(.title3.weight(.semibold))
            Text("Generate a color and save it here, then export your whole brand palette as one .xcassets catalog.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Fixed width shared by the header labels and every swatch column so the
    /// whole table lines up in vertical columns regardless of label length.
    static let nameColumnWidth: CGFloat = 160
    static let variantColumnWidth: CGFloat = 92

    /// Column header, aligned to the exact same widths as each row below it.
    private var columnHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Each color is saved as four variants")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text("Color")
                    .frame(width: PaletteView.nameColumnWidth, alignment: .leading)
                ForEach(Appearance.allCases) { appearance in
                    Text(appearance.shortLabel)
                        .frame(width: PaletteView.variantColumnWidth)
                        .help(appearance.roleDescription)
                }
                Spacer(minLength: 0)
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                columnHeader
                ForEach(store.items) { item in
                    PaletteRow(
                        item: item,
                        isNew: item.id == store.lastAddedID,
                        onExport: { Exporters.exportColorSet(name: item.name, set: item.set) },
                        onDelete: { store.remove(item) }
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Row

private struct PaletteRow: View {
    let item: PaletteItem
    let isNew: Bool
    let onExport: () -> Void
    let onDelete: () -> Void

    /// Drives the pop-in: the row starts small + transparent, then springs into place.
    @State private var landed = false

    var body: some View {
        HStack(spacing: 12) {
            Text(item.name)
                .font(.system(.title3, design: .monospaced))
                .frame(width: PaletteView.nameColumnWidth, alignment: .leading)

            ForEach(Appearance.allCases) { appearance in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: item.set[appearance]))
                        .frame(width: 72, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                    Text(item.set[appearance])
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(width: PaletteView.variantColumnWidth)
                .help(appearance.displayName)
            }

            Spacer(minLength: 0)

            Button(action: onExport) {
                Image(systemName: "square.and.arrow.down")
            }
            .help("Export \(item.name).colorset")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .help("Delete")
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .scaleEffect(landed ? 1 : 0.3)
        .opacity(landed ? 1 : 0)
        .onAppear {
            guard isNew else {
                landed = true
                return
            }
            // Bouncy spring overshoots past 1.0 so the row visibly pops in.
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                landed = true
            }
        }
    }
}
