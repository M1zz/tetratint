//
//  Plan.swift
//  TetraTint
//
//  **무료 · Plus · Pro 세 칸의 정책** — 무엇이 어느 칸에 있는지, 어떤 상품이 어느 칸을 여는지.
//  사고 되찾는 일은 PurchaseManager(→ LeeoStore)가 한다. 이 파일은 LeeoKit 없이 시험한다(TetraTintTests).
//
//   · 무료: 색 하나를 네 모드로 만들고 다듬기 · 화면에서 집기, 색 하나씩 대비 · WCAG, 텍스트 복사
//           (hex · SwiftUI · UIKit · Contents.json), Dynamic Type 표 · 미리보기, 시스템 색, 팔레트 6색
//   · Plus: 팔레트 무제한, 대비 일괄 검사, 색각 시뮬레이션 · 헷갈리는 짝, 색각 안전 팔레트
//   · Pro:  Plus 전부 + .colorset 저장, .xcassets 내보내기, Dynamic Type 코드, 단축어 · Spotlight
//
//  ⚠️ 절대 잠그지 않는 것: 이미 담은 팔레트 색을 보고 지우는 일(6색을 넘어도), 텍스트 복사,
//     앱 전체 색각 프리뷰(툴바 눈 아이콘 — 손쉬운 사용), VoiceOver 같은 손쉬운 사용.
//

import Foundation
import StoreKit

/// 세 칸. 위 칸은 아래 칸을 전부 연다.
enum PlanTier: Int, Comparable, CaseIterable {
    case free, plus, pro

    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }

    var title: String {
        switch self {
        case .free: String(localized: "Free", comment: "Plan name: free tier")
        case .plus: "Plus"
        case .pro: "Pro"
        }
    }
}

/// 값을 받는 자리. 막히면 그 기능이 든 칸을 앞세운 페이월이 뜬다.
enum PlanFeature: String, Identifiable, CaseIterable {
    /// 팔레트 7번째 색부터 (무료는 `Plan.freePaletteLimit` 색).
    case unlimitedPalette
    /// 대비 검사에 두 색 이상을 한 번에.
    case bulkAudit
    /// 색각 시뮬레이션 렌즈 · 헷갈리는 짝.
    case colorVision
    /// Okabe Ito · IBM · Paul Tol 팔레트 담기.
    case safePalettes
    /// .colorset 파일 저장.
    case colorSetFiles
    /// 팔레트 전체를 .xcassets 하나로.
    case assetCatalog
    /// Dynamic Type 코드(@ScaledMetric · 레이아웃 전환) 복사.
    case dynamicTypeCode
    /// 단축어 · Spotlight 로 색 집기 · 화면 열기.
    case shortcuts

    var id: String { rawValue }

    var tier: PlanTier {
        switch self {
        case .unlimitedPalette, .bulkAudit, .colorVision, .safePalettes: .plus
        case .colorSetFiles, .assetCatalog, .dynamicTypeCode, .shortcuts: .pro
        }
    }
}

enum Plan {
    /// 무료로 담을 수 있는 팔레트 색 수.
    static let freePaletteLimit = 6

    // MARK: 상품 ID
    //
    // ⚠️ App Store Connect · TetraTint.storekit 과 **글자 하나까지 같아야** 한다.
    // 자동 갱신 구독 여섯 개는 한 구독 그룹("TetraTint Plus · Pro")에 두고 Pro 를 위 등급으로 둔다.

    static let plusWeeklyID = "com.leeo.TetraTint.plus.weekly"
    static let plusMonthlyID = "com.leeo.TetraTint.plus.monthly"
    static let plusYearlyID = "com.leeo.TetraTint.plus.yearly"
    static let plusLifetimeID = "com.leeo.TetraTint.plus"
    static let proWeeklyID = "com.leeo.TetraTint.pro.weekly"
    static let proMonthlyID = "com.leeo.TetraTint.pro.monthly"
    static let proYearlyID = "com.leeo.TetraTint.pro.yearly"
    static let proLifetimeID = "com.leeo.TetraTint.pro"
    /// Plus 평생을 산 사람이 Pro 평생으로 올리는 값.
    static let proUpgradeID = "com.leeo.TetraTint.pro.upgrade"
    /// 구독 졸업: 구독 중인 사람에게만 보이는 Pro 평생.
    static let proGraduateID = "com.leeo.TetraTint.pro.graduate"

    /// 개발자 응원하기. **기능을 열지 않는다** — 권한 목록에 넣지 않는다.
    static let tipProductIDs = ["com.leeo.TetraTint.tip.small",
                                "com.leeo.TetraTint.tip.medium",
                                "com.leeo.TetraTint.tip.large"]

    /// 페이월이 불러올 상품.
    static let saleProductIDs = [plusWeeklyID, plusMonthlyID, plusYearlyID, plusLifetimeID,
                                 proWeeklyID, proMonthlyID, proYearlyID, proLifetimeID,
                                 proUpgradeID, proGraduateID]

    static let plusEntitlementIDs: Set<String> = [plusWeeklyID, plusMonthlyID, plusYearlyID, plusLifetimeID]
    static let proEntitlementIDs: Set<String> = [proWeeklyID, proMonthlyID, proYearlyID, proLifetimeID,
                                                 proUpgradeID, proGraduateID]
    /// 자동 갱신 구독 (졸업 제안의 대상).
    static let subscriptionIDs: Set<String> = [plusWeeklyID, plusMonthlyID, plusYearlyID,
                                               proWeeklyID, proMonthlyID, proYearlyID]
    /// 끝이 없는 Pro.
    static let proLifetimeIDs: Set<String> = [proLifetimeID, proUpgradeID, proGraduateID]

    /// 가진 상품이 여는 칸.
    static func tier(owned: Set<String>) -> PlanTier {
        if !owned.isDisjoint(with: proEntitlementIDs) { return .pro }
        if !owned.isDisjoint(with: plusEntitlementIDs) { return .plus }
        return .free
    }

    /// 팔레트에 `adding` 색을 더 담아도 되는가. 이미 담긴 색은 몇 개든 그대로 둔다.
    static func allowsPalette(existing: Int, adding: Int, tier: PlanTier) -> Bool {
        tier >= PlanFeature.unlimitedPalette.tier || existing + adding <= freePaletteLimit
    }
}

// MARK: - 먼저 쓰던 사람

/// 페이월이 들어오기 전에 받은 사람은 그때까지 무료로 쓰던 것을 잃지 않게 **Pro 평생**을 그대로 쓴다.
enum EarlyUser {
    /// 스토어에 나간 페이월 없는 마지막 버전(1.0.2). 그때까지 받은 사람은 Pro 다.
    /// 페이월이 없던 1.0.3 빌드 5 는 심사에서 반려돼 나가지 않았고, 페이월이 든 첫 판이 1.0.3 이다.
    /// ⚠️ 페이월이 든 버전은 이보다 높아야 한다(1.0.3 이상).
    static let lastVersionBeforePaywall = "1.0.2"

    /// macOS 의 `originalAppVersion` 은 처음 받은 판의 CFBundleShortVersionString 이다.
    /// 샌드박스 · Xcode 는 실제 판을 돌려주지 않으므로 App Store 에서 받은 것만 본다.
    static func isEarly() async -> Bool {
        guard case .verified(let app)? = try? await AppTransaction.shared,
              app.environment == .production else { return false }
        return isEarly(originalAppVersion: app.originalAppVersion)
    }

    static func isEarly(originalAppVersion: String) -> Bool {
        originalAppVersion.compare(lastVersionBeforePaywall, options: .numeric) != .orderedDescending
    }
}
