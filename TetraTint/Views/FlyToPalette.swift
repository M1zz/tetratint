import SwiftUI

// MARK: - Fly-to-palette animation
//
// When a color is saved from any lens, a small swatch flies from the button
// that triggered it and lands on the Palette item in the sidebar, so the user
// can see *where* the new color went. A count badge on the Palette row backs
// this up for anyone who misses the motion.

/// Drives the flying swatches. One instance lives at the app root and is shared
/// through the environment so any "add" button can launch a flight.
@MainActor
final class FlyOverlayModel: ObservableObject {
    /// Named coordinate space that both the launch points and the landing
    /// point (the Palette sidebar row) are measured in.
    static let spaceName = "flyRoot"

    struct Flight: Identifiable {
        let id = UUID()
        let color: Color
        let start: CGPoint
        let delay: Double
    }

    @Published var flights: [Flight] = []
    /// Center of the Palette sidebar row, in the `flyRoot` space.
    var target: CGPoint = .zero

    func launch(color: Color, from start: CGPoint, delay: Double = 0) {
        // No measured start yet (button never laid out) → skip silently.
        guard start != .zero else { return }
        flights.append(Flight(color: color, start: start, delay: delay))
    }

    func finish(_ id: UUID) {
        flights.removeAll { $0.id == id }
    }
}

/// Reports the Palette sidebar row's center up to the root.
struct PaletteAnchorKey: PreferenceKey {
    static let defaultValue = CGPoint.zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

/// A single swatch animating from its launch point to the Palette row.
struct FlyingSwatch: View {
    let flight: FlyOverlayModel.Flight
    let target: CGPoint
    let onFinish: () -> Void

    @State private var arrived = false
    private let travel = 0.55

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(flight.color)
            .frame(width: 26, height: 26)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            .scaleEffect(arrived ? 0.35 : 1)
            .opacity(arrived ? 0 : 1)
            .position(arrived ? target : flight.start)
            .allowsHitTesting(false)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + flight.delay) {
                    withAnimation(.easeInOut(duration: travel)) { arrived = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + flight.delay + travel + 0.05) {
                    onFinish()
                }
            }
    }
}

/// An "add to palette" button that, on tap, both runs `action` and launches a
/// swatch (or several) flying toward the Palette sidebar row.
struct FlyingAddButton<L: View>: View {
    @EnvironmentObject private var fly: FlyOverlayModel

    /// Colors to send flying. Multiple colors fan out with a slight stagger.
    let colors: [Color]
    let action: () -> Void
    @ViewBuilder var label: () -> L

    @State private var center: CGPoint = .zero

    init(colors: [Color], action: @escaping () -> Void, @ViewBuilder label: @escaping () -> L) {
        self.colors = colors
        self.action = action
        self.label = label
    }

    init(color: Color, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> L) {
        self.init(colors: [color], action: action, label: label)
    }

    var body: some View {
        Button {
            action()
            for (i, c) in colors.prefix(6).enumerated() {
                fly.launch(color: c, from: center, delay: Double(i) * 0.08)
            }
        } label: {
            label()
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { record(proxy) }
                    .onChange(of: proxy.frame(in: .named(FlyOverlayModel.spaceName))) { _ in record(proxy) }
            }
        )
    }

    private func record(_ proxy: GeometryProxy) {
        let f = proxy.frame(in: .named(FlyOverlayModel.spaceName))
        center = CGPoint(x: f.midX, y: f.midY)
    }
}
