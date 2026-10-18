//
//  MediaCategory.swift
//  Mosaic
//
//  筛选栏与记录类型共用的分类。
//  内置分类直接复用 MediaKind 的 rawValue 作为 id，因此历史记录无需迁移；
//  用户新建的分类用 "custom-<uuid>" 作为 id，标题随分类一起保存。
//
//  分类 id 落在 MediaItem.kindRaw 里，删除分类时记录仍然保留，
//  只是会回退显示成「其他」。
//

import Foundation

struct MediaCategory: Identifiable, Hashable, Codable {
    /// 内置分类是 MediaKind.rawValue，自定义分类是 "custom-<uuid>"。
    let id: String
    var title: String
    var symbolName: String

    /// 内置分类对应的类型；自定义分类为 nil。
    var builtInKind: MediaKind? { MediaKind(rawValue: id) }

    var isBuiltIn: Bool { builtInKind != nil }

    // MARK: - 表单文案

    /// 「作品名称」这一栏的标签，自定义分类统一用通用叫法。
    var titleFieldLabel: String { builtInKind?.titleFieldLabel ?? "作品名称" }

    var creatorFieldLabel: String { builtInKind?.creatorFieldLabel ?? "创作者" }

    var titleFieldPlaceholder: String { builtInKind?.titleFieldPlaceholder ?? "例如：任一喜欢的作品" }

    /// 时间轴右上角的小字，自定义分类统一落到 SAVED。
    var timelineActionLabel: String { builtInKind?.timelineActionLabel ?? "SAVED" }

    // MARK: - 构造

    static func builtIn(_ kind: MediaKind) -> MediaCategory {
        MediaCategory(id: kind.rawValue, title: kind.title, symbolName: kind.symbolName)
    }

    static func custom(title: String, id: String = "custom-\(UUID().uuidString)") -> MediaCategory {
        MediaCategory(id: id, title: title, symbolName: "tag")
    }

    /// 首次启动时的分类顺序，与筛选栏参考稿一致。
    static let allBuiltIn: [MediaCategory] = MediaKind.filterOrder.map(MediaCategory.builtIn)

    /// 自定义分类 id 的前缀。
    static let customIDPrefix = "custom-"
}
