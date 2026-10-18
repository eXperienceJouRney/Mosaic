//
//  MediaCategoryStore.swift
//  Mosaic
//
//  分类的唯一数据源：内置分类 + 用户新增的分类，整体以 JSON 存进 UserDefaults。
//  筛选栏的长按管理与添加记录时的类型选择都读这里，
//  因此删掉一个分类后，两处会同时消失，已有记录不受影响。
//

import Foundation
import Observation

@Observable
final class MediaCategoryStore {
    /// 正式 App 共用一份。UI 测试可通过 -resetMediaCategories 回到默认分类。
    static let shared = MediaCategoryStore(
        resettingStorage: ProcessInfo.processInfo.arguments.contains("-resetMediaCategories")
    )

    /// 存储键带版本号，将来结构变化时可以换键做轻量迁移。
    private static let storageKey = "mosaic.mediaCategories.v1"

    private(set) var categories: [MediaCategory]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, resettingStorage: Bool = false) {
        self.defaults = defaults
        if resettingStorage {
            defaults.removeObject(forKey: Self.storageKey)
        }
        categories = Self.load(from: defaults)
    }

    // MARK: - 查询

    func contains(id: String) -> Bool {
        categories.contains { $0.id == id }
    }

    /// 找不到时退回「其他」：分类被删除后，旧记录仍然能正常显示。
    func category(for id: String) -> MediaCategory {
        categories.first { $0.id == id } ?? .builtIn(.other)
    }

    func isTitleTaken(_ title: String) -> Bool {
        let target = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return true }
        // 「全部」是筛选栏的固定项，不允许被同名分类占用。
        guard target != "全部" else { return true }
        return categories.contains {
            $0.title.compare(target, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    /// 至少保留一个分类，避免筛选栏与表单都没有可选项。
    var canDelete: Bool { categories.count > 1 }

    /// 「其他」是已删除分类的归宿，不许删除，否则旧记录会无处可归。
    func isDeletable(_ category: MediaCategory) -> Bool {
        canDelete && category.id != MediaKind.other.rawValue
    }

    // MARK: - 编辑

    /// 新增分类。标题为空或重名时返回 nil，由调用方决定如何提示。
    @discardableResult
    func add(title: String) -> MediaCategory? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isTitleTaken(trimmed) else { return nil }

        let category = MediaCategory.custom(title: String(trimmed.prefix(12)))
        categories.append(category)
        persist()
        return category
    }

    /// 删除分类本身，不删除记录；只剩一个分类或目标是「其他」时返回 false。
    @discardableResult
    func delete(_ category: MediaCategory) -> Bool {
        guard isDeletable(category), contains(id: category.id) else { return false }

        categories.removeAll { $0.id == category.id }
        persist()
        return true
    }

    // MARK: - 持久化

    private static func load(from defaults: UserDefaults) -> [MediaCategory] {
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([MediaCategory].self, from: data),
           !saved.isEmpty {
            return saved
        }
        return MediaCategory.allBuiltIn
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(categories) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
