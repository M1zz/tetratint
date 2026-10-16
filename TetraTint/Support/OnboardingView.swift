import SwiftUI

enum OnboardingState {
    /// 첫 실행 안내를 본 적이 있는가. 도움말 메뉴 ▸ Welcome to TetraTint 가 false 로 되돌려 다시 띄운다.
    static let storageKey = "hasSeenOnboarding"
}

/// 첫 실행 안내 — 한 가지 색을 여러 렌즈로 본다는 앱의 흐름을 한 장에 보여 준다.
struct TetraTintOnboardingView: View {
    let onFinish: () -> Void

    private struct Step: Identifiable {
        let id: Int
        let icon: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
    }

    private let steps: [Step] = [
        Step(id: 0, icon: "eyedropper",
             title: "Start with one color",
             detail: "Type a hex value, use the color well, or pick any pixel on screen with the eyedropper. Every screen works on this same color."),
        Step(id: 1, icon: "square.grid.2x2.fill",
             title: "Look at it through three lenses",
             detail: "Generate light, dark, and high-contrast variants, check WCAG contrast, and see how it looks with color vision deficiency."),
        Step(id: 2, icon: "square.and.arrow.down.on.square",
             title: "Save and export",
             detail: "Save colors to your palette, then export a .colorset, SwiftUI or UIKit code, or one .xcassets catalog for Xcode."),
        Step(id: 3, icon: "textformat.size",
             title: "Custom fonts too",
             detail: "Dynamic Type shows every text style at every size and writes the scaling code for your custom font."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to TetraTint")
                    .font(.largeTitle.weight(.bold))
                Text("Accessibility work Apple doesn't do for your custom colors and fonts.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 18) {
                ForEach(steps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: step.icon)
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.title)
                                .font(.headline)
                            Text(step.detail)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            HStack {
                Text("You can open this guide again from the Help menu.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Get Started", action: onFinish)
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
        }
        .padding(32)
        .frame(width: 560)
    }
}
