import SwiftUI

/// Paste every color already used in an app and get a triage verdict:
/// which colors are fine as-is, which need a High Contrast variant to
/// pass the Accessibility Nutrition Label's Sufficient Contrast bar,
/// and which should not carry text at all.
/// "Contrast" lens: the working color's WCAG verdict, plus a bulk tool to
/// audit a whole pasted palette.
struct ContrastLens: View {
    @EnvironmentObject private var store: PaletteStore
    @EnvironmentObject private var appState: AppState

    @State private var input: String = "#007AFF\n#8E8E93\n#FFCC00\n#34C759"
    @State private var results: [AuditResult] = []

    struct AuditResult: Identifiable {
        let id = UUID()
        let hex: String
        let contrastOnWhite: Double
        let contrastOnBlack: Double

        enum Verdict {
            case passes            // 4.5:1 on its background already
            case needsHCVariant    // 3.0–4.5, fine for UI but text needs an HC variant
            case decorativeOnly    // below 3.0, avoid for text and key UI

            var label: String {
                switch self {
                case .passes: return String(localized: "Use as is")
                case .needsHCVariant: return String(localized: "Needs high contrast")
                case .decorativeOnly: return String(localized: "Decorative only")
                }
            }

            var detail: String {
                switch self {
                case .passes: return String(localized: "Meets 4.5:1 for text")
                case .needsHCVariant: return String(localized: "Passes 3:1 for UI; text or High Contrast needs a variant")
                case .decorativeOnly: return String(localized: "Below 3:1; do not use for text, icons, or status")
                }
            }

            var color: Color {
                switch self {
                case .passes: return .green
                case .needsHCVariant: return .orange
                case .decorativeOnly: return .red
                }
            }

            var icon: String {
                switch self {
                case .passes: return "checkmark.circle.fill"
                case .needsHCVariant: return "wand.and.stars"
                case .decorativeOnly: return "nosign"
                }
            }
        }

        var lightVerdict: Verdict { verdict(for: contrastOnWhite) }
        var darkVerdict: Verdict { verdict(for: contrastOnBlack) }

        private func verdict(for ratio: Double) -> Verdict {
            if ratio >= 4.5 { return .passes }
            if ratio >= 3.0 { return .needsHCVariant }
            return .decorativeOnly
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            workingColorSection
            Divider()
            inputSection
            if !results.isEmpty {
                resultsSection
            }
        }
    }

    // MARK: Working color

    /// The shared working color, audited live so this screen is a lens on it.
    private var workingColorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Working color")
                .font(.title3.weight(.semibold))
            row(auditResult(for: appState.set.light))
        }
    }

    private func auditResult(for hex: String) -> AuditResult {
        let normalized = RGB(hex: hex)?.hexString ?? hex
        return AuditResult(
            hex: normalized,
            contrastOnWhite: WCAG.contrast(hex: normalized, hex: "#FFFFFF"),
            contrastOnBlack: WCAG.contrast(hex: normalized, hex: "#000000")
        )
    }

    // MARK: Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste the colors your app uses (separated by line breaks or commas)")
                .font(.title3.weight(.semibold))

            TextEditor(text: $input)
                .font(.system(.title3, design: .monospaced))
                .frame(height: 110)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )

            livePreview

            HStack {
                Button {
                    runAudit()
                } label: {
                    Label("Audit", systemImage: "checklist")
                }
                .keyboardShortcut(.return, modifiers: [.command])

                Text("Screens each color against light (vs white) and dark (vs black) backgrounds using WCAG thresholds.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Live preview — shows each pasted color instantly, before auditing

    private struct ParsedSwatch: Identifiable {
        let id = UUID()
        let token: String
        let hex: String?      // nil when the token isn't a valid color
        var valid: Bool { hex != nil }
    }

    private var parsedSwatches: [ParsedSwatch] {
        input
            .components(separatedBy: CharacterSet(charactersIn: "\n,; \t"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { token in
                ParsedSwatch(token: token, hex: RGB(hex: token)?.hexString)
            }
    }

    @ViewBuilder
    private var livePreview: some View {
        let swatches = parsedSwatches
        if !swatches.isEmpty {
            let invalid = swatches.filter { !$0.valid }.count
            VStack(alignment: .leading, spacing: 6) {
                Text(invalid == 0
                     ? "Preview: \(swatches.count) colors"
                     : "Preview: \(swatches.count) colors, \(invalid) unrecognized")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 108), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(swatches) { swatchChip($0) }
                }
            }
        }
    }

    private func swatchChip(_ s: ParsedSwatch) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(s.valid ? Color(hex: s.hex!) : Color.gray.opacity(0.15))
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                )
                .overlay {
                    if !s.valid {
                        Image(systemName: "questionmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }

            Text(s.valid ? s.hex! : s.token)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(s.valid ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func runAudit() {
        let tokens = input
            .components(separatedBy: CharacterSet(charactersIn: "\n,; \t"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        results = tokens.compactMap { token in
            guard let rgb = RGB(hex: token) else { return nil }
            let hex = rgb.hexString
            return AuditResult(
                hex: hex,
                contrastOnWhite: WCAG.contrast(hex: hex, hex: "#FFFFFF"),
                contrastOnBlack: WCAG.contrast(hex: hex, hex: "#000000")
            )
        }
    }

    // MARK: Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let needsWork = results.filter {
                $0.lightVerdict != .passes || $0.darkVerdict != .passes
            }.count
            Text("\(needsWork) of \(results.count) colors need a high-contrast variant")
                .font(.title3.weight(.semibold))

            ForEach(results) { result in
                row(result)
            }
        }
    }

    private func row(_ result: AuditResult) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: result.hex))
                    .frame(width: 56, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    )

                Text(result.hex)
                    .font(.system(.callout, design: .monospaced))
            }
            .frame(width: 88)
            .swatchAccessibility(
                role: String(localized: "Color"),
                hex: result.hex,
                note: "\(result.lightVerdict.label), \(result.darkVerdict.label)"
            )

            VStack(alignment: .leading, spacing: 8) {
                verdictCell(
                    title: String(localized: "Light"),
                    ratio: result.contrastOnWhite,
                    verdict: result.lightVerdict
                )

                verdictCell(
                    title: String(localized: "Dark"),
                    ratio: result.contrastOnBlack,
                    verdict: result.darkVerdict
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if result.lightVerdict != .passes || result.darkVerdict != .passes {
                FlyingAddButton(color: Color(hex: result.hex)) {
                    store.add(
                        name: "audited\(result.hex.dropFirst())",
                        set: VariantDeriver.derive(fromLight: result.hex)
                    )
                } label: {
                    Label("Derive four variants", systemImage: "wand.and.stars")
                }
                .help("Derive four variants including high contrast and save to the palette")
                .fixedSize()
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func verdictCell(title: String, ratio: Double, verdict: AuditResult.Verdict) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: verdict.icon)
                .foregroundStyle(verdict.color)
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "\(title)  \(String(format: "%.2f", ratio)):1  \(verdict.label)")
                    .font(.callout.weight(.medium))
                Text(verdict.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
