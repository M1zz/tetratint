import XCTest

/// 요금제 정책(→ Plan.swift)과 가짜 스토어(→ TetraTint.storekit).
/// 상품 ID 가 Plan 과 글자 하나라도 다르면 페이월은 그 자리를 비운다 — 여기서 먼저 잡는다.
final class PlanTests: XCTestCase {

    func testOwnedProductsOpenTiers() {
        XCTAssertEqual(Plan.tier(owned: []), .free)
        // 팁은 아무것도 열지 않는다.
        XCTAssertEqual(Plan.tier(owned: Set(Plan.tipProductIDs)), .free)
        XCTAssertEqual(Plan.tier(owned: [Plan.plusYearlyID]), .plus)
        XCTAssertEqual(Plan.tier(owned: [Plan.plusLifetimeID]), .plus)
        XCTAssertEqual(Plan.tier(owned: [Plan.plusLifetimeID, Plan.proUpgradeID]), .pro)
        XCTAssertEqual(Plan.tier(owned: [Plan.proGraduateID]), .pro)
        XCTAssertEqual(Plan.tier(owned: [Plan.proWeeklyID]), .pro)
    }

    func testTipsAreNeverEntitlements() {
        let entitlements = Plan.plusEntitlementIDs.union(Plan.proEntitlementIDs)
        XCTAssertTrue(entitlements.isDisjoint(with: Plan.tipProductIDs))
        XCTAssertEqual(entitlements, Set(Plan.saleProductIDs))
    }

    func testFreePaletteHoldsSixColors() {
        XCTAssertTrue(Plan.allowsPalette(existing: 5, adding: 1, tier: .free))
        XCTAssertFalse(Plan.allowsPalette(existing: 6, adding: 1, tier: .free))
        // 안전 팔레트처럼 여러 색을 한 번에 담으면 한도를 넘는 순간 막는다.
        XCTAssertFalse(Plan.allowsPalette(existing: 0, adding: 8, tier: .free))
        XCTAssertTrue(Plan.allowsPalette(existing: 40, adding: 8, tier: .plus))
    }

    func testFeaturesSitInTheirTiers() {
        XCTAssertEqual(PlanFeature.bulkAudit.tier, .plus)
        XCTAssertEqual(PlanFeature.colorVision.tier, .plus)
        XCTAssertEqual(PlanFeature.assetCatalog.tier, .pro)
        XCTAssertEqual(PlanFeature.shortcuts.tier, .pro)
    }

    func testEarlyUsersUpToTheLastFreeVersion() {
        XCTAssertTrue(EarlyUser.isEarly(originalAppVersion: "1.0"))
        XCTAssertTrue(EarlyUser.isEarly(originalAppVersion: "1.0.2"))
        XCTAssertTrue(EarlyUser.isEarly(originalAppVersion: "1.0.3"))
        XCTAssertFalse(EarlyUser.isEarly(originalAppVersion: "1.0.4"))
        XCTAssertFalse(EarlyUser.isEarly(originalAppVersion: "1.1"))
        XCTAssertFalse(EarlyUser.isEarly(originalAppVersion: "1.0.10"))
    }

    // MARK: 가짜 스토어 (TetraTint.storekit)
    //
    // 이 테스트 묶음은 앱을 띄우지 않으므로 StoreKit 세션을 열 수 없다. 대신 설정 파일을 직접 읽어
    // 앱 스킴의 실행(가짜 스토어로 구매 흐름 시험)이 Plan 과 같은 상품을 보는지 확인한다.

    private func storeKitConfig() throws -> [String: Any] {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TetraTint", withExtension: "storekit"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    func testStoreKitConfigMatchesPlan() throws {
        let config = try storeKitConfig()
        let products = try XCTUnwrap(config["products"] as? [[String: Any]])
        let groups = try XCTUnwrap(config["subscriptionGroups"] as? [[String: Any]])
        // 구독 여섯 개는 한 그룹이다.
        XCTAssertEqual(groups.count, 1)
        let subs = try XCTUnwrap(groups.first?["subscriptions"] as? [[String: Any]])

        let lifetimeIDs = Set(products.filter { $0["type"] as? String == "NonConsumable" }.compactMap { $0["productID"] as? String })
        let tipIDs = Set(products.filter { $0["type"] as? String == "Consumable" }.compactMap { $0["productID"] as? String })
        let subIDs = Set(subs.compactMap { $0["productID"] as? String })

        XCTAssertEqual(subIDs, Plan.subscriptionIDs)
        XCTAssertEqual(lifetimeIDs.union(subIDs), Set(Plan.saleProductIDs))
        XCTAssertEqual(tipIDs, Set(Plan.tipProductIDs))

        // Pro 가 위 등급(숫자가 작을수록 위), 연 구독에는 첫 해 할인이 있다.
        for sub in subs {
            let id = try XCTUnwrap(sub["productID"] as? String)
            let level = try XCTUnwrap(sub["groupNumber"] as? Int)
            XCTAssertEqual(level, Plan.proEntitlementIDs.contains(id) ? 1 : 2, id)
            if id == Plan.plusYearlyID || id == Plan.proYearlyID {
                XCTAssertNotNil(sub["introductoryOffer"], id)
            }
        }
    }
}
