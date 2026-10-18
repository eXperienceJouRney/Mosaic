//
//  MonthGridTests.swift
//  MosaicTests
//
//  网格是日历里最容易出错的纯逻辑，先把它锁死。
//

import Foundation
import Testing
@testable import Mosaic

struct MonthGridTests {
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return MosaicCalendar.calendar.date(from: components)!
    }

    @Test("网格总是按整周切分")
    func weeksAreComplete() {
        for month in 1...12 {
            let grid = MonthGrid(monthContaining: date(2026, month, 15))
            #expect(grid.weeks.allSatisfy { $0.count == 7 })
            #expect(grid.days.count % 7 == 0)
            #expect(!grid.weeks.isEmpty)
        }
    }

    @Test("2024 年 2 月（闰月，周四起）")
    func february2024() {
        let grid = MonthGrid(monthContaining: date(2024, 2, 10))

        #expect(grid.weeks.count == 5)
        #expect(grid.days.count == 35)
        #expect(grid.days.filter { $0.isInMonth }.count == 29)

        let inMonth = grid.days.filter { $0.isInMonth }
        #expect(inMonth.first?.number == 1)
        #expect(inMonth.last?.number == 29)
    }

    @Test("2024 年 12 月（周日开始，需要 6 行）")
    func december2024NeedsSixRows() {
        let grid = MonthGrid(monthContaining: date(2024, 12, 1))

        #expect(grid.weeks.count == 6)
        #expect(grid.days.count == 42)
        #expect(grid.days.filter { $0.isInMonth }.count == 31)
    }

    @Test("首尾补位标记为非本月")
    func leadingAndTrailingPadding() {
        let grid = MonthGrid(monthContaining: date(2024, 2, 10))

        #expect(grid.days.first?.isInMonth == false)
        #expect(grid.days.last?.isInMonth == false)

        // 2024-02-01 是周四，周一为首日 → 前面补 3 天（1 月 29/30/31）。
        #expect(grid.days.first.map { MosaicCalendar.dayNumber(of: $0.date) } == 29)
        #expect(MosaicCalendar.isSameDay(grid.days.first!.date, date(2024, 1, 29)))

        // 末尾补到 2024-03-03。
        #expect(MosaicCalendar.isSameDay(grid.days.last!.date, date(2024, 3, 3)))
    }

    @Test("日期连续且月份锚点正确")
    func daysAreContiguous() {
        let anchor = date(2026, 7, 20)
        let grid = MonthGrid(monthContaining: anchor)

        #expect(MosaicCalendar.isSameDay(grid.monthStart, MosaicCalendar.startOfMonth(anchor)))

        for (previous, next) in zip(grid.days, grid.days.dropFirst()) {
            #expect(MosaicCalendar.isSameDay(next.date, MosaicCalendar.addDays(1, to: previous.date)))
        }

        for day in grid.days {
            #expect(MosaicCalendar.startOfDay(day.date) == day.date)
        }
    }

    @Test("每一行都严格从周一开始、到周日结束")
    func columnsAlignWithWeekdayHeaders() {
        let calendar = MosaicCalendar.calendar
        let monday = MosaicCalendar.weekStartWeekday
        let sunday = (monday + 5) % 7 + 1

        for month in 1...12 {
            let grid = MonthGrid(monthContaining: date(2026, month, 1))
            for week in grid.weeks {
                #expect(week.count == 7)
                #expect(calendar.component(.weekday, from: week.first!.date) == monday)
                #expect(calendar.component(.weekday, from: week.last!.date) == sunday)
            }
        }
    }

    @Test("闰年二月有 29 天且落在正确格位")
    func leapFebruary() {
        let grid = MonthGrid(monthContaining: date(2028, 2, 10))
        let inMonth = grid.days.filter { $0.isInMonth }

        #expect(MosaicCalendar.daysInMonth(of: grid.monthStart) == 29)
        #expect(inMonth.count == 29)
        #expect(inMonth.first?.number == 1)
        #expect(inMonth.last?.number == 29)

        // 2028-02-01 是周二，周一起始 → 前面补 1 天（1 月 31 日）。
        #expect(MosaicCalendar.isSameDay(grid.days.first!.date, date(2028, 1, 31)))
        #expect(grid.days.first!.isInMonth == false)
    }

    @Test("平年二月有 28 天")
    func commonFebruary() {
        let grid = MonthGrid(monthContaining: date(2026, 2, 10))
        let inMonth = grid.days.filter { $0.isInMonth }

        #expect(MosaicCalendar.daysInMonth(of: grid.monthStart) == 28)
        #expect(inMonth.count == 28)
        #expect(inMonth.last?.number == 28)
    }

    @Test("月首正好是周一时不需要前置补位")
    func monthStartingOnMonday() {
        // 2026-06-01 是周一，30 天 → 5 行 35 格。
        let grid = MonthGrid(monthContaining: date(2026, 6, 1))

        #expect(grid.weeks.count == 5)
        #expect(grid.days.count == 35)
        #expect(grid.days.first?.number == 1)
        #expect(grid.days.first?.isInMonth == true)
        #expect(grid.days[29].number == 30)
        #expect(grid.days[30].isInMonth == false)
    }

    @Test("恰好四周的月份只生成 4 行")
    func februaryStartingOnMondayHasFourRows() {
        // 2027-02-01 是周一，28 天 → 正好 4 行，没有补位。
        let grid = MonthGrid(monthContaining: date(2027, 2, 1))

        #expect(grid.weeks.count == 4)
        #expect(grid.days.count == 28)
        #expect(grid.days.allSatisfy { $0.isInMonth })
        #expect(grid.days.first?.number == 1)
        #expect(grid.days.last?.number == 28)
    }

    @Test("一月的网格可跨到上一年十二月")
    func januaryLeadingPaddingCrossesYear() {
        // 2027-01-01 是周五，周一起始 → 补 2026-12-28...12-31 四天。
        let grid = MonthGrid(monthContaining: date(2027, 1, 1))

        #expect(MosaicCalendar.isSameDay(grid.days.first!.date, date(2026, 12, 28)))
        #expect(grid.days[0..<4].allSatisfy { !$0.isInMonth })
        #expect(grid.days[4].number == 1)
        #expect(grid.days[4].isInMonth)
        #expect(MosaicCalendar.isSameDay(grid.days.last!.date, date(2027, 1, 31)))
    }

    @Test("连续五年所有月份的天数与补位都准确")
    func allMonthsAcrossYears() {
        for year in 2024...2028 {
            for month in 1...12 {
                let anchor = date(year, month, 15)
                let grid = MonthGrid(monthContaining: anchor)
                let expectedDays = MosaicCalendar.daysInMonth(of: anchor)
                let inMonth = grid.days.filter(\.isInMonth)

                #expect(grid.monthStart == MosaicCalendar.startOfMonth(anchor))
                #expect(grid.days.count % 7 == 0)
                #expect(inMonth.count == expectedDays)
                #expect(inMonth.first?.number == 1)
                #expect(inMonth.last?.number == expectedDays)

                // 本月日期必须连续、从 1 号排到月末，且每天都是零点。
                for (index, day) in inMonth.enumerated() {
                    #expect(day.number == index + 1)
                    #expect(day.date == MosaicCalendar.startOfDay(day.date))
                }
            }
        }
    }
}
