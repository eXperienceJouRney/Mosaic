//
//  RecordEditingTests.swift
//  MosaicTests
//
//  锁定编辑记录的纯规则：草稿回填、字段规范化、改日期后的分桶变化。
//

import Foundation
import Testing
@testable import Mosaic

struct RecordEditingTests {
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return MosaicCalendar.calendar.date(from: components)!
    }

    @Test("编辑草稿完整回填已有记录")
    func draftPrefillsExistingRecord() {
        let item = MediaItem(
            title: "花样年华",
            creator: "王家卫",
            kind: .movie,
            rating: 5,
            note: "那些消逝了的岁月。",
            recordDate: date(2026, 5, 4, hour: 20),
            tags: ["香港", "重看"]
        )

        let draft = RecordDraft(item: item)

        #expect(draft.kind == .movie)
        #expect(draft.title == "花样年华")
        #expect(draft.creator == "王家卫")
        #expect(draft.note == "那些消逝了的岁月。")
        #expect(draft.tagsText == "香港, 重看")
        #expect(draft.recordDate == item.recordDate)
        #expect(draft.isValid)
    }

    @Test("修改日期后记录从旧日期移动到新日期")
    func editingDateMovesRecordToNewDay() {
        let oldDay = date(2026, 10, 3)
        let newDay = date(2026, 10, 9, hour: 22)

        let item = MediaItem(title: "一一", creator: "杨德昌", kind: .movie, recordDate: oldDay)
        var draft = RecordDraft(item: item)
        draft.title = "一一（重看）"
        draft.recordDate = newDay
        item.apply(draft)

        let index = DayIndex(items: [item])

        #expect(index.count(on: oldDay) == 0)
        #expect(index.count(on: newDay) == 1)
        #expect(index.items(on: newDay).first === item)
        #expect(item.recordDate == MosaicCalendar.startOfDay(newDay))
        #expect(MosaicCalendar.isoDayKey(item.recordDate) == "2026-10-09")
        #expect(item.title == "一一（重看）")
    }

    @Test("编辑会重新规范化标题、作者、标签与日期")
    func editingNormalizesFields() {
        let item = MediaItem(title: "旧标题", kind: .book, recordDate: date(2026, 2, 2))
        var draft = RecordDraft(item: item)
        draft.title = "  新标题  \n"
        draft.creator = "  某人 "
        draft.note = "   "
        draft.tagsText = "a、b，a #c"
        draft.recordDate = date(2026, 2, 3, hour: 23)
        item.apply(draft)

        #expect(item.title == "新标题")
        #expect(item.creator == "某人")
        #expect(item.note == "")
        #expect(item.tags == ["a", "b", "c"])
        #expect(item.recordDate == MosaicCalendar.startOfDay(date(2026, 2, 3)))
        #expect(item.updatedAt >= item.createdAt)
    }

    @Test("取消编辑不会修改原记录")
    func cancellingEditLeavesRecordUntouched() {
        let item = MediaItem(
            title: "海边的卡夫卡",
            creator: "村上春树",
            kind: .book,
            recordDate: date(2026, 3, 14),
            tags: ["文学"]
        )
        let originalDate = item.recordDate
        let originalUpdatedAt = item.updatedAt

        var draft = RecordDraft(item: item)
        draft.title = "不保存的标题"
        draft.recordDate = date(2026, 4, 1)
        draft.tagsText = "临时标签"

        // 只是修改草稿，不调用 apply。
        #expect(item.title == "海边的卡夫卡")
        #expect(item.recordDate == originalDate)
        #expect(item.tags == ["文学"])
        #expect(item.updatedAt == originalUpdatedAt)
    }

    @Test("图片引用可以替换和清空")
    func imageReferenceCanBeReplacedAndCleared() {
        let item = MediaItem(title: "蓝", kind: .movie, imageFileName: "old.jpg", pixelWidth: 900, pixelHeight: 1200)

        item.setImage(fileName: "new.jpg", pixelWidth: 600, pixelHeight: 800)
        #expect(item.hasImage)
        #expect(item.imageFileName == "new.jpg")
        #expect(item.pixelWidth == 600)
        #expect(item.pixelHeight == 800)

        item.clearImage()
        #expect(!item.hasImage)
        #expect(item.imageFileName == "")
        #expect(item.pixelWidth == 0)
        #expect(item.pixelHeight == 0)
    }
}
