import SwiftUI
import LeeoKit

/// TetraTint ▸ Settings… (⌘,) — 피드백 · 리뷰 · 개발자 연락처.
struct TetraTintSettingsView: View {
    @AppStorage(OnboardingState.storageKey) private var hasSeenOnboarding = false

    var body: some View {
        // LeeoSupportSection 의 "피드백 보내기" 는 NavigationLink 라 스택 안에 있어야 열린다.
        NavigationStack {
            Form {
                Section {
                    LeeoSupportSection<TetraTintSpec>()
                    // 앞으로 만들 기능 — 원본은 TetraTintRoadmap.swift
                    NavigationLink(LeeoRoadmapText.entry) { RoadmapScreen() }
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
        .frame(minHeight: 480)
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
