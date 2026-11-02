import Foundation
import Combine

// MARK: - Saved palette item

struct PaletteItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var set: AppearanceSet
}

// MARK: - Store

@MainActor
final class PaletteStore: ObservableObject {
    @Published var items: [PaletteItem] = [] {
        didSet { save() }
    }
    /// Id of the most recently added item, used to drive the "pop in" animation.
    @Published var lastAddedID: UUID?
    /// Colors added since the user last opened the Palette tab. Drives the
    /// sidebar count badge so additions from other lenses are noticeable.
    @Published var unseenCount: Int = 0

    private static let storageKey = "tetratint.palette.v1"

    init() {
        load()
    }

    func add(name: String, set: AppearanceSet) {
        var candidate = name.trimmingCharacters(in: .whitespaces)
        if candidate.isEmpty { candidate = "Color\(items.count + 1)" }
        // Deduplicate names so asset export never collides.
        var unique = candidate
        var counter = 2
        while items.contains(where: { $0.name == unique }) {
            unique = "\(candidate)\(counter)"
            counter += 1
        }
        let item = PaletteItem(name: unique, set: set)
        items.append(item)
        lastAddedID = item.id
        unseenCount += 1
    }

    func remove(_ item: PaletteItem) {
        items.removeAll { $0.id == item.id }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        guard let decoded = try? JSONDecoder().decode([PaletteItem].self, from: data) else {
            // 못 읽은 원본을 옆에 남긴다 — 빈 목록으로 시작해 다음 저장이 덮어써도 되찾을 수 있게
            UserDefaults.standard.set(data, forKey: Self.storageKey + ".unreadable")
            return
        }
        items = decoded
    }
}
