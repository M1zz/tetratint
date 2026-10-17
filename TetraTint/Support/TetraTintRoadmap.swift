//
//  TetraTintRoadmap.swift
//  TetraTint
//
//  **앞으로 만들 것**의 원본. 설정 ▸ 앞으로 만들 기능(`LeeoRoadmapView`)이 이 목록을 그대로 보여 준다.
//
//  ⚠️ 개발하다 "이건 다음에" 가 생기면 **여기에 한 줄을 더한다.** 코드의 TODO 주석으로만 남기지 않는다.
//     - 새 항목: `.planned`. 손대기 시작하면 `.building`. 내보내면 `.shipped("1.2.0")`.
//     - id 는 한 번 정하면 바꾸지 않는다(문구는 바꿔도 된다).
//     - 문구는 사용자 말로 쓴다(내부 이름 · 기술 용어 금지). 키는 영어 문장(개발 언어 en),
//       한국어는 `ko.lproj/Localizable.strings` 에 넣는다.
//     - 사용자에게 보일 만한 것만 적는다. 리팩터링 · 시험 · 빌드 설정은 `.sprintcommander/tasks.json` 의 몫이다.
//

import SwiftUI
import LeeoKit

extension TetraTintSpec {
    static var roadmap: [LeeoRoadmapItem] {[
        // MARK: 다음에 만들어요
        .init(id: "a11y.voiceover", status: .planned,
              title: NSLocalizedString("Better VoiceOver support", comment: "Roadmap item: a11y.voiceover"),
              detail: NSLocalizedString("VoiceOver reads every color, button, and value in a sensible order.", comment: "Roadmap item detail: a11y.voiceover")),
        .init(id: "a11y.contrast", status: .planned,
              title: NSLocalizedString("Easier-to-see interface", comment: "Roadmap item: a11y.contrast"),
              detail: NSLocalizedString("Labels and controls stay crisp with Increase Contrast turned on.", comment: "Roadmap item detail: a11y.contrast")),
        .init(id: "a11y.motion", status: .planned,
              title: NSLocalizedString("Reduced motion", comment: "Roadmap item: a11y.motion"),
              detail: NSLocalizedString("With Reduce Motion on, effects like colors flying into your palette get calmer.", comment: "Roadmap item detail: a11y.motion")),
        .init(id: "lang.more", status: .planned,
              title: NSLocalizedString("More languages", comment: "Roadmap item: lang.more"),
              detail: NSLocalizedString("Use TetraTint in more languages, not just English and Korean.", comment: "Roadmap item detail: lang.more")),
        .init(id: "whatsnew", status: .planned,
              title: NSLocalizedString("What’s new", comment: "Roadmap item: whatsnew"),
              detail: NSLocalizedString("After an update, see what’s new the first time you open the app.", comment: "Roadmap item detail: whatsnew")),
        .init(id: "feedback.reply", status: .planned,
              title: NSLocalizedString("Replies to your feedback", comment: "Roadmap item: feedback.reply"),
              detail: NSLocalizedString("Read our replies to your feedback right in the app.", comment: "Roadmap item detail: feedback.reply")),
        .init(id: "widgets", status: .planned,
              title: NSLocalizedString("Desktop widgets", comment: "Roadmap item: widgets"),
              detail: NSLocalizedString("See your palette right on the desktop without opening the app.", comment: "Roadmap item detail: widgets")),
        .init(id: "sync.icloud", status: .planned,
              title: NSLocalizedString("Palettes on all your Macs", comment: "Roadmap item: sync.icloud"),
              detail: NSLocalizedString("Pick up the same palette on your other Macs with iCloud.", comment: "Roadmap item detail: sync.icloud")),
        .init(id: "backup", status: .planned,
              title: NSLocalizedString("Back up and restore palettes", comment: "Roadmap item: backup"),
              detail: NSLocalizedString("Save your palette to a file and load it back anytime.", comment: "Roadmap item detail: backup")),
        .init(id: "data.delete", status: .planned,
              title: NSLocalizedString("Clear the whole palette", comment: "Roadmap item: data.delete"),
              detail: NSLocalizedString("Remove every saved color at once when you want a fresh start.", comment: "Roadmap item detail: data.delete")),
    ]}
}

// MARK: - 화면

/// 설정 ▸ 앞으로 만들 기능. "이런 기능이 있으면 좋겠어요" 는 기능 제안으로 시작하는 피드백 창을 연다.
struct RoadmapScreen: View {
    @State private var showFeedback = false

    var body: some View {
        LeeoRoadmapView<TetraTintSpec>(onSuggest: { showFeedback = true })
            .sheet(isPresented: $showFeedback) {
                NavigationStack {
                    LeeoFeedbackView<TetraTintSpec>(initialType: .feature)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showFeedback = false }
                            }
                        }
                }
                .frame(width: 460, height: 560)
            }
    }
}
