import Foundation
import Observation

@Observable
final class MediaCatalogStore {
    static let shared = MediaCatalogStore()
    private let defaults = UserDefaults.standard
    private(set) var tags: [String]
    private(set) var moods: [String]

    private init() {
        tags = defaults.stringArray(forKey: "mosaic.customTags.v1") ?? []
        moods = defaults.stringArray(forKey: "mosaic.moods.v1") ?? ["平静", "开心", "感动", "思考", "怀念", "惊喜"]
    }

    func addTag(_ value: String) { tags = add(value, to: tags); defaults.set(tags, forKey: "mosaic.customTags.v1") }
    func addMood(_ value: String) { moods = add(value, to: moods); defaults.set(moods, forKey: "mosaic.moods.v1") }

    func remember(tags newTags: [String]) {
        var result = tags
        for tag in newTags where !result.contains(where: { $0.localizedCaseInsensitiveCompare(tag) == .orderedSame }) {
            result.append(tag)
        }
        tags = result
        defaults.set(tags, forKey: "mosaic.customTags.v1")
    }

    func removeTag(_ value: String) { tags.removeAll { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }; defaults.set(tags, forKey: "mosaic.customTags.v1") }
    func removeMood(_ value: String) { moods.removeAll { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }; defaults.set(moods, forKey: "mosaic.moods.v1") }

    private func add(_ value: String, to values: [String]) -> [String] {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !values.contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) else { return values }
        return values + [trimmed]
    }
}
