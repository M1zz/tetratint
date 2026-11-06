import SwiftUI
import LeeoKit

/// TetraTint ▸ Settings… (⌘,) — 요금제 · 피드백 · 리뷰 · 개발자 연락처.
struct TetraTintSettingsView: View {
    @AppStorage(OnboardingState.storageKey) private var hasSeenOnboarding = false

    private static let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    // 요금제 (→ PurchaseManager.swift, PaywallView.swift)
    private let purchases = PurchaseManager.shared
    @State private var showingPaywall = false
    /// 페이월을 평생으로 골라 둔 채 여는가 ('평생으로 바꾸기').
    @State private var paywallTerm: PlanTerm = .yearly
    /// 구독을 평생으로 바꾸는 시트 (→ LeeoGraduationOfferView).
    @State private var showingGraduation = false
    @State private var restoreMessage: String?

    var body: some View {
        // LeeoSupportSection 의 "피드백 보내기" 는 NavigationLink 라 스택 안에 있어야 열린다.
        NavigationStack {
            Form {
                planSection

                Section {
                    LeeoSupportSection<TetraTintSpec>()
                    // 앞으로 만들 기능 — 원본은 TetraTintRoadmap.swift
                    NavigationLink(LeeoRoadmapText.entry) { RoadmapScreen() }
                    // 친구에게 소개하기 — App Store ID 가 없으면 그리지 않는다
                    LeeoShareAppLink<TetraTintSpec>()
                    // 개발자 응원하기 — 판매 중인 팁이 있어야 선다
                    LeeoTipJarLink<TetraTintSpec>(tipJar: purchases.tipJar)
                } header: {
                    Text("Support")
                }

                Section {
                    Link(destination: TetraTintSpec.mailURL) {
                        Label("Email the developer", systemImage: "envelope")
                    }
                    .help(TetraTintSpec.developerEmail)
                    Link(destination: TetraTintSpec.instagramURL) {
                        Label("Message on Instagram (@lee25_ios)", systemImage: "camera")
                    }
                } header: {
                    Text("Contact")
                }

                Section {
                    Button {
                        hasSeenOnboarding = false
                    } label: {
                        Label("Show the welcome guide again", systemImage: "sparkles")
                    }
                    .help("Opens the guide in the main window")
                } header: {
                    Text("Help")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 460)
        .frame(minHeight: 560)
        .sheet(isPresented: $showingPaywall) {
            PaywallView(initialTerm: paywallTerm)
        }
        .sheet(isPresented: $showingGraduation) {
            LeeoGraduationOfferView(graduate: purchases.graduateProduct) {
                await purchases.refresh()
            }
        }
    }

    /// 지금 쓰는 칸 · 요금제 보기 · 구독 관리 · 평생으로 바꾸기 · 구매 복원.
    private var planSection: some View {
        Section {
            LabeledContent("Your plan", value: purchases.tier.title)
            if purchases.isEarlyUser {
                Text("You were here before plans existed, so Pro is yours to keep.")
                    .foregroundStyle(.secondary)
            }
            if purchases.tier < .pro {
                Button("See Plans") { openPaywall(.yearly) }
            }
            if purchases.subscription != nil {
                Link(LeeoLadderText.manageSubscription, destination: Self.subscriptionsURL)
            }
            // 평생이 아닌 사람에게 늘 선다. 구독 중이면 졸업가로, 아니면 평생을 골라 둔 요금제로.
            if !purchases.ownsLifetimePro, !purchases.ownsPlusLifetime {
                Button(LeeoLadderText.switchToLifetimeEntry) {
                    if purchases.subscription != nil, purchases.graduateProduct != nil {
                        showingGraduation = true
                    } else {
                        openPaywall(.lifetime)
                    }
                }
            }
            Button("Restore Purchases") {
                Task {
                    restoreMessage = nil
                    await purchases.restore()
                    if purchases.tier == .free { restoreMessage = purchases.failureMessage }
                }
            }
            .disabled(purchases.isWorking)
            if let restoreMessage {
                Text(restoreMessage)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Plan")
        }
    }

    private func openPaywall(_ term: PlanTerm) {
        paywallTerm = term
        showingPaywall = true
    }
}

/// Help 메뉴 끝에 붙는 항목 — 맥 사용자가 도움을 찾으러 가는 자리.
struct TetraTintHelpCommands: Commands {
    @AppStorage(OnboardingState.storageKey) private var hasSeenOnboarding = false
    @Environment(\.openURL) private var openURL

    var body: some Commands {
        CommandGroup(after: .help) {
            Button("Welcome to TetraTint") {
                hasSeenOnboarding = false
            }
            Divider()
            Button("TetraTint Support Page") {
                openURL(TetraTintSpec.legal.supportURL)
            }
            Button("Email the Developer…") {
                openURL(TetraTintSpec.mailURL)
            }
            Button("Message on Instagram (@lee25_ios)") {
                openURL(TetraTintSpec.instagramURL)
            }
        }
    }
}
