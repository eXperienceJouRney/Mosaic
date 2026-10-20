//
//  DayIndex.swift
//  Mosaic
//
//  把记录按「天」分桶，供日历网格 O(1) 查询；可按分类预先过滤。
//

import Foundation

struct DayIndex {
    private let buckets: [Date: [MediaItem]]

    /// - Parameter categoryID: 传入分类 id 时只保留该分类的记录，nil 表示全部。
    init(items: [MediaItem], categoryID: String? = nil) {
        var buckets: [Date: [MediaItem]] = [:]
        // 先排好序再分桶，保证同一天内顺序稳定（按创建时间升序）。
        for item in items.sorted(by: { $0.createdAt < $1.createdAt })
        where categoryID == nil || item.categoryID == categoryID {
            buckets[item.dayKey, default: []].append(item)
        }
        self.buckets = buckets
    }

    /// 兼容按内置类型过滤的调用（测试 & 旧代码）。
    init(items: [MediaItem], kind: MediaKind?) {
        self.init(items: items, categoryID: kind?.rawValue)
    }

    func items(on day: Date) -> [MediaItem] {
        buckets[MosaicCalendar.startOfDay(day)] ?? []
    }

    func count(on day: Date) -> Int {
        buckets[MosaicCalendar.startOfDay(day)]?.count ?? 0
    }

    var totalCount: Int {
        buckets.values.reduce(0) { $0 + $1.count }
    }

    func count(inMonthOf date: Date) -> Int {
        let calendar = MosaicCalendar.calendar
        var total = 0
        for (day, dayItems) in buckets where calendar.isDate(day, equalTo: date, toGranularity: .month) {
            total += dayItems.count
        }
        return total
    }
}
