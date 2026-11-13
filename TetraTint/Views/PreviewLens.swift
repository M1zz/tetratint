import SwiftUI

/// "Preview" lens: the working color on a small mock screen, first as it really
/// is and right below as someone with the chosen color vision sees it, so the
/// two can be compared side by side.
struct PreviewLens: View {
    @EnvironmentObject private var store: PaletteStore
    @EnvironmentObject private var appState: AppState
    /// 가장 흔한 녹색약으로 시작해, 처음부터 차이가 보이게 한다.
    @AppStorage("previewVision") private var vision: CVDType = .deuteranomaly

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Picker("Seen by", selection: $vision) {
                    CVDTypeOptions()
                }
                .pickerStyle(.menu)
                .fixedSize()
                Text(vision.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            row("Original", vision: .normal)
            if vision != .normal {
                row(LocalizedStringKey(vision.rawValue), vision: vision)
            }
        }
    }

    private func row(_ title: LocalizedStringKey, vision: CVDType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 12) {
                ForEach([Appearance.light, .dark]) { appearance in
                    PreviewScreen(appearance: appearance,
                                  tint: appState.set[appearance],
                                  palette: store.items.prefix(5).map { $0.set[appearance] },
                                  vision: vision)
                }
            }
        }
    }
}

/// One mock app screen in one appearance, drawn through a vision simulation.
private struct PreviewScreen: View {
    let appearance: Appearance
    let tint: String
    let palette: [String]
    let vision: CVDType

    private func seen(_ hex: String) -> String {
        guard let rgb = RGB(hex: hex) else { return hex }
        return CVDSimulator.simulate(rgb, type: vision).hexString
    }

    private var tintSeen: String { seen(tint) }
    private var tintColor: Color { Color(hex: tintSeen) }
    private var labelOnFill: Color { WCAG.contrast(hex: tintSeen, hex: "#FFFFFF") >= 3 ? .white : .black }
    private var sub: Color { appearance.isDark ? .white.opacity(0.6) : .black.opacity(0.6) }
    private var track: Color { Color(hex: appearance.secondaryBackgroundHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appearance.shortLabel)
                .font(.callout)
                .foregroundStyle(sub)

            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                Text("Tint label")
                    .fontWeight(.medium)
                Spacer()
                Capsule()
                    .fill(tintColor)
                    .frame(width: 38, height: 22)
                    .overlay(alignment: .trailing) {
                        Circle().fill(.white).padding(2)
                    }
            }
            .foregroundStyle(tintColor)

            Text("Button")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(tintColor, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(labelOnFill)

            Capsule()
                .fill(track)
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule().fill(tintColor).frame(width: proxy.size.width * 0.6)
                    }
                }

            if !palette.isEmpty {
                chart
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: appearance.backgroundHex))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(appearance.shortLabel): \(tintSeen.colorName), \(tintSeen)"))
    }

    /// The working color next to saved palette colors, the way a chart would
    /// use them, so colors that run together are easy to spot.
    private var chart: some View {
        let bars = [tint] + palette
        let heights: [CGFloat] = [0.55, 0.9, 0.7, 1.0, 0.45, 0.8]
        return VStack(alignment: .leading, spacing: 6) {
            Text("Palette")
                .font(.callout)
                .foregroundStyle(sub)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(bars.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: seen(bars[i])))
                        .frame(height: 56 * heights[i % heights.count])
                }
            }
            .frame(height: 56, alignment: .bottom)
        }
    }
}
