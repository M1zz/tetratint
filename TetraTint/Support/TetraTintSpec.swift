import Foundation
import LeeoKit

/// LeeoKit 계약 — 피드백·리뷰 요청·익명 사용 통계·원격 킬스위치가 이 값으로 묶인다.
enum TetraTintSpec: LeeoAppSpec {
    /// 식별 이름. 피드백·사용 기록이 이 값으로 묶이므로 언어마다 바꾸지 않는다.
    static let appName = "TetraTint"
    static let developerEmail = "leeo@kakao.com"
    /// 여러 앱이 함께 쓰는 피드백 허브. 앱은 appIdentifier 로 구분된다.
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
                                             appIdentifier: "com.leeo.TetraTint")
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/tetratint/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/tetratint/support.html")!)
    static let monetization = LeeoMonetization.free
    /// 개발자 응원하기(팁, 소모성 세 가지 — 작은 것부터). 기능을 열지 않는다.
    /// 무료 앱이라 LeeoStore 가 없다 — 앱이 뜰 때 `startStandalone()` 으로 혼자 선다.
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.leeo.TetraTint.tip.small",
        "com.leeo.TetraTint.tip.medium",
        "com.leeo.TetraTint.tip.large"
    ]))
    /// Mac App Store 의 TetraTint. 설정의 "리뷰 남기기" 가 작성 페이지로 바로 간다.
    static let appStoreID: String? = "6789206198"
    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: TetraTintSpec.self)

    /// 개발자에게 바로 연락하는 길 (도움말 메뉴 · 설정).
    static let instagramURL = URL(string: "https://instagram.com/lee25_ios")!
    static var mailURL: URL {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = developerEmail
        c.queryItems = [URLQueryItem(name: "subject", value: "TetraTint Support")]
        return c.url ?? URL(string: "mailto:leeo@kakao.com")!
    }
}

/// 원격 킬스위치 — LeeoRemoteFlags 가 CloudKit RemoteFlags 레코드에서 읽는다.
///
/// ⚠️ rawValue = CloudKit 필드명 계약이다. 바꾸면 아무리 꺼도 켜진 채로 돈다. 변경 금지.
/// ⚠️ 조회 실패 = 켬(가용성 우선). 갱신은 6시간 쓰로틀이라 즉시 전파되지 않는다.
///
/// CloudKit Dashboard(iCloud.com.Ysoup.FeedbackHub): 레코드 타입 RemoteFlags,
/// recordName "flags_com.leeo.TetraTint", 각 플래그를 Int64(1=켬/0=끔) 필드로. 필드가 없으면 켬.
enum TetraTintFlag: String, LeeoRemoteFlag, CaseIterable {
    /// "즐겁게 쓰고 계신가요?" 만족도 질문 → 리뷰 요청. 거슬린다는 신고가 오면 끈다.
    case satisfactionPromptEnabled
    /// TipKit 사용 팁 풍선. 팁이 화면을 가리거나 잘못 뜨면 끈다(다음 실행부터).
    case tipsEnabled
}
