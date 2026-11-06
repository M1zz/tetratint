//
//  PaywallView.swift
//  TetraTint
//
//  **무료 · Plus · Pro 세 칸과 비교표를 한 장에** (→ Plan.swift, PurchaseManager.swift).
//
//  무료 칸을 먼저 세운다. 색 하나를 네 모드로 만들고 대비를 확인해 코드를 복사하는 데는 값을 받지 않는다.
//  유료 칸마다 연 구독(기본) · 평생을 고르고, 주 · 월 구독은 펼쳐서 고른다.
//  ⚠️ App Store 에서 불러온 상품만 단추로 선다. 아직 없는 상품은 자리를 비운다.
//  ⚠️ 구독을 파는 화면이라 심사가 보는 것: 가격과 기간, 첫 해 할인 뒤 값, 자동 갱신과 해지,
//     이용약관 · 개인정보 처리방침, 구매 복원. 하나라도 빠지면 돌아온다.
//

import SwiftUI
import StoreKit
import LeeoKit

/// 유료 칸을 사는 길.
enum PlanTerm: CaseIterable {
    case weekly, monthly, yearly, lifetime
}

struct PaywallView: View {
    /// 어느 문 앞에서 열렸는가. 그 기능이 든 칸과 비교표의 줄을 강조한다.
    var highlight: PlanFeature?
    /// 처음 고를 길. 설정의 '평생으로 바꾸기' 는 평생으로 연다.
    var initialTerm: PlanTerm = .yearly

    private let purchases = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 이 페이월이 떠 있는 창에 띄운다.
    @Environment(\.purchase) private var purchaseAction

    @State private var plusTerm: PlanTerm = .yearly
    @State private var proTerm: PlanTerm = .yearly
    /// 주 · 월 구독을 펼쳤는가.
    @State private var showsShortTerms = false
    /// 첫 해 할인을 받을 수 있는 구독. 이미 한 번 받은 사람에게 할인가를 말하면 거짓말이다.
    @State private var introEligible: Set<String> = []
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let highlight { reasonBanner(highlight) }
                    plansStatus
                    HStack(alignment: .top, spacing: 12) {
                        freeCard
                        paidCard(.plus)
                        paidCard(.pro)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    ComparisonTable(highlight: highlight)
                    if let message = purchases.failureMessage, !purchases.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.body)
                            .foregroundStyle(.orange)
                    }
                    legal
                }
                .padding(24)
            }
            Divider()
            HStack {
                Button(LeeoLadderText.later) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Restore Purchases") { Task { await purchases.restore() } }
                    .disabled(purchases.isWorking)
            }
            .padding(16)
        }
        .frame(width: 880, height: 700)
        .task {
            LeeoAnalyticsCenter.track(.paywallShown(reason: highlight?.rawValue ?? "settings"))
            plusTerm = initialTerm
            proTerm = initialTerm
            if initialTerm == .weekly || initialTerm == .monthly { showsShortTerms = true }
            await loadPlans()
        }
        .onChange(of: purchases.products.map(\.id)) { _, _ in
            Task { await loadIntroEligibility() }
        }
        // 사거나 되찾아서 칸이 올라갔으면 이 화면은 할 일을 다 했다.
        .onChange(of: purchases.tier) { old, new in
            if new > old, new >= (highlight?.tier ?? .plus) { dismiss() }
        }
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TetraTint Plus and Pro")
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
            Text("Audit your whole palette and send it straight to Xcode. Go yearly or lifetime.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    /// 방금 부딪힌 자리를 한 줄로.
    private func reasonBanner(_ feature: PlanFeature) -> some View {
        Label {
            Text(verbatim: "\(feature.title) · \(Self.included(in: feature.tier))")
                .font(.body.weight(.semibold))
        } icon: {
            Image(systemName: "lock.open")
                .accessibilityHidden(true)
        }
        .foregroundStyle(.tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: 칸

    private var freeCard: some View {
        card(.free, tagline: "Make one color in four modes and check its contrast.") {
            EmptyView()
        }
    }

    private func paidCard(_ tier: PlanTier) -> some View {
        let tagline: LocalizedStringKey = tier == .plus
            ? "Check your whole palette in one go."
            : "Send files straight to Xcode, and start from Shortcuts."
        return card(tier, tagline: tagline) {
            purchaseArea(tier)
        }
    }

    private func card<Footer: View>(_ tier: PlanTier, tagline: LocalizedStringKey,
                                    @ViewBuilder footer: () -> Footer) -> some View {
        let current = purchases.tier == tier
        let included = purchases.tier > tier && tier != .free
        let emphasized = highlight.map { $0.tier == tier } ?? (tier == .pro)
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(tier.title)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                if tier == .pro, !current {
                    Text("Recommended")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .background(Color.accentColor, in: Capsule())
                }
            }
            Text(tagline)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if current {
                Label("Current plan", systemImage: "checkmark.seal.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            } else if included {
                Label(Self.included(in: .pro), systemImage: "checkmark")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                footer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            shape.fill(emphasized ? Color.accentColor.opacity(0.06) : Color.primary.opacity(0.03))
            shape.strokeBorder(emphasized || current ? Color.accentColor : Color.primary.opacity(0.08),
                               lineWidth: emphasized || current ? 1.5 : 1)
        }
    }

    /// "Included in Pro".
    private static func included(in tier: PlanTier) -> String {
        String(localized: "Included in \(tier.title)", comment: "Paywall: a feature or plan comes with this plan. %@ = plan name")
    }

    // MARK: 고르고 사기

    private func term(_ tier: PlanTier) -> Binding<PlanTerm> {
        tier == .plus ? $plusTerm : $proTerm
    }

    /// 그 칸의 그 길. 불러오지 못했으면 nil.
    /// **Plus 평생을 가진 사람에게는 Pro 평생 자리에 올리기 상품을 세운다** — 같은 것을 두 번 다 내고 사게 두지 않는다.
    private func product(_ tier: PlanTier, _ term: PlanTerm) -> Product? {
        let id: String = switch (tier, term) {
        case (.plus, .weekly): Plan.plusWeeklyID
        case (.plus, .monthly): Plan.plusMonthlyID
        case (.plus, .yearly): Plan.plusYearlyID
        case (.plus, .lifetime): Plan.plusLifetimeID
        case (_, .weekly): Plan.proWeeklyID
        case (_, .monthly): Plan.proMonthlyID
        case (_, .yearly): Plan.proYearlyID
        case (_, .lifetime): purchases.ownsPlusLifetime ? Plan.proUpgradeID : Plan.proLifetimeID
        }
        return purchases.product(id)
    }

    @ViewBuilder
    private func purchaseArea(_ tier: PlanTier) -> some View {
        let shown: [PlanTerm] = showsShortTerms ? PlanTerm.allCases : [.yearly, .lifetime]
        let available = shown.filter { product(tier, $0) != nil }
        if !available.isEmpty {
            let chosenTerm = available.contains(term(tier).wrappedValue) ? term(tier).wrappedValue : available[0]
            let chosen = product(tier, chosenTerm)
            VStack(alignment: .leading, spacing: 8) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    ForEach(available, id: \.self) { option in
                        termButton(tier, option, selected: option == chosenTerm)
                    }
                }
                if let note = note(tier, chosenTerm) {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !showsShortTerms, product(tier, .weekly) != nil || product(tier, .monthly) != nil {
                    Button("Show weekly and monthly plans") { showsShortTerms = true }
                        .buttonStyle(.link)
                        .font(.body)
                }
                Button {
                    guard let chosen else { return }
                    Task { await purchases.purchase(chosen, using: purchaseAction) }
                } label: {
                    Group {
                        if purchases.isWorking {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(buyTitle(chosen))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(purchases.isWorking || chosen == nil)
            }
        }
    }

    private func termButton(_ tier: PlanTier, _ option: PlanTerm, selected: Bool) -> some View {
        let price = product(tier, option)?.displayPrice ?? ""
        let (title, priceText): (String, String) = switch option {
        case .weekly: (String(localized: "Weekly", comment: "Plan term: weekly subscription"),
                       String(localized: "\(price) / week", comment: "Weekly price. %@ = price"))
        case .monthly: (String(localized: "Monthly", comment: "Plan term: monthly subscription"),
                        String(localized: "\(price) / month", comment: "Monthly price. %@ = price"))
        case .yearly: (LeeoLadderText.yearly, String(format: LeeoLadderText.perYearFormat, price))
        case .lifetime: (LeeoLadderText.lifetime, price)
        }
        return Button {
            term(tier).wrappedValue = option
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(priceText).font(.body.monospacedDigit())
            }
            .foregroundStyle(selected ? Color.accentColor : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05))
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: "\(title), \(priceText)"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// 고른 길 아래 한 줄: 첫 해 할인, 평생이 연 구독 몇 년치인지, 올리기 값.
    private func note(_ tier: PlanTier, _ term: PlanTerm) -> String? {
        switch term {
        case .yearly:
            guard let product = product(tier, .yearly), introEligible.contains(product.id),
                  let offer = product.subscription?.introductoryOffer else { return nil }
            return String(format: LeeoLadderText.introFormat, offer.displayPrice)
        case .lifetime:
            if tier == .pro, purchases.ownsPlusLifetime {
                return String(localized: "You own Plus Lifetime, so you pay only the difference.",
                              comment: "Paywall: Plus lifetime owners pay only the upgrade price for Pro lifetime")
            }
            guard let yearly = product(tier, .yearly)?.price, let lifetime = product(tier, .lifetime)?.price,
                  yearly > 0 else { return nil }
            let years = Int(NSDecimalNumber(decimal: lifetime / yearly).doubleValue.rounded(.down))
            return years >= 2 ? String(format: LeeoLadderText.lifetimeWorthFormat, years) : nil
        case .weekly, .monthly:
            return nil
        }
    }

    /// "Pay $7.99". 첫 해 할인을 받을 수 있으면 실제로 나갈 할인가를 적는다.
    private func buyTitle(_ product: Product?) -> String {
        guard let product else { return "" }
        var price = product.displayPrice
        if introEligible.contains(product.id), let offer = product.subscription?.introductoryOffer {
            price = offer.displayPrice
        }
        return String(localized: "Pay \(price)", comment: "Paywall buy button. %@ = price")
    }

    // MARK: 불러오기

    @ViewBuilder
    private var plansStatus: some View {
        if purchases.products.isEmpty {
            if loading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading plans…")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    Text("Couldn't load plans. Check your internet connection and try again.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        Task { await loadPlans() }
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }

    /// 요금제를 불러온다. 샌드박스는 첫 조회가 빈손으로 돌아오는 일이 잦아 한 번 더 청한다.
    private func loadPlans() async {
        loading = true
        await purchases.loadProducts()
        if purchases.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await purchases.loadProducts()
        }
        await loadIntroEligibility()
        loading = false
    }

    private func loadIntroEligibility() async {
        var eligible: Set<String> = []
        for product in purchases.products {
            if let sub = product.subscription, sub.introductoryOffer != nil, await sub.isEligibleForIntroOffer {
                eligible.insert(product.id)
            }
        }
        introEligible = eligible
    }

    // MARK: 약관

    private var legal: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscriptions renew automatically at the same price unless canceled at least 24 hours before the period ends, and are charged to your Apple Account. New subscribers get the first year of a yearly plan at a discount once; after that it renews at the regular price. Manage or cancel anytime in your App Store account settings. Lifetime is a one-time payment and never renews.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                if let terms = TetraTintSpec.monetization.subscriptionTermsURL {
                    Button("Terms of Use") { openURL(terms) }
                }
                Button("Privacy Policy") { openURL(TetraTintSpec.legal.privacyURL) }
            }
            .buttonStyle(.link)
            .font(.body)
        }
    }
}

// MARK: - 비교표

/// 칸마다 무엇이 열리는지. 방금 부딪힌 기능의 줄을 강조한다.
private struct ComparisonTable: View {
    let highlight: PlanFeature?

    private enum Cell {
        case text(String), included, excluded
    }

    private struct Row: Identifiable {
        let title: String
        let cells: [Cell]   // 무료 · Plus · Pro
        var feature: PlanFeature?
        var id: String { title }
    }

    private var rows: [Row] {
        let unlimited = String(localized: "Unlimited", comment: "Comparison table: no limit")
        let everyone: [Cell] = [.included, .included, .included]
        let plus: [Cell] = [.excluded, .included, .included]
        let pro: [Cell] = [.excluded, .excluded, .included]
        return [
            Row(title: String(localized: "Four mode variants", comment: "Comparison table row"), cells: everyone),
            Row(title: String(localized: "Contrast and WCAG for one color", comment: "Comparison table row"), cells: everyone),
            Row(title: String(localized: "Copy hex and code as text", comment: "Comparison table row"), cells: everyone),
            Row(title: String(localized: "Dynamic Type table and preview", comment: "Comparison table row"), cells: everyone),
            Row(title: String(localized: "System colors reference", comment: "Comparison table row"), cells: everyone),
            Row(title: String(localized: "Palette"),
                cells: [.text(String(localized: "\(Plan.freePaletteLimit) colors", comment: "Comparison table: free palette size")),
                        .text(unlimited), .text(unlimited)],
                feature: .unlimitedPalette),
            Row(title: PlanFeature.bulkAudit.title, cells: plus, feature: .bulkAudit),
            Row(title: PlanFeature.colorVision.title, cells: plus, feature: .colorVision),
            Row(title: PlanFeature.safePalettes.title, cells: plus, feature: .safePalettes),
            Row(title: PlanFeature.colorSetFiles.title, cells: pro, feature: .colorSetFiles),
            Row(title: PlanFeature.assetCatalog.title, cells: pro, feature: .assetCatalog),
            Row(title: PlanFeature.dynamicTypeCode.title, cells: pro, feature: .dynamicTypeCode),
            Row(title: PlanFeature.shortcuts.title, cells: pro, feature: .shortcuts),
        ]
    }

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                Text("Feature")
                ForEach(PlanTier.allCases, id: \.self) { tier in
                    Text(tier.title).gridColumnAlignment(.center)
                }
            }
            .font(.body.weight(.semibold))
            .padding(.vertical, 6)
            Divider()
            ForEach(rows) { row in
                let lit = row.feature != nil && row.feature == highlight
                GridRow {
                    // 방금 부딪힌 기능의 줄은 이름을 강조색 · 굵게.
                    Text(row.title)
                        .fontWeight(lit ? .semibold : .regular)
                        .foregroundStyle(lit ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    ForEach(row.cells.indices, id: \.self) { i in
                        cell(row.cells[i])
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.body)
                .padding(.vertical, 6)
                Divider()
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func cell(_ cell: Cell) -> some View {
        switch cell {
        case .text(let s):
            Text(s)
        case .included:
            Image(systemName: "checkmark")
                .foregroundStyle(.tint)
                .accessibilityLabel(Text("Included", comment: "Comparison table: included"))
        case .excluded:
            Text(verbatim: "–")
                .foregroundStyle(.tertiary)
                .accessibilityLabel(Text("Not included", comment: "Comparison table: not included"))
        }
    }
}

// MARK: - 기능 이름

extension PlanFeature {
    /// 비교표의 줄 이름.
    var title: String {
        switch self {
        case .unlimitedPalette:
            String(localized: "Unlimited palette", comment: "Feature: no limit on palette colors")
        case .bulkAudit:
            String(localized: "Bulk contrast audit and quick fix", comment: "Feature: audit many pasted colors at once")
        case .colorVision:
            String(localized: "Color vision simulation")
        case .safePalettes:
            String(localized: "Color-blind safe palettes", comment: "Feature: add Okabe Ito, IBM, Paul Tol palettes")
        case .colorSetFiles:
            String(localized: "Save .colorset files", comment: "Feature: save a color as a .colorset folder")
        case .assetCatalog:
            String(localized: "Export the palette as one .xcassets", comment: "Feature: export every palette color at once")
        case .dynamicTypeCode:
            String(localized: "Dynamic Type code", comment: "Feature: generated @ScaledMetric and layout code")
        case .shortcuts:
            String(localized: "Shortcuts and Spotlight", comment: "Feature: pick a color or open a screen from Shortcuts")
        }
    }

    /// 페이월 머리의 한 줄 — 방금 부딪힌 자리.
    var reasonTitle: String {
        switch self {
        case .unlimitedPalette:
            String(localized: "Free palettes hold up to \(Plan.freePaletteLimit) colors",
                   comment: "Paywall reason: the free palette limit is reached")
        default:
            title
        }
    }
}
