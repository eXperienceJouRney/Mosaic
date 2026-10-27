//
//  TimelineUITests.swift
//  MosaicUITests
//
//  第二页回归：从底部导航进入时间轴、按分类 / 时间范围筛选、打开作品详情。
//  使用 -usePreviewContainer 的样例数据；日期断言一律由设备当前日期推导，
//  不写死某一天，避免跨月 / 跨年时测试失效。
//

import Foundation
import XCTest

final class TimelineUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-usePreviewContainer", "-resetMediaCategories"]
        app.launch()
    }

    // MARK: - 进入时间轴与分类筛选

    @MainActor
    func testSwitchToTimelineAndFilterByKind() throws {
        let timelineTab = try openTimeline()

        let entries = visibleEntries()
        XCTAssertGreaterThan(entries.count, 0, "时间轴应显示记录")
        XCTAssertTrue(
            entries.allSatisfy { entryDate($0) != nil },
            "每条记录都应带有日期"
        )
        XCTAssertTrue(
            entryDate(entries[0]).map { currentCalendar.component(.year, from: $0) == currentYear } ?? false,
            "默认年份应为今年：\(entries[0].identifier)"
        )

        attachScreenshot(named: "TimelineAll")

        // 只保留音乐：可见条目的类型全部变成音乐，电影记录消失。
        app.buttons["filter-music"].tap()
        XCTAssertTrue(app.buttons["filter-music"].isSelected)

        let musicEntries = visibleEntries()
        XCTAssertGreaterThan(musicEntries.count, 0, "音乐筛选下应仍有记录")
        for entry in musicEntries {
            XCTAssertTrue(entry.label.contains("，音乐"), "音乐筛选下不应出现其他类型：\(entry.label)")
        }
        XCTAssertFalse(entry(containing: "花样年华").exists, "音乐筛选下不应出现电影记录")

        // 回到全部：电影记录回来，Timeline 仍是选中页。
        app.buttons["filter-all"].tap()
        XCTAssertTrue(
            entry(containing: "花样年华").waitForExistence(timeout: 5),
            "全部筛选下电影记录应回来"
        )
        XCTAssertTrue(timelineTab.isSelected)
    }

    // MARK: - 时间范围

    @MainActor
    func testTimeRangeKeepsOnlyEntriesInsideTheWindow() throws {
        try openTimeline()
        XCTAssertTrue(visibleEntries().count > 0)

        // 近 1 月：所有可见条目的日期都在最近一个月内。
        app.buttons["timelineRange-oneMonth"].tap()
        XCTAssertTrue(app.buttons["timelineRange-oneMonth"].isSelected)
        assertVisibleEntries(within: 1)

        // 近 3 月：窗口放宽到三个月，两个月前的样例记录重新出现。
        app.buttons["timelineRange-threeMonths"].tap()
        XCTAssertTrue(app.buttons["timelineRange-threeMonths"].isSelected)
        assertVisibleEntries(within: 3)

        let oldEntry = entry(containing: "电锯人") // 两个月前
        if currentMonthNumber > 2 {
            XCTAssertTrue(oldEntry.waitForExistence(timeout: 5), "近 3 月应包含两个月前的记录")
        }

        attachScreenshot(named: "TimelineThreeMonths")

        // 回到全部，列表重新包含更早的记录。
        app.buttons["timelineRange-all"].tap()
        XCTAssertTrue(app.buttons["timelineRange-all"].isSelected)
        XCTAssertTrue(entry(containing: "花样年华").waitForExistence(timeout: 5))
    }

    // MARK: - 列表 → 详情 → 返回

    @MainActor
    func testOpenDetailFromTimelineAndBack() throws {
        try openTimeline()

        let target = entry(containing: "花样年华")
        XCTAssertTrue(target.waitForExistence(timeout: 5), "应能找到《花样年华》")
        target.tap()

        XCTAssertTrue(
            app.buttons["editRecordButton"].waitForExistence(timeout: 5),
            "点击条目应进入作品详情"
        )
        XCTAssertEqual(app.staticTexts["detailTitle"].label, "花样年华")
        XCTAssertFalse(
            app.buttons["timelineTabButton"].exists,
            "进入详情后底部导航应隐藏"
        )

        app.buttons["detailBackButton"].tap()
        XCTAssertTrue(
            app.buttons["yearTitleButton"].waitForExistence(timeout: 5),
            "返回后应回到时间轴"
        )
        XCTAssertTrue(app.buttons["timelineTabButton"].isSelected, "返回后仍停留在 Timeline")
    }

    // MARK: - 年份切换（与画廊的月份切换同款）

    @MainActor
    func testYearHeaderSwitchesAndPicksYear() throws {
        try openTimeline()

        let title = app.buttons["yearTitleButton"]
        XCTAssertTrue(title.label.contains(String(currentYear)), "默认年份应为今年：\(title.label)")

        // ‹ 切到上一年：样例数据只有今年，所以列表变空。
        app.buttons["previousYearButton"].tap()
        XCTAssertTrue(
            waitForLabel(title, containing: String(currentYear - 1)),
            "‹ 应切到上一年：\(title.label)"
        )
        XCTAssertTrue(
            app.staticTexts["这段时间还没有记录。"].waitForExistence(timeout: 5),
            "上一年没有记录时应显示空状态"
        )

        // 点击年份打开选择器，用「回到今年」跳回来。
        title.tap()
        XCTAssertTrue(
            app.buttons["currentYearButton"].waitForExistence(timeout: 5),
            "点击年份应打开年份选择器"
        )
        XCTAssertTrue(app.buttons["year-\(currentYear - 1)"].exists, "选择器应包含当前页年份")
        app.buttons["currentYearButton"].tap()
        XCTAssertTrue(
            waitForLabel(title, containing: String(currentYear)),
            "选择器应切回今年：\(title.label)"
        )
        XCTAssertTrue(
            entry(containing: "花样年华").waitForExistence(timeout: 5),
            "回到今年应重新显示记录"
        )

        // › 切到下一年。
        app.buttons["nextYearButton"].tap()
        XCTAssertTrue(
            waitForLabel(title, containing: String(currentYear + 1)),
            "› 应切到下一年：\(title.label)"
        )
    }

    // MARK: - 切换标签保留各自的浏览状态

    @MainActor
    func testGalleryKeepsItsStateWhenSwitchingTabs() throws {
        XCTAssertTrue(app.buttons["nextMonthButton"].waitForExistence(timeout: 15))
        app.buttons["nextMonthButton"].tap()
        app.buttons["filter-movie"].tap()
        XCTAssertTrue(app.buttons["filter-movie"].isSelected)

        let monthLabel = app.buttons["monthTitleButton"].label

        app.buttons["timelineTabButton"].tap()
        XCTAssertTrue(app.buttons["yearTitleButton"].waitForExistence(timeout: 5))

        app.buttons["galleryTabButton"].tap()
        XCTAssertTrue(app.buttons["monthTitleButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["monthTitleButton"].label, monthLabel, "切回不应重置月份")
        XCTAssertTrue(app.buttons["filter-movie"].isSelected, "切回不应重置分类")
    }

    // MARK: - 辅助

    @MainActor
    private func openTimeline() throws -> XCUIElement {
        let timelineTab = app.buttons["timelineTabButton"]
        XCTAssertTrue(timelineTab.waitForExistence(timeout: 15), "底部导航应有 Timeline")
        timelineTab.tap()
        XCTAssertTrue(
            app.buttons["yearTitleButton"].waitForExistence(timeout: 5),
            "时间轴页应显示年份标题"
        )
        return timelineTab
    }

    @MainActor
    private func waitForLabel(
        _ element: XCUIElement,
        containing text: String,
        timeout: TimeInterval = 5
    ) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// 只统计当前屏幕上真实渲染出来的条目（LazyVStack 不会实例化屏幕外的行）。
    private func visibleEntries() -> [XCUIElement] {
        let query = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "timelineEntry-"))
        return (0..<query.count).map { query.element(boundBy: $0) }
    }

    private func entry(containing title: String) -> XCUIElement {
        app.buttons
            .matching(NSPredicate(
                format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                "timelineEntry-",
                title
            ))
            .firstMatch
    }

    /// 断言当前可见条目的日期都落在「最近 n 个月」窗口内。
    private func assertVisibleEntries(within months: Int) {
        let today = Date()
        let lower = currentCalendar.date(byAdding: .month, value: -months, to: today)!
        let upper = currentCalendar.date(byAdding: .day, value: 1, to: today)!

        for entry in visibleEntries() {
            guard let date = entryDate(entry) else {
                XCTFail("无法从标识中解析日期：\(entry.identifier)")
                continue
            }
            XCTAssertGreaterThanOrEqual(date, currentCalendar.startOfDay(for: lower), "超出范围：\(entry.label)")
            XCTAssertLessThan(date, upper, "超出范围：\(entry.label)")
        }
    }

    /// 条目标识形如 timelineEntry-2026-10-12。
    private func entryDate(_ element: XCUIElement) -> Date? {
        let prefix = "timelineEntry-"
        guard element.identifier.hasPrefix(prefix) else { return nil }
        let text = String(element.identifier.dropFirst(prefix.count))

        var components = DateComponents()
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return currentCalendar.date(from: components)
    }

    private var currentCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private var currentYear: Int { currentCalendar.component(.year, from: Date()) }
    private var currentMonthNumber: Int { currentCalendar.component(.month, from: Date()) }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
