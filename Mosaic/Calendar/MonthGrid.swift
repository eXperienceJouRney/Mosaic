//
//  MonthGrid.swift
//  Mosaic
//
//  纯逻辑：把一个月展开成按周分组的日期网格（含首尾补位）。
//  不依赖 SwiftUI / SwiftData，方便单元测试。
//

import Foundation

struct MonthGrid: Equatable {
    struct Day: Identifiable, Hashable {
        /// 当天 00:00。
        let date: Date
        /// 是否属于当前展示的月份（否则是上/下月的补位格）。
        let isInMonth: Bool

        var id: Date { date }
        var number: Int { MosaicCalendar.dayNumber(of: date) }
    }

    let monthStart: Date
    let weeks: [[Day]]

    var days: [Day] { weeks.flatMap { $0 } }

    init(monthContaining date: Date) {
        let calendar = MosaicCalendar.calendar
        let monthStart = MosaicCalendar.startOfMonth(date)
        self.monthStart = monthStart

        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let dayCount = MosaicCalendar.daysInMonth(of: monthStart)
        let total = Int((Double(leading + dayCount) / 7.0).rounded(.up)) * 7

        let targetMonth = calendar.component(.month, from: monthStart)
        let targetYear = calendar.component(.year, from: monthStart)

        var days: [Day] = []
        days.reserveCapacity(total)

        for offset in 0..<total {
            let rawDate = calendar.date(byAdding: .day, value: offset - leading, to: monthStart) ?? monthStart
            let dayStart = calendar.startOfDay(for: rawDate)
            let sameMonth = calendar.component(.month, from: dayStart) == targetMonth
                && calendar.component(.year, from: dayStart) == targetYear
            days.append(Day(date: dayStart, isInMonth: sameMonth))
        }

        var weeks: [[Day]] = []
        var index = 0
        while index < days.count {
            let end = min(index + 7, days.count)
            weeks.append(Array(days[index..<end]))
            index = end
        }
        self.weeks = weeks
    }
}
