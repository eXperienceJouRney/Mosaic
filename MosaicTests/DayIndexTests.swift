//
//  DayIndexTests.swift
//  MosaicTests
//

import Foundation
import Testing
@testable import Mosaic

struct DayIndexTests {
    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return MosaicCalendar.calendar.date(from: components)!
    }

    @Test("按天分桶并统计")
    func groupsByDay() {
        let day = date(2026, 2, 3)
        let first = MediaItem(title: "海边的卡夫卡", kind: .book, recordDate: day)
        let second = MediaItem(title: "花样年华", kind: .movie, recordDate: day)
        let other = MediaItem(title: "async", kind: .music, recordDate: MosaicCalendar.addDays(1, to: day))

        let index = DayIndex(items: [second, first, other])

        #expect(index.count(on: day) == 2)
        #expect(index.items(on: day).count == 2)
        #expect(index.count(on: MosaicCalendar.addDays(1, to: day)) == 1)
        #expect(index.count(on: MosaicCalendar.addDays(2, to: day)) == 0)
        #expect(index.totalCount == 3)
    }

    @Test("按月统计只算本月")
    func countsInMonth() {
        let february = date(2026, 2, 10)
        let items = [
            MediaItem(title: "A", kind: .book, recordDate: date(2026, 2, 2)),
            MediaItem(title: "B", kind: .book, recordDate: date(2026, 2, 28)),
            MediaItem(title: "C", kind: .book, recordDate: date(2026, 1, 31)),
            MediaItem(title: "D", kind: .book, recordDate: date(2026, 3, 1)),
        ]

        let index = DayIndex(items: items)

        #expect(index.count(inMonthOf: february) == 2)
        #expect(index.totalCount == 4)
    }

    @Test("记录日期归一化到当天零点")
    func recordDateIsNormalized() {
        let lateNight = date(2026, 2, 11, hour: 23)
        let item = MediaItem(title: "深夜", kind: .other, recordDate: lateNight)

        #expect(item.recordDate == MosaicCalendar.startOfDay(lateNight))
        #expect(item.dayKey == item.recordDate)
        #expect(item.recordDate != lateNight)
    }

    @Test("评分被限制在 0...5")
    func ratingIsClamped() {
        #expect(MediaItem(title: "A", kind: .book, rating: -3).rating == 0)
        #expect(MediaItem(title: "B", kind: .book, rating: 9).rating == 5)
    }

    @Test("未知类型回退到「其他」")
    func unknownKindFallsBack() {
        let item = MediaItem(title: "X", kind: .book)
        item.kindRaw = "legacy-unknown"
        #expect(item.kind == .other)
    }

    @Test("按类型筛选只保留对应记录")
    func filtersByKind() {
        let day = date(2026, 2, 3)
        let book = MediaItem(title: "A", kind: .book, recordDate: day)
        let movie = MediaItem(title: "B", kind: .movie, recordDate: day)
        let podcast = MediaItem(title: "C", kind: .podcast, recordDate: day)

        let all = DayIndex(items: [book, movie, podcast])
        #expect(all.count(on: day) == 3)

        let moviesOnly = DayIndex(items: [book, movie, podcast], kind: .movie)
        #expect(moviesOnly.count(on: day) == 1)
        #expect(moviesOnly.totalCount == 1)
        #expect(moviesOnly.items(on: day).first?.title == "B")

        #expect(DayIndex(items: [book, movie], kind: .game).totalCount == 0)
    }

    @Test("筛选后按天分组仍然正确")
    func filteredGrouping() {
        let day1 = date(2026, 2, 3)
        let day2 = date(2026, 2, 9)
        let items = [
            MediaItem(title: "A", kind: .book, recordDate: day1),
            MediaItem(title: "B", kind: .book, recordDate: day1),
            MediaItem(title: "C", kind: .movie, recordDate: day2),
        ]

        let index = DayIndex(items: items, kind: .book)
        #expect(index.count(on: day1) == 2)
        #expect(index.count(on: day2) == 0)
        #expect(index.count(inMonthOf: day1) == 2)
    }

    @Test("切换分类是只读推导，不修改记录日期")
    func filteringDoesNotMutateRecords() {
        let bookDate = date(2026, 10, 5)
        let movieDate = date(2026, 10, 12)
        let book = MediaItem(title: "海边的卡夫卡", kind: .book, recordDate: bookDate)
        let movie = MediaItem(title: "花样年华", kind: .movie, recordDate: movieDate)

        _ = DayIndex(items: [book, movie], kind: .movie)
        _ = DayIndex(items: [book, movie], kind: .book)
        _ = DayIndex(items: [book, movie], kind: nil)

        #expect(book.recordDate == MosaicCalendar.startOfDay(bookDate))
        #expect(movie.recordDate == MosaicCalendar.startOfDay(movieDate))
        #expect(book.dayKey == book.recordDate)
        #expect(movie.dayKey == movie.recordDate)
        #expect(book.kind == .book)
        #expect(movie.kind == .movie)
    }

    @Test("分类筛选只影响当前视图，其他月份计数不变")
    func filterIsScopedPerMonthWithoutLosingOtherMonths() {
        let september = date(2026, 9, 1)
        let october = date(2026, 10, 1)

        let septemberMovie = MediaItem(title: "蓝", kind: .movie, recordDate: date(2026, 9, 9))
        let octoberMovie = MediaItem(title: "春光乍泄", kind: .movie, recordDate: date(2026, 10, 12))
        let octoberBook = MediaItem(title: "树上的男爵", kind: .book, recordDate: date(2026, 10, 27))

        let all = DayIndex(items: [septemberMovie, octoberMovie, octoberBook])
        let movies = DayIndex(items: [septemberMovie, octoberMovie, octoberBook], kind: .movie)
        let books = DayIndex(items: [septemberMovie, octoberMovie, octoberBook], kind: .book)

        #expect(all.count(inMonthOf: october) == 2)
        #expect(all.count(inMonthOf: september) == 1)

        #expect(movies.count(inMonthOf: october) == 1)
        #expect(movies.count(inMonthOf: september) == 1)
        #expect(movies.count(on: date(2026, 10, 27)) == 0)

        #expect(books.count(inMonthOf: october) == 1)
        #expect(books.count(inMonthOf: september) == 0)
    }

    @Test("跨年时按月统计不会把十二月和一月混在一起")
    func monthCountingRespectsYearBoundary() {
        let december = date(2026, 12, 31)
        let january = date(2027, 1, 1)
        let items = [
            MediaItem(title: "年末", kind: .other, recordDate: december),
            MediaItem(title: "年初", kind: .other, recordDate: january),
        ]

        let index = DayIndex(items: items)
        #expect(index.count(inMonthOf: december) == 1)
        #expect(index.count(inMonthOf: january) == 1)
        #expect(index.count(on: december) == 1)
        #expect(index.count(on: january) == 1)
    }

    @Test("筛选栏覆盖全部类型且没有重复")
    func filterOrderCoversEveryKind() {
        #expect(MediaKind.filterOrder.count == MediaKind.allCases.count)
        for kind in MediaKind.allCases {
            #expect(MediaKind.filterOrder.contains(kind))
        }
        #expect(MediaKind.allCases.allSatisfy { !$0.title.isEmpty })
    }
}
