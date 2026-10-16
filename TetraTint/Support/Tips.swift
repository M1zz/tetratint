import SwiftUI
import TipKit
import LeeoKit

// MARK: - TipKit 사용 팁
//
// 앱의 강점인데 아이콘 하나로만 보이는 기능을 처음 한 번 짚어 준다.
// 기능을 한 번 쓰면 그 팁은 다시 뜨지 않는다(invalidate).

enum TetraTintTips {
    /// 앱 시작 시 1회. 원격 킬스위치(tipsEnabled)가 꺼져 있으면 팁 시스템을 켜지 않는다 → 팁이 뜨지 않는다.
    static func configure() {
        guard LeeoRemoteFlags.isEnabled(TetraTintFlag.tipsEnabled) else { return }
        try? Tips.configure([.displayFrequency(.immediate)])
    }
}

/// 툴바 스포이드 — 화면 어디서든 색을 집어 작업 색으로.
struct PickFromScreenTip: Tip {
    var title: Text { Text("Pick any color on screen") }
    var message: Text? {
        Text("Click the eyedropper, then click a pixel in any app, website, or design file. It becomes the working color everywhere.")
    }
    var image: Image? { Image(systemName: "eyedropper") }
}

/// 툴바 눈 아이콘 — 앱 전체를 색각이상 시뮬레이션으로.
struct ColorVisionPreviewTip: Tip {
    var title: Text { Text("See the whole app as others do") }
    var message: Text? {
        Text("Turn on a color vision preview to view every screen as someone with protanopia, deuteranopia, or tritanopia sees it.")
    }
    var image: Image? { Image(systemName: "eye") }
}
