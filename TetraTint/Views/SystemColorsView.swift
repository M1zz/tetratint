import SwiftUI

/// Adaptivity-style system color reference, with one key difference:
/// every row shows all four appearance values side by side instead of
/// requiring an appearance toggle.
struct SystemColorsView: View {
    @State private var copiedHex: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                section(title: "Tint colors", entries: SystemColorData.tints)
                section(title: "Gray colors", entries: SystemColorData.grays)
                disclaimer
            }
            .padding(20)
        }
        .navigationTitle("System colors")
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("Color")
                .frame(width: 190, alignment: .leading)
            ForEach(Appearance.allCases) { appearance in
                Text(appearance.displayName)
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(.secondary)
    }

    private func section(title: String, entries: [SystemColorEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
            ForEach(entries) { entry in
                row(entry)
            }
        }
    }

    private func row(_ entry: SystemColorEntry) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(.title3, design: .monospaced))
                Text(entry.swiftUIName)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 190, alignment: .leading)

            ForEach(Appearance.allCases) { appearance in
                chip(hex: entry.set[appearance], appearance: appearance)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private func chip(hex: String, appearance: Appearance) -> some View {
        Button {
            Exporters.copyToClipboard(hex)
            copiedHex = hex
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if copiedHex == hex { copiedHex = nil }
            }
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: hex))
                    .frame(height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                Text(copiedHex == hex ? "Copied" : hex)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(copiedHex == hex ? .green : .secondary)
            }
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: appearance.backgroundHex).opacity(0.001))
            )
        }
        .buttonStyle(.plain)
        .help("Click to copy \(hex)")
    }

    private var disclaimer: some View {
        Text("Reference values from Apple's Human Interface Guidelines. Actual values may change between OS releases, so always use the UIColor or Color API in shipping code rather than hard-coding.")
            .font(.callout)
            .foregroundStyle(.secondary)
    }
}
