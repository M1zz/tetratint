import SwiftUI

/// One appearance pane. The background is pinned to the appearance it
/// represents (white for light, black for dark) so all four modes are
/// visible simultaneously — something single-appearance preview tools
/// can't show without toggling the whole app.
struct VariantCard: View {
    let appearance: Appearance
    @Binding var hex: String
    var onManualEdit: (() -> Void)?

    private var bg: Color { Color(hex: appearance.backgroundHex) }
    private var cardBg: Color { Color(hex: appearance.secondaryBackgroundHex) }
    private var fg: Color { appearance.isDark ? .white : .black }
    private var sub: Color { appearance.isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.5) }

    private var contrastVsBackground: Double {
        WCAG.contrast(hex: hex, hex: appearance.backgroundHex)
    }

    private var labelOnFill: Color {
        WCAG.contrast(hex: hex, hex: "#FFFFFF") >= 3 ? .white : .black
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(appearance.displayName)
                    .font(.callout)
                    .foregroundStyle(sub)
                Spacer()
                contrastBadge
            }

            HStack(spacing: 10) {
                pickerSwatch

                VStack(alignment: .leading, spacing: 2) {
                    Text(hex)
                        .font(.system(.title3, design: .monospaced).weight(.medium))
                        .foregroundStyle(fg)
                        .textSelection(.enabled)
                    Text("\(String(format: "%.2f", contrastVsBackground)):1 vs background")
                        .font(.callout)
                        .foregroundStyle(sub)
                }

                Spacer()

                Button {
                    Exporters.copyToClipboard(hex)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(sub)
                }
                .buttonStyle(.plain)
                .help("Copy hex")
            }

            componentPreview
        }
        .padding(14)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Swatch + inline fine-tune picker

    private var pickerSwatch: some View {
        ColorPicker(
            "",
            selection: Binding(
                get: { Color(hex: hex) },
                set: { newValue in
                    if let newHex = NSColor(newValue).hexString {
                        hex = newHex
                        onManualEdit?()
                    }
                }
            ),
            supportsOpacity: false
        )
        .labelsHidden()
        .frame(width: 44, height: 32)
        .help("Fine-tune this variant manually")
        .accessibilityLabel(Text("\(appearance.displayName): \(hex.colorName), \(hex)"))
    }

    // MARK: Contrast badge

    private var contrastBadge: some View {
        let ratio = contrastVsBackground
        let (label, color): (LocalizedStringKey, Color) =
            ratio >= 4.5 ? ("AA text", .green) :
            ratio >= 3.0 ? ("UI 3:1", .orange) :
            ("Low", .red)
        return Text(label)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: Mini component preview

    private var componentPreview: some View {
        let tint = Color(hex: hex)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Button")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(tint)
                    .foregroundStyle(labelOnFill)
                    .clipShape(Capsule())

                Text("Tint label")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(tint)

                Image(systemName: "heart.fill")
                    .font(.callout)
                    .foregroundStyle(tint)
            }

            HStack(spacing: 8) {
                Capsule()
                    .fill(tint)
                    .frame(width: 60, height: 4)
                Circle()
                    .fill(tint)
                    .frame(width: 12, height: 12)
                Text("Progress")
                    .font(.callout)
                    .foregroundStyle(sub)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
