import SwiftUI

/// 아랍어처럼 오른쪽에서 왼쪽으로 읽는 언어를 위한 자리.
enum AppLanguage {
    /// 지금 화면에 나가는 말이 아랍어인가.
    static var isArabic: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("ar") ?? false
    }

    /// 숫자를 찍을 때 쓰는 지역 설정.
    ///
    /// 아랍어에서는 숫자를 0~9 로, 달력을 양력으로 맞춘다. 기기 지역을 그대로 따르면
    /// 개수는 ١٢٣ 으로, 대비 비율 · hex 는 123 으로 나와 한 화면에 섞인다.
    /// 다른 언어는 기기 설정 그대로 둔다.
    static var locale: Locale {
        guard isArabic else { return .current }
        var components = Locale.Components(locale: .current)
        components.languageComponents = Locale.Language.Components(identifier: "ar")
        components.numberingSystem = "latn"
        components.calendar = .gregorian
        return Locale(components: components)
    }

    /// 코드처럼 왼쪽에서 오른쪽으로 읽는 여러 줄 글. 줄마다 LTR 로 감싸(LRI…PDI)
    /// 아랍어 화면에서도 `{` 가 `}` 로 뒤집히거나 기호가 줄 끝으로 옮겨 가지 않는다. 화면에만 쓰고 복사 값은 그대로다.
    static func leftToRightLines(_ text: String) -> String {
        guard isArabic else { return text }
        return text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "\u{2066}\($0)\u{2069}" }
            .joined(separator: "\n")
    }
}

extension Font.Design {
    /// 색 이름 글꼴. 이름은 `brandPrimary` 같은 코드 이름이라 고정폭으로 쓰지만, 아랍어 화면에서는
    /// "لون العمل" 처럼 아랍어 이름도 오고 고정폭 글꼴에는 아랍어 글자가 없어 낱자로 흩어진다.
    static var nameDesign: Font.Design { AppLanguage.isArabic ? .default : .monospaced }
}

extension View {
    /// 아랍어에서는 화면을 오른쪽에서 왼쪽으로 놓고 숫자를 0~9 로 맞춘다 (§`AppLanguage.locale`).
    /// 맥에서 앱 언어만 아랍어로 고르면 창 단추 · 툴바 · 사이드바 자리(AppKit)는 왼쪽부터인데 SwiftUI 화면도
    /// 왼쪽부터 그린다. 그래서 창 틀(분할 보기 · 툴바)은 AppKit 에 맡기고 **그 안 화면**에 방향을 준다 —
    /// 분할 보기째 뒤집으면 툴바 단추가 넘침(») 메뉴로 숨는다. 시트 · 설정 창은 따로 뜬 창이라 거기에도 붙인다.
    /// 시스템 언어가 아랍어면 이미 오른쪽부터라 아무것도 바뀌지 않는다. 다른 언어는 손대지 않는다.
    @ViewBuilder
    func arabicLayout() -> some View {
        if AppLanguage.isArabic {
            arabicNumbers().environment(\.layoutDirection, .rightToLeft)
        } else {
            self
        }
    }

    /// 아랍어에서 숫자를 0~9 로 (방향은 건드리지 않는다).
    @ViewBuilder
    func arabicNumbers() -> some View {
        if AppLanguage.isArabic {
            environment(\.locale, AppLanguage.locale)
        } else {
            self
        }
    }

    /// 코드 · hex 목록처럼 원래 왼쪽에서 오른쪽으로 읽는 내용은 아랍어 화면에서도 그대로 둔다.
    func keepsLeftToRight() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }
}
