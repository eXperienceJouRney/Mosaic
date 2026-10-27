//
//  MediaItem.swift
//  Mosaic
//
//  一条书影音记录。图片以文件形式存放在磁盘（见 ImageStore），
//  模型里只保存文件名与像素尺寸，避免把图片二进制塞进数据库。
//

import Foundation
import SwiftData

@Model
final class MediaItem {
    var id: UUID = UUID()

    /// 标题，例如《海边的卡夫卡》。
    var title: String = ""

    /// 作者 / 导演 / 音乐人。
    var creator: String = ""

    /// 分类 id：内置类型存 MediaKind.rawValue，自定义分类存 "custom-<uuid>"。
    /// 存字符串而非枚举，方便排序、谓词查询与后续迁移。
    var kindRaw: String = MediaKind.book.rawValue

    /// 0...5 星，0 表示未评分。
    var rating: Int = 0

    var note: String = ""

    /// Optional mood and collection association used by the expanded journal flow.
    var mood: String = ""
    var collectionID: UUID?

    /// 标签以逗号分隔的文本落库，对外仍然通过 `tags` 读写数组。
    /// 这样不用为标签单独建表，也能安全地做轻量迁移。
    var tagsRaw: String = ""

    /// 记录归属的日期，归一化到当天 00:00。
    var recordDate: Date = Date()

    /// 原图文件名（位于 ImageStore.originalsDirectory）。
    var imageFileName: String = ""

    var pixelWidth: Double = 0
    var pixelHeight: Double = 0

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        title: String,
        creator: String = "",
        kind: MediaKind,
        categoryID: String? = nil,
        rating: Int = 0,
        note: String = "",
        mood: String = "",
        collectionID: UUID? = nil,
        recordDate: Date = .now,
        imageFileName: String = "",
        pixelWidth: Double = 0,
        pixelHeight: Double = 0,
        tags: [String] = [],
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.creator = creator
        // 自定义分类没有对应的 MediaKind，此时由 categoryID 决定落库的分类 id。
        self.kindRaw = categoryID ?? kind.rawValue
        self.rating = max(0, min(5, rating))
        self.note = note
        self.mood = mood
        self.collectionID = collectionID
        self.tagsRaw = MediaTags.serialize(tags)
        self.recordDate = MosaicCalendar.startOfDay(recordDate)
        self.imageFileName = imageFileName
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.createdAt = .now
        self.updatedAt = .now
    }

    // MARK: - 派生属性

    /// 分类 id，与 `kindRaw` 同义。筛选、显示都优先用它，才能覆盖自定义分类。
    var categoryID: String { kindRaw }

    /// 内置类型。自定义分类没有对应的枚举值，回退到 .other。
    var kind: MediaKind {
        get { MediaKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var tags: [String] {
        get { MediaTags.parse(tagsRaw) }
        set { tagsRaw = MediaTags.serialize(newValue) }
    }

    var hasImage: Bool { !imageFileName.isEmpty }

    /// 画廊分组键。
    var dayKey: Date { MosaicCalendar.startOfDay(recordDate) }

    /// 只在需要显示时改动，保证 updatedAt 一致。
    func touch() {
        updatedAt = .now
    }

    // MARK: - 编辑

    /// 把编辑草稿写回模型。日期与新增时使用同一套归一化规则，
    /// 因此改完日期后 `dayKey` 会立即指向新的一天，日历格子随之更新。
    func apply(_ draft: RecordDraft) {
        kindRaw = draft.categoryID
        title = draft.normalizedTitle
        creator = draft.normalizedCreator
        note = draft.normalizedNote
        mood = draft.mood
        collectionID = draft.collectionID
        tags = draft.tags
        recordDate = MosaicCalendar.startOfDay(draft.recordDate)
        touch()
    }

    /// 图片文件由 ImageStore 单独管理，这里只同步文件名与像素尺寸。
    func setImage(fileName: String, pixelWidth: Double, pixelHeight: Double) {
        imageFileName = fileName
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    func clearImage() {
        setImage(fileName: "", pixelWidth: 0, pixelHeight: 0)
    }
}
