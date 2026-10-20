//
//  MosaicCalendar.swift
//  Mosaic
//
//  全局日期规则：周起始、日归一化、月份运算与英文格式化。
//  月份与星期按参考稿使用英文（October 2026 / MON…SUN）。
//

import Foundation

enum MosaicCalendar {
    /// 一周从周一开始。改成 1 即为周日起始。
    static let weekStartWeekday = 2

    /// 全局唯一的日历配置。
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = .current
        calendar.firstWeekday = weekStartWeekday
        return calendar
    }()

    // MARK: - 日期运算

    /// 归一化到当天 00:00，作为「日期」这一维度的唯一键。
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func startOfMonth(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? startOfDay(date)
    }

    /// 指定年月的第一天 00:00。用于月份选择器直接跳转，避免依赖偏移量。
    static func startOfMonth(year: Int, month: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return calendar.date(from: components).map(startOfMonth) ?? startOfMonth(.now)
    }

    static func addMonths(_ value: Int, to date: Date) -> Date {
        let monthStart = startOfMonth(date)
        return calendar.date(byAdding: .month, value: value, to: monthStart) ?? monthStart
    }

    static func year(of date: Date) -> Int {
        calendar.component(.year, from: date)
    }

    /// 1...12。
    static func month(of date: Date) -> Int {
        calendar.component(.month, from: date)
    }

    static func addDays(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value, to: startOfDay(date)) ?? date
    }

    static func daysInMonth(of date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    static func dayNumber(of date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    static func isToday(_ date: Date) -> Bool {
        isSameDay(date, .now)
    }

    // MARK: - 展示（英文）

    /// 按 firstWeekday 排好的星期缩写，例如 ["MON", "TUE", ..., "SUN"]。
    static let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"

        // 2024-01-01 是周一，据此按 firstWeekday 偏移取 7 天。
        guard let monday = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) else {
            return []
        }
        let offset = (calendar.firstWeekday - 2 + 7) % 7
        return (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: offset + index, to: monday) ?? monday
            return formatter.string(from: date).uppercased()
        }
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()

    private static let monthOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = calendar
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private static let isoDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let weekdayShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.dateFormat = "EEE"
        return formatter
    }()

    /// 一月到十二月的英文全名，与月份标题保持同一语言。
    static let monthNames: [String] = {
        guard let january = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1)) else {
            return []
        }
        return (0..<12).map { offset in
            let date = calendar.date(byAdding: .month, value: offset, to: january) ?? january
            return monthOnlyFormatter.string(from: date)
        }
    }()

    /// "October 2026"
    static func monthTitle(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    /// 1 → "January"；越界时安全回退为空串。
    static func monthName(_ month: Int) -> String {
        guard (1...12).contains(month), monthNames.indices.contains(month - 1) else { return "" }
        return monthNames[month - 1]
    }

    /// "October 12, 2026"
    static func fullDateTitle(_ date: Date) -> String {
        fullDateFormatter.string(from: date)
    }

    /// 时间轴左列的星期缩写，例如 "SUN"。始终按日期本身取，与周起始无关。
    static func weekdayShortLabel(_ date: Date) -> String {
        weekdayShortFormatter.string(from: date).uppercased()
    }

    /// 稳定且可测试的日期键，例如 "2026-10-12"。
    static func isoDayKey(_ date: Date) -> String {
        isoDayFormatter.string(from: startOfDay(date))
    }
}
