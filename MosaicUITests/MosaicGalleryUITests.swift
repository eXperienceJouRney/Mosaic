//
//  MosaicGalleryUITests.swift
//  MosaicUITests
//
//  首页交互回归：月份按钮、月份选择器、分类筛选与跨年跳转。
//  日期断言使用设备当前年月推导，避免写死某一天。
//

import Foundation
import XCTest

final class MosaicGalleryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-usePreviewContainer", "-resetMediaCategories"]
        app.launch()
    }

    @MainActor
    func testMonthNavigationKeepsFilterAndUpdatesMonth() throws {
        let title = app.buttons["monthTitleButton"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "月份标题应可点击")

        let calendar = currentCalendar
        let now = Date()
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!

        XCTAssertTrue(title.label.hasPrefix(monthTitle(currentMonth)), "初始月份应为当前月：\(title.label)")

        // 分类筛选：当前月 12 号在样例数据里有 5 条记录（书 / 电影 / 播客 / 游戏 / 音乐）。
        let day12ID = "day-\(isoDay(currentMonth, day: 12))"
        let day12 = app.buttons[day12ID]
        XCTAssertTrue(day12.waitForExistence(timeout: 5), "当前月 12 号应存在")
        XCTAssertTrue(
            waitForLabel(day12, containing: "5 条记录"),
            "全部筛选下 12 号应有 5 条：\(day12.label)"
        )

        app.buttons["filter-movie"].tap()
        XCTAssertTrue(app.buttons["filter-movie"].isSelected, "电影筛选应处于选中态")
        XCTAssertTrue(
            waitForLabel(day12, containing: "1 条记录"),
            "电影筛选下 12 号只应剩 1 条：\(day12.label)"
        )

        // 切到下个月，筛选保持，图片与记录全部换成下个月的数据。
        app.buttons["nextMonthButton"].tap()
        XCTAssertTrue(waitForLabel(title, containing: monthTitle(nextMonth)))
        XCTAssertTrue(app.buttons["filter-movie"].isSelected, "切换月份后应保留电影筛选")

        let nextDay3ID = "day-\(isoDay(nextMonth, day: 3))"
        let nextDay3 = app.buttons[nextDay3ID]
        XCTAssertTrue(nextDay3.waitForExistence(timeout: 5), "下个月 3 号应存在")
        XCTAssertTrue(
            waitForLabel(nextDay3, containing: "1 条记录"),
            "下个月 3 号在电影筛选下应有 1 条：\(nextDay3.label)"
        )

        // 再往前两个月，回到上一个月；分类仍然保持。
        app.buttons["previousMonthButton"].tap()
        app.buttons["previousMonthButton"].tap()
        XCTAssertTrue(waitForLabel(title, containing: monthTitle(previousMonth)))
        XCTAssertTrue(app.buttons["filter-movie"].isSelected, "连续切换月份后应保留电影筛选")

        // 通过月份选择器的「回到本月」跳回当前月，分类筛选仍然保留。
        title.tap()
        XCTAssertTrue(app.buttons["currentMonthButton"].waitForExistence(timeout: 5))
        app.buttons["currentMonthButton"].tap()
        XCTAssertTrue(waitForLabel(title, containing: monthTitle(currentMonth)))
        XCTAssertTrue(app.buttons["filter-movie"].isSelected, "回到本月后应保留电影筛选")

        // 恢复全部筛选，12 号重新显示 5 条。
        app.buttons["filter-all"].tap()
        XCTAssertTrue(app.buttons["filter-all"].isSelected)
        XCTAssertTrue(
            waitForLabel(day12, containing: "5 条记录"),
            "恢复全部后 12 号应重新显示 5 条：\(day12.label)"
        )
    }

    @MainActor
    func testMonthPickerJumpsToLeapFebruaryAndHandlesYearBoundary() throws {
        let title = app.buttons["monthTitleButton"]
        XCTAssertTrue(title.waitForExistence(timeout: 15))

        let calendar = currentCalendar
        let currentYear = calendar.component(.year, from: Date())
        let leapYear = 2028
        let yearDelta = leapYear - currentYear

        title.tap()
        XCTAssertTrue(app.buttons["currentMonthButton"].waitForExistence(timeout: 5), "月份选择器应打开")

        if yearDelta > 0 {
            for _ in 0..<yearDelta {
                app.buttons["nextYearButton"].tap()
            }
        } else if yearDelta < 0 {
            for _ in 0..<(-yearDelta) {
                app.buttons["previousYearButton"].tap()
            }
        }

        XCTAssertTrue(
            app.buttons["month-\(leapYear)-2"].waitForExistence(timeout: 5),
            "年份切换后应显示目标月份"
        )
        app.buttons["month-\(leapYear)-2"].tap()
        XCTAssertTrue(waitForLabel(title, containing: "February \(leapYear)"), "应跳转到闰年二月")

        // 闰年二月 29 天：1 号与 29 号都在，30 号不存在。
        XCTAssertTrue(app.buttons["day-\(leapYear)-02-01"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["day-\(leapYear)-02-29"].exists, "2028 年 2 月应包含 29 号")
        XCTAssertFalse(app.buttons["day-\(leapYear)-02-30"].exists, "2 月不应出现 30 号")

        // 12 月 → 1 月的跨年切换。
        title.tap()
        XCTAssertTrue(app.buttons["month-\(leapYear)-12"].waitForExistence(timeout: 5))
        app.buttons["month-\(leapYear)-12"].tap()
        XCTAssertTrue(waitForLabel(title, containing: "December \(leapYear)"))

        app.buttons["nextMonthButton"].tap()
        XCTAssertTrue(waitForLabel(title, containing: "January \(leapYear + 1)"))
        XCTAssertTrue(app.buttons["day-\(leapYear + 1)-01-01"].waitForExistence(timeout: 5))

        app.buttons["previousMonthButton"].tap()
        XCTAssertTrue(waitForLabel(title, containing: "December \(leapYear)"))
        XCTAssertTrue(app.buttons["day-\(leapYear)-12-31"].waitForExistence(timeout: 5))
    }

    // MARK: - 辅助

    private var currentCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = currentCalendar
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func isoDay(_ month: Date, day: Int) -> String {
        var components = currentCalendar.dateComponents([.year, .month], from: month)
        components.day = day
        let date = currentCalendar.date(from: components) ?? month
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = currentCalendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    @MainActor
    private func waitForLabel(_ element: XCUIElement, containing text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
