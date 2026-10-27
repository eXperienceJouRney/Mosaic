//
//  TimelineFeedTests.swift
//  MosaicTests
//
//  时间轴的筛选与分组：年份、分类、时间范围，以及月份顺序与条数。
//

import Foundation
import Testing
@testable import Mosaic

struct TimelineFeedTests {
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return MosaicCalendar.calendar.date(from: components)!
    }

    private func item(
        _ title: String,
        kind: MediaKind = .book,
        on day: Date,
        createdAt: Date = .now
    ) -> MediaItem {
        let item = MediaItem(title: title, kind: kind, recordDate: day)
        item.createdAt = createdAt
        return item
    }

    @Test("按年份过滤，跨年记录不混进来")
    func filtersByYear() {
        let items = [
            item("今年", on: date(2026, 3, 8)),
            item("去年", on: date(2025, 12, 31)),
            item("明年", on: date(2027, 1, 1)),
        ]

        let feed = TimelineFeed(items: items, year: 2026, range: .all, today: date(2026, 10, 18))

        #expect(feed.totalCount == 1)
        #expect(feed.sections.flatMap(\.items).map(\.title) == ["今年"])
    }

    @Test("按类型过滤")
    func filtersByKind() {
        let day = date(2026, 5, 4)
        let items = [
            item("书", kind: .book, on: day),
            item("电影", kind: .movie, on: day),
            item("音乐", kind: .music, on: day),
        ]

        let feed = TimelineFeed(
            items: items,
            year: 2026,
            range: .all,
            kind: .movie,
            today: date(2026, 10, 18)
        )

        #expect(feed.totalCount == 1)
        #expect(feed.sections.first?.items.first?.title == "电影")
    }

    @Test("月份分组从新到旧，组内按记录日期倒序")
    func groupsByMonthNewestFirst() {
        let items = [
            item("九月早", on: date(2026, 9, 3)),
            item("十月晚", on: date(2026, 10, 12)),
            item("九月晚", on: date(2026, 9, 28)),
            item("十月早", on: date(2026, 10, 1)),
        ]

        let feed = TimelineFeed(items: items, year: 2026, range: .all, today: date(2026, 10, 18))

        #expect(feed.sections.count == 2)
        #expect(feed.sections.map { MosaicCalendar.month(of: $0.monthStart) } == [10, 9])
        #expect(feed.sections[0].items.map(\.title) == ["十月晚", "十月早"])
        #expect(feed.sections[1].items.map(\.title) == ["九月晚", "九月早"])
        #expect(feed.sections[0].title == "October 2026")
    }

    @Test("同一天的记录按创建时间倒序，保证顺序稳定")
    func sortsSameDayByCreation() {
        let day = date(2026, 10, 12)
        let items = [
            item("先建", on: day, createdAt: date(2026, 10, 1, hour: 9)),
            item("后建", on: day, createdAt: date(2026, 10, 2, hour: 9)),
        ]

        let feed = TimelineFeed(items: items, year: 2026, range: .all, today: date(2026, 10, 18))

        #expect(feed.sections.first?.items.map(\.title) == ["后建", "先建"])
    }

    @Test("近 3 月包含两个月前的记录，排除三个月外与未来")
    func threeMonthRange() {
        let today = date(2026, 10, 18)
        let items = [
            item("上个月", on: date(2026, 9, 20)),
            item("两个月前", on: date(2026, 8, 20)),
            item("边界当天", on: date(2026, 7, 18)),
            item("三个月外", on: date(2026, 7, 17)),
            item("未来", on: date(2026, 10, 25)),
        ]

        let feed = TimelineFeed(items: items, year: 2026, range: .threeMonths, today: today)
        let titles = feed.sections.flatMap(\.items).map(\.title)

        #expect(titles.contains("上个月"))
        #expect(titles.contains("两个月前"))
        #expect(titles.contains("边界当天"))
        #expect(!titles.contains("三个月外"))
        #expect(!titles.contains("未来"))
    }

    @Test("近 1 月只保留最近一个月，且不含未来记录")
    func oneMonthRange() {
        let today = date(2026, 10, 18)
        let items = [
            item("刚刚好一个月前", on: date(2026, 9, 18)),
            item("一个月零一天前", on: date(2026, 9, 17)),
            item("两天前", on: date(2026, 10, 16)),
            item("后天", on: date(2026, 10, 20)),
        ]

        let feed = TimelineFeed(items: items, year: 2026, range: .oneMonth, today: today)
        let titles = feed.sections.flatMap(\.items).map(\.title)

        #expect(titles == ["两天前", "刚刚好一个月前"])
    }

    @Test("全部范围下不设右界，补记的未来日期也能看到")
    func allRangeKeepsFuture() {
        let today = date(2026, 10, 18)
        let items = [item("补记", on: date(2026, 12, 1))]

        let feed = TimelineFeed(items: items, year: 2026, range: .all, today: today)

        #expect(feed.totalCount == 1)
    }

    @Test("没有匹配记录时为空")
    func emptyWhenNothingMatches() {
        let feed = TimelineFeed(items: [], year: 2026, range: .all, today: date(2026, 10, 18))

        #expect(feed.isEmpty)
        #expect(feed.totalCount == 0)
        #expect(feed.sections.isEmpty)
    }

    @Test("时间范围的三段文案与回溯月数")
    func rangeMetadata() {
        #expect(TimelineRange.allCases.map(\.title) == ["全部", "近 3 月", "近 1 月"])
        #expect(TimelineRange.all.monthCount == nil)
        #expect(TimelineRange.threeMonths.monthCount == 3)
        #expect(TimelineRange.oneMonth.monthCount == 1)
    }

    @Test("时间轴动作标签按类型区分")
    func actionLabels() {
        #expect(MediaKind.movie.timelineActionLabel == "WATCHED")
        #expect(MediaKind.book.timelineActionLabel == "READ")
        #expect(MediaKind.comic.timelineActionLabel == "READ")
        #expect(MediaKind.music.timelineActionLabel == "LISTENED")
        #expect(MediaKind.podcast.timelineActionLabel == "LISTENED")
        #expect(MediaKind.game.timelineActionLabel == "SAVED")
        #expect(MediaKind.other.timelineActionLabel == "SAVED")
    }
}
