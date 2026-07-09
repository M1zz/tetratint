import SwiftUI
import CoreImage

// MARK: - Whole-app color vision preview
//
// Renders the entire UI as someone with a color vision deficiency sees it, so
// a color-blind user can check their own colors in place — and a designer can
// verify any screen. Implemented as a Core Image filter on the window's
// content layer, which reliably covers the whole window live (toolbar, sidebar,
// AppKit color wells, materials) — unlike a SwiftUI shader over a scroll view.

/// Applies (or clears) a CVD color matrix on the host window's content layer.
struct CVDWindowFilter: NSViewRepresentable {
    let type: CVDType

    func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

    func updateNSView(_ nsView: NSView, context: Context) {
        let type = self.type
        // Defer so the view is attached to its window before we reach for it.
        DispatchQueue.main.async {
            guard let content = nsView.window?.contentView else { return }
            content.wantsLayer = true
            content.layerUsesCoreImageFilters = true
            content.layer?.filters = CVDWindowFilter.filters(for: type)
        }
    }

    static func filters(for type: CVDType) -> [CIFilter] {
        switch type {
        case .normal:
            return []
        case .grayscale:
            let luma = CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
            return [colorMatrix(luma, luma, luma)]
        default:
            guard let m = CVDSimulator.matrix(for: type) else { return [] }
            return [colorMatrix(
                CIVector(x: m[0][0], y: m[0][1], z: m[0][2], w: 0),
                CIVector(x: m[1][0], y: m[1][1], z: m[1][2], w: 0),
                CIVector(x: m[2][0], y: m[2][1], z: m[2][2], w: 0)
            )]
        }
    }

    private static func colorMatrix(_ r: CIVector, _ g: CIVector, _ b: CIVector) -> CIFilter {
        let f = CIFilter(name: "CIColorMatrix")!
        f.setValue(r, forKey: "inputRVector")
        f.setValue(g, forKey: "inputGVector")
        f.setValue(b, forKey: "inputBVector")
        f.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        return f
    }
}

// MARK: - Swatch accessibility

extension View {
    /// Give a color swatch a spoken identity: role, color name, hex, and any
    /// extra note (e.g. a contrast verdict). A color-blind or screen-reader
    /// user gets the color's meaning without having to see it.
    func swatchAccessibility(role: String, hex: String, note: String? = nil) -> some View {
        var label = "\(role): \(hex.colorName), \(hex)"
        if let note { label += ", \(note)" }
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(label))
    }
}

// MARK: - "You are viewing a simulation" banner

/// Shown while a preview is active so the on-screen colors aren't mistaken for
/// the real ones.
struct CVDPreviewBanner: View {
    let type: CVDType
    let onExit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
            Text("Color vision preview")
                .fontWeight(.semibold)
            Text(LocalizedStringKey(type.rawValue))
                .foregroundStyle(.secondary)
            Text("simulated colors, not the real ones")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Exit", action: onExit)
                .buttonStyle(.borderless)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
    }
}
