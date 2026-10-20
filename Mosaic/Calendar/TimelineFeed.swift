//
//  TimelineFeed.swift
//  Mosaic
//
//  纯逻辑：把记录整理成时间轴的「月份分组 → 当天条目」。
//  年份 / 分类 / 时间范围三种筛选都在这里完成，视图只负责画。
//  不依赖 SwiftUI / SwiftData，方便单元测试。
//

import Foundation

/// 时间轴右上角的时间范围。与参考稿一致：全部 / 近 3 月 / 近 1 月。
enum TimelineRange: String, CaseIterable, Identifiable {
    case all
    case threeMonths
    case oneMonth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .threeMonths: return "近 3 月"
        case .oneMonth: return "近 1 月"
        }
    }

    /// 相对「今天」向前回溯的月数；nil 表示不限。
    var monthCount: Int? {
        switch self {
        case .all: return nil
        case .threeMonths: return 3
        case .oneMonth: return 1
        }
    }
}

struct TimelineFeed {
    struct Section: Identifiable {
        /// 该月第一天 00:00。
        let monthStart: Date
        let items: [MediaItem]

        var id: Date { monthStart }
        /// "October 2026"
        var title: String { MosaicCalendar.monthTitle(monthStart) }
    }

    let sections: [Section]
    let totalCount: Int

    /// - Parameters:
    ///   - year: 只保留这一年的记录。
    ///   - range: 时间范围。选择具体范围时，未来的记录也会被排除（参考稿同样以今天为右界）。
    ///   - categoryID: 传入分类 id 时只保留该分类的记录，nil 表示全部。
    ///   - today: 计算范围的锚点，测试里可以固定。
    init(
        items: [MediaItem],
        year: Int,
        range: TimelineRange,
        categoryID: String? = nil,
        today: Date = .now
    ) {
        let todayStart = MosaicCalendar.startOfDay(today)
        let lowerBound = range.monthCount.flatMap {
            MosaicCalendar.calendar.date(byAdding: .month, value: -$0, to: todayStart)
        }
        // 「全部」不设右界，补记的未来日期也能看到。
        let upperBound = range.monthCount.map { _ in MosaicCalendar.addDays(1, to: todayStart) }

        let filtered = items
            .filter { item in
                guard categoryID == nil || item.categoryID == categoryID else { return false }

                let day = item.dayKey
                guard MosaicCalendar.year(of: day) == year else { return false }
                if let lowerBound, day < lowerBound { return false }
                if let upperBound, day >= upperBound { return false }
                return true
            }
            .sorted { lhs, rhs in
                if lhs.recordDate != rhs.recordDate { return lhs.recordDate > rhs.recordDate }
                return lhs.createdAt > rhs.createdAt
            }

        var sections: [Section] = []
        var currentMonth: Date?
        var bucket: [MediaItem] = []

        for item in filtered {
            let month = MosaicCalendar.startOfMonth(item.recordDate)
            if month != currentMonth {
                if let currentMonth {
                    sections.append(Section(monthStart: currentMonth, items: bucket))
                }
                currentMonth = month
                bucket = []
            }
            bucket.append(item)
        }

        if let currentMonth {
            sections.append(Section(monthStart: currentMonth, items: bucket))
        }

        self.sections = sections
        self.totalCount = filtered.count
    }

    /// 兼容按内置类型过滤的调用（测试 & 旧代码）。
    init(
        items: [MediaItem],
        year: Int,
        range: TimelineRange,
        kind: MediaKind?,
        today: Date = .now
    ) {
        self.init(items: items, year: year, range: range, categoryID: kind?.rawValue, today: today)
    }

    var isEmpty: Bool { sections.isEmpty }
}
