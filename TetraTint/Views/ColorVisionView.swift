import SwiftUI

/// "Color vision" lens: how the working color (and any saved palette colors)
/// appear under each color vision deficiency, with conflict detection and
/// safe-palette suggestions.
struct ColorVisionLens: View {
    @EnvironmentObject private var store: PaletteStore
    @EnvironmentObject private var appState: AppState

    /// Colors under inspection: the shared working color first, then any
    /// saved palette colors so conflicts between them can be spotted.
    private var inspected: [(name: String, hex: String)] {
        var result: [(name: String, hex: String)] = [
            (String(localized: "Working color"), appState.set.light)
        ]
        result += store.items.map { ($0.name, $0.set.light) }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            simulationGrid
            conflictSection
            safePaletteSection
        }
    }

    // MARK: Simulation grid

    private func stepHeader(_ number: Int, _ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(verbatim: "\(number)")
                .font(.callout.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.accentColor))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var simulationGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            stepHeader(1, "Color vision simulation",
                       "This shows how your colors look to people with color vision deficiency. It is the current state, not a suggestion to change them.")
                .padding(.bottom, 4)

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("Color")
                        .frame(width: 130, alignment: .leading)
                    ForEach(CVDType.allCases) { type in
                        VStack(spacing: 0) {
                            Text(type.rawValue)
                            Text(type.subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)

                ForEach(inspected, id: \.name) { item in
                    GridRow {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.system(.callout, design: .monospaced))
                            Text(item.hex)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 130, alignment: .leading)

                        ForEach(CVDType.allCases) { type in
                            let simulated = simulatedHex(item.hex, type: type)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: simulated))
                                .frame(height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                                .help("\(type.rawValue): \(simulated)")
                        }
                    }
                }
            }
        }
    }

    private func simulatedHex(_ hex: String, type: CVDType) -> String {
        guard let rgb = RGB(hex: hex) else { return hex }
        return CVDSimulator.simulate(rgb, type: type).hexString
    }

    // MARK: Confusable pairs

    private struct Conflict: Identifiable {
        let id = UUID()
        let type: CVDType
        let a: (name: String, hex: String)
        let b: (name: String, hex: String)
        let deltaE: Double
    }

    private var conflicts: [Conflict] {
        var result: [Conflict] = []
        let items = inspected
        for type in CVDType.allCases where type != .normal {
            for i in items.indices {
                for j in items.indices where j > i {
                    guard
                        let ra = RGB(hex: items[i].hex),
                        let rb = RGB(hex: items[j].hex)
                    else { continue }
                    let sa = CVDSimulator.simulate(ra, type: type)
                    let sb = CVDSimulator.simulate(rb, type: type)
                    let d = LabColor.deltaE(sa, sb)
                    if d < 12 {
                        result.append(Conflict(type: type, a: items[i], b: items[j], deltaE: d))
                    }
                }
            }
        }
        return result.sorted { $0.deltaE < $1.deltaE }
    }

    private var conflictSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            stepHeader(2, "Conflict warnings",
                       "Finds color pairs that become too similar to tell apart under simulation.")
                .padding(.bottom, 4)

            if conflicts.isEmpty {
                Label("All color pairs stay distinguishable across every vision type (ΔE ≥ 12)", systemImage: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)
            } else {
                ForEach(conflicts) { c in
                    HStack(spacing: 10) {
                        Image(systemName: c.deltaE < 6 ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                            .foregroundStyle(c.deltaE < 6 ? .red : .orange)

                        HStack(spacing: 4) {
                            swatchPair(c.a.hex, type: c.type)
                            swatchPair(c.b.hex, type: c.type)
                        }

                        Text("\(c.a.name) ↔ \(c.b.name)")
                            .font(.system(.callout, design: .monospaced))

                        Text("ΔE \(String(format: "%.1f", c.deltaE)) under \(c.type.rawValue)")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Text("Do not rely on color alone. Pair it with icons, patterns, or labels, or switch to a safe palette below.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func swatchPair(_ hex: String, type: CVDType) -> some View {
        let sim = simulatedHex(hex, type: type)
        return RoundedRectangle(cornerRadius: 4)
            .fill(Color(hex: sim))
            .frame(width: 26, height: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }

    // MARK: Safe palettes

    private var safePaletteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepHeader(3, "Recommended safe palettes",
                       "If there were conflicts above, switch to a verified palette that stays distinguishable across every vision type.")
                .padding(.bottom, 4)

            ForEach(SafePalette.all) { palette in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(palette.name)
                            .font(.body.weight(.medium))
                        Text(palette.source)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 160, alignment: .leading)

                    HStack(spacing: 4) {
                        ForEach(palette.hexes, id: \.self) { hex in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 24)
                                .help(hex)
                        }
                    }

                    Spacer()

                    FlyingAddButton(colors: palette.hexes.map { Color(hex: $0) }) {
                        for (index, hex) in palette.hexes.enumerated() {
                            let name = palette.name.replacingOccurrences(of: "–", with: "")
                                .replacingOccurrences(of: " ", with: "") + "\(index + 1)"
                            store.add(name: name, set: VariantDeriver.derive(fromLight: hex))
                        }
                    } label: {
                        Text("Add to palette")
                    }
                    .help("Derive each color into four variants and save to the palette")
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
