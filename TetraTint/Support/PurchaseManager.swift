//
//  PurchaseManager.swift
//  TetraTint
//
//  Plus · Pro 를 사고 되찾는 자리. **속은 전부 `LeeoStore`다** (상품 로드 · 구매 · 복원 · 거래 리스너).
//  여기 남은 것은 그 값을 `Plan` 의 정책에 통과시키는 일뿐이다. 화면은 `tier` 와 `allows(_:)` 만 본다.
//

import Foundation
import Combine
import StoreKit
import SwiftUI
import LeeoKit

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    @ObservationIgnored let store: LeeoStore
    /// 개발자 응원하기(팁). 기능을 열지 않는다 — 결제 갱신은 `store` 의 리스너가 이리로 넘긴다.
    @ObservationIgnored let tipJar: LeeoTipJar

    /// 지금 쓰는 칸.
    private(set) var tier: PlanTier = .free
    /// 페이월에 설 상품. App Store 에서 불러온 것만 있다.
    private(set) var products: [Product] = []
    /// 이 Apple 계정이 가진 상품.
    private(set) var ownedIDs: Set<String> = []
    /// 페이월 전부터 쓰던 사람이라 Pro 인가.
    private(set) var isEarlyUser = false
    /// 지금 살아 있는 구독. 있으면 졸업가를 권할 수 있다.
    private(set) var subscription: LeeoGraduation.Subscription?
    private(set) var isWorking = false
    /// 사다가 막혔을 때 그대로 보여 줄 말.
    private(set) var failureMessage: String?
    /// 이 기기가 한 번이라도 상품을 불러왔는가 (→ `isSelling`).
    private var hasEverSold = UserDefaults.standard.bool(forKey: PurchaseManager.everSoldKey)

    @ObservationIgnored private var observation: AnyCancellable?
    private static let everSoldKey = "tetratint.plan.everSold"

    private init() {
        guard let config = TetraTintSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. TetraTintSpec.monetization 을 확인할 것")
        }
        let store = LeeoStore(config: config, grandfather: { await EarlyUser.isEarly() })
        guard let tipJar = store.tipJar else {
            preconditionFailure("계약에 팁이 없다. TetraTintSpec.monetization 을 확인할 것")
        }
        self.store = store
        self.tipJar = tipJar
        // objectWillChange 는 값이 바뀌기 **직전**에 온다. 다음 차례에 읽는다.
        observation = store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.pull() }
        }
        pull()
    }

    /// **팔고 있는가.** 상품을 App Store Connect 에 만들기 전에 빌드가 나가도 살 수 없는 사람을 막지 않는다.
    /// 한 번이라도 상품을 불러온 기기는 잠깐 인터넷이 끊겨도 판매 중으로 본다.
    var isSelling: Bool { hasEverSold || !products.isEmpty }

    /// 이 기능을 지금 써도 되는가.
    func allows(_ feature: PlanFeature) -> Bool { !isSelling || tier >= feature.tier }

    /// 막혀 있으면 그 기능을, 열려 있으면 nil. 단추가 페이월을 띄울지 정한다.
    func lock(_ feature: PlanFeature) -> PlanFeature? { allows(feature) ? nil : feature }

    /// 팔레트에 `adding` 색을 더 담는 길이 막혀 있으면 `.unlimitedPalette`.
    func paletteLock(existing: Int, adding: Int = 1) -> PlanFeature? {
        !isSelling || Plan.allowsPalette(existing: existing, adding: adding, tier: tier) ? nil : .unlimitedPalette
    }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    /// Plus 평생을 가졌는가. 그러면 Pro 평생 자리에 올리기 상품이 선다.
    var ownsPlusLifetime: Bool { ownedIDs.contains(Plan.plusLifetimeID) }
    /// 끝이 없는 Pro 를 가졌는가. 졸업 · 평생으로 바꾸기를 권하지 않는다.
    var ownsLifetimePro: Bool { isEarlyUser || !ownedIDs.isDisjoint(with: Plan.proLifetimeIDs) }

    // MARK: 상태 맞추기

    /// 영수증을 다시 읽고 상품을 불러온다. 앱을 열 때 부른다.
    func refresh() async {
        await store.refreshEntitlements()
        await store.loadProducts()
        subscription = await LeeoGraduation.currentSubscription(among: Plan.subscriptionIDs)
        pull()
    }

    /// 페이월이 상품을 못 불러왔을 때 다시 청한다.
    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    // MARK: 사기 / 되찾기

    /// ⚠️ `action` 은 화면의 `@Environment(\.purchase)` 다. 결제 시트가 그 창에 뜬다.
    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        subscription = await LeeoGraduation.currentSubscription(among: Plan.subscriptionIDs)
        pull()
    }

    func restore() async {
        await store.restore()
        subscription = await LeeoGraduation.currentSubscription(among: Plan.subscriptionIDs)
        pull()
        if tier == .free, failureMessage == nil {
            failureMessage = String(localized: "No purchases were found for this Apple Account.",
                                    comment: "Restore purchases: nothing found")
        }
    }

    // MARK: 구독 졸업

    var graduateProduct: Product? { product(Plan.proGraduateID) }

    /// 지금 졸업가를 한 번 보일 때인가 (구독 6개월째 · 갱신 7일 전). 보이기로 했으면 표시를 남긴다.
    func takeGraduationOffer(now: Date = Date()) -> Bool {
        guard let subscription, graduateProduct != nil, !ownsLifetimePro,
              LeeoGraduation.isDue(subscription, now: now, lastOffered: LeeoGraduation.lastOffered())
        else { return false }
        LeeoGraduation.markOffered(now)
        return true
    }

    // MARK: -

    private func pull() {
        isEarlyUser = store.isGrandfathered
        tier = isEarlyUser ? .pro : Plan.tier(owned: store.purchasedProductIDs)
        ownedIDs = store.purchasedProductIDs
        products = store.products
        if !products.isEmpty, !hasEverSold {
            hasEverSold = true
            UserDefaults.standard.set(true, forKey: Self.everSoldKey)
        }
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
    }
}
