//
//  RecordDraft.swift
//  Mosaic
//
//  添加记录时的纯数据草稿：与 SwiftUI 无关，方便单元测试校验
//  「必填 / 日期归一化 / 标签解析」这些规则。
//

import Foundation

struct RecordDraft {
    /// 分类 id。内置分类是 MediaKind.rawValue，自定义分类是 "custom-<uuid>"。
    var categoryID: String = MediaKind.movie.rawValue
    var title: String = ""
    var creator: String = ""
    var recordDate: Date = .now
    var note: String = ""
    var tagsText: String = ""
    var mood: String = ""
    var collectionID: UUID?

    /// 兼容按内置类型读写的调用方；自定义分类在这里回退到 .other。
    /// 真正落库的是 `categoryID`。
    var kind: MediaKind {
        get { MediaKind(rawValue: categoryID) ?? .other }
        set { categoryID = newValue.rawValue }
    }

    init() {}

    /// 编辑已有记录时用同一个草稿类型回填，保存前的修改不会碰到 SwiftData 模型，
    /// 取消编辑就等于丢弃草稿。
    init(item: MediaItem) {
        categoryID = item.categoryID
        title = item.title
        creator = item.creator
        recordDate = item.recordDate
        note = item.note
        tagsText = item.tags.joined(separator: ", ")
        mood = item.mood
        collectionID = item.collectionID
    }

    // MARK: - 校验

    /// 作品名称必填；只有空白字符不算填写。
    var isValid: Bool { !normalizedTitle.isEmpty }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedCreator: String {
        creator.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var tags: [String] {
        MediaTags.parse(tagsText)
    }

    // MARK: - 生成模型

    /// 图片由调用方先写入 ImageStore，再把文件名与尺寸传进来。
    /// 日期由 MediaItem 统一归一化到当天 00:00，保证日历分组稳定。
    func makeItem(
        id: UUID = UUID(),
        imageFileName: String = "",
        pixelWidth: Double = 0,
        pixelHeight: Double = 0
    ) -> MediaItem {
        MediaItem(
            title: normalizedTitle,
            creator: normalizedCreator,
            kind: kind,
            categoryID: categoryID,
            note: normalizedNote,
            mood: mood,
            collectionID: collectionID,
            recordDate: recordDate,
            imageFileName: imageFileName,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            tags: tags,
            id: id
        )
    }
}
