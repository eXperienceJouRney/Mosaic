//
//  RecordDraftTests.swift
//  MosaicTests
//
//  锁定新增记录的纯规则：必填、日期归一化、跨月分桶与标签解析。
//

import Foundation
import Testing
@testable import Mosaic

struct RecordDraftTests {
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return MosaicCalendar.calendar.date(from: components)!
    }

    @Test("作品名称必填且去除首尾空白")
    func titleIsRequiredAndTrimmed() {
        var draft = RecordDraft()
        #expect(!draft.isValid)

        draft.title = "   \n "
        #expect(!draft.isValid)

        draft.title = "  一一 "
        #expect(draft.isValid)
        #expect(draft.normalizedTitle == "一一")
    }

    @Test("保存时记录日期归一化到当天零点")
    func recordDateIsNormalized() {
        var draft = RecordDraft()
        draft.title = "一一"
        draft.recordDate = date(2026, 9, 3, hour: 23)

        let item = draft.makeItem()

        #expect(item.recordDate == MosaicCalendar.startOfDay(date(2026, 9, 3, hour: 23)))
        #expect(MosaicCalendar.isoDayKey(item.recordDate) == "2026-09-03")
    }

    @Test("跨月记录落在实际记录日期的格子里")
    func crossMonthRecordLandsOnItsOwnDay() {
        let currentMonth = MosaicCalendar.startOfMonth(.now)
        let targetMonth = MosaicCalendar.addMonths(-2, to: currentMonth)
        let targetDay = MosaicCalendar.addDays(4, to: targetMonth)

        var draft = RecordDraft()
        draft.title = "跨月记录"
        draft.recordDate = targetDay

        let item = draft.makeItem()
        let index = DayIndex(items: [item])

        #expect(index.count(on: targetDay) == 1)
        #expect(index.items(on: targetDay).first === item)
        #expect(index.count(inMonthOf: targetMonth) == 1)
        #expect(index.count(inMonthOf: currentMonth) == 0)
    }

    @Test("标签支持中英文分隔符、去重并保留内部空格")
    func tagsAreNormalized() {
        var draft = RecordDraft()
        draft.title = "海边的卡夫卡"
        draft.tagsText = "文学, 小说，小说 #重读、non fiction"

        #expect(draft.tags == ["文学", "小说", "重读", "non fiction"])

        let item = draft.makeItem()
        #expect(item.tags == ["文学", "小说", "重读", "non fiction"])
        #expect(item.tagsRaw == "文学,小说,重读,non fiction")
    }

    @Test("标签数组写回模型时同样会规范化")
    func tagsSetterNormalizes() {
        let item = MediaItem(title: "海边的卡夫卡", kind: .book, tags: ["文学", " 小说 ", "文学"])

        #expect(item.tagsRaw == "文学,小说")
        #expect(item.tags == ["文学", "小说"])

        item.tags = ["a", "A", "b"]
        #expect(item.tags == ["a", "b"])
        #expect(item.tagsRaw == "a,b")
    }

    @Test("不同类型使用不同的字段名称")
    func kindsUseTheirOwnFieldNames() {
        #expect(MediaKind.movie.titleFieldLabel == "片名")
        #expect(MediaKind.book.titleFieldLabel == "书名")
        #expect(MediaKind.comic.titleFieldLabel == "漫画名")
        #expect(MediaKind.music.titleFieldLabel == "专辑或单曲")
        #expect(MediaKind.podcast.titleFieldLabel == "节目名")
        #expect(MediaKind.game.titleFieldLabel == "游戏名")
        #expect(MediaKind.other.titleFieldLabel == "作品名称")

        #expect(MediaKind.movie.creatorFieldLabel == "导演")
        #expect(MediaKind.book.creatorFieldLabel == "作者")
        #expect(MediaKind.comic.creatorFieldLabel == "作者")
        #expect(MediaKind.music.creatorFieldLabel == "艺术家")
        #expect(MediaKind.podcast.creatorFieldLabel == "主播")
        #expect(MediaKind.game.creatorFieldLabel == "开发者")
        #expect(MediaKind.other.creatorFieldLabel == "创作者")
    }

    @Test("图片信息会随草稿写入模型")
    func imageMetadataIsCarriedOver() {
        var draft = RecordDraft()
        draft.title = "花样年华"
        draft.kind = .movie
        draft.creator = " 王家卫 "
        draft.note = "  那些消逝了的岁月。 "

        let identifier = UUID()
        let item = draft.makeItem(
            id: identifier,
            imageFileName: "cover.jpg",
            pixelWidth: 900,
            pixelHeight: 1200
        )

        #expect(item.id == identifier)
        #expect(item.title == "花样年华")
        #expect(item.kind == .movie)
        #expect(item.creator == "王家卫")
        #expect(item.note == "那些消逝了的岁月。")
        #expect(item.imageFileName == "cover.jpg")
        #expect(item.pixelWidth == 900)
        #expect(item.pixelHeight == 1200)
        #expect(item.hasImage)
    }
}
