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
    /// 보조 글자. 흰 바탕 위 검정 50% 는 3.9:1 이라 AA(4.5:1) 를 넘도록 60% 로 둔다.
    private var sub: Color { appearance.isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.6) }

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
                    // 색을 못 가리는 사람도 무슨 색인지 글로 안다.
                    Text(hex.colorName)
                        .font(.callout)
                        .foregroundStyle(sub)
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
                .accessibilityLabel(Text("Copy \(hex)"))
                .accessibilityInputLabels([Text("Copy \(hex)"), Text("Copy hex")])
            }

            componentPreview
                .accessibilityHidden(true)
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
        // 등급은 색 말고도 글과 모양으로 구별한다. 글자는 카드의 기본 글자색이라 대비가 충분하다.
        let (label, color, icon): (LocalizedStringKey, Color, String) =
            ratio >= 4.5 ? ("AA text", .green, "checkmark.circle.fill") :
            ratio >= 3.0 ? ("UI 3:1", .orange, "exclamationmark.triangle.fill") :
            ("Low", .red, "xmark.octagon.fill")
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(label)
                .foregroundStyle(fg)
        }
        .font(.callout.weight(.medium))
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(color.opacity(0.18))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }

    // MARK: Mini component preview

    private var componentPreview: some View {
        let tint: Color = Color(hex: hex)
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
