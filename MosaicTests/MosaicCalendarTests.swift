//
//  MosaicCalendarTests.swift
//  MosaicTests
//
//  锁定月份 / 星期的英文格式，避免本地化环境改坏首屏标题。
//

import Foundation
import Testing
@testable import Mosaic

struct MosaicCalendarTests {
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return MosaicCalendar.calendar.date(from: components)!
    }

    @Test("月份标题为英文")
    func monthTitleIsEnglish() {
        #expect(MosaicCalendar.monthTitle(date(2026, 10, 1)) == "October 2026")
    }

    @Test("星期从周一开始并大写")
    func weekdaysStartOnMonday() {
        #expect(MosaicCalendar.weekdaySymbols == ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"])
    }

    @Test("完整日期为英文")
    func fullDateTitleIsEnglish() {
        #expect(MosaicCalendar.fullDateTitle(date(2026, 10, 12)) == "October 12, 2026")
    }

    @Test("月份加减跨年正确")
    func monthArithmeticCrossesYear() {
        let january = MosaicCalendar.startOfMonth(date(2026, 1, 5))
        let december = MosaicCalendar.addMonths(-1, to: january)
        #expect(MosaicCalendar.monthTitle(december) == "December 2025")
    }

    @Test("向前向后都能跨年")
    func monthArithmeticCrossesYearBothWays() {
        let december = MosaicCalendar.startOfMonth(date(2026, 12, 15))
        let nextJanuary = MosaicCalendar.addMonths(1, to: december)
        #expect(MosaicCalendar.monthTitle(nextJanuary) == "January 2027")
        #expect(MosaicCalendar.year(of: nextJanuary) == 2027)
        #expect(MosaicCalendar.month(of: nextJanuary) == 1)

        let january = MosaicCalendar.startOfMonth(date(2026, 1, 15))
        let previousDecember = MosaicCalendar.addMonths(-1, to: january)
        #expect(MosaicCalendar.monthTitle(previousDecember) == "December 2025")

        // 连续跨两年：2026-01 往前 13 个月是 2024-12。
        #expect(MosaicCalendar.monthTitle(MosaicCalendar.addMonths(-13, to: january)) == "December 2024")
        #expect(MosaicCalendar.monthTitle(MosaicCalendar.addMonths(13, to: january)) == "February 2027")
    }

    @Test("天数包含闰年规则")
    func daysInMonthHandlesLeapYears() {
        #expect(MosaicCalendar.daysInMonth(of: date(2024, 2, 1)) == 29)
        #expect(MosaicCalendar.daysInMonth(of: date(2026, 2, 1)) == 28)
        #expect(MosaicCalendar.daysInMonth(of: date(2028, 2, 1)) == 29)
        // 世纪年：2000 是闰年，2100 不是。
        #expect(MosaicCalendar.daysInMonth(of: date(2000, 2, 1)) == 29)
        #expect(MosaicCalendar.daysInMonth(of: date(2100, 2, 1)) == 28)

        #expect(MosaicCalendar.daysInMonth(of: date(2026, 4, 1)) == 30)
        #expect(MosaicCalendar.daysInMonth(of: date(2026, 7, 1)) == 31)
    }

    @Test("按年月直接构造月首")
    func startOfMonthByComponents() {
        let february = MosaicCalendar.startOfMonth(year: 2028, month: 2)
        #expect(MosaicCalendar.monthTitle(february) == "February 2028")
        #expect(MosaicCalendar.dayNumber(of: february) == 1)
        #expect(MosaicCalendar.daysInMonth(of: february) == 29)

        // 越界月份由 Calendar 规范化，不会崩溃。
        let normalized = MosaicCalendar.startOfMonth(year: 2026, month: 13)
        #expect(MosaicCalendar.monthTitle(normalized) == "January 2027")
    }

    @Test("月份名称固定为英文")
    func monthNamesAreEnglish() {
        #expect(MosaicCalendar.monthNames.count == 12)
        #expect(MosaicCalendar.monthName(1) == "January")
        #expect(MosaicCalendar.monthName(12) == "December")
        #expect(MosaicCalendar.monthName(0) == "")
        #expect(MosaicCalendar.monthName(13) == "")
    }
}
