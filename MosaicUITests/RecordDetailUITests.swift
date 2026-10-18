//
//  RecordDetailUITests.swift
//  MosaicUITests
//
//  当天记录 → 作品详情 → 编辑 / 删除 的回归测试，
//  以及「新建记录 → 杀掉 App → 重新启动 → 记录仍在」的持久化验证。
//

import Foundation
import XCTest

final class RecordDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-usePreviewContainer", "-resetMediaCategories"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - 列表 → 详情 → 编辑

    @MainActor
    func testDayListOpensDetailAndEditUpdatesTitle() throws {
        let dayCell = try openDayTwelve()

        let cards = app.buttons.matching(identifier: "dayRecordCard")
        XCTAssertTrue(cards.element(boundBy: 4).waitForExistence(timeout: 5), "当天列表应显示 5 条记录")
        XCTAssertEqual(cards.count, 5)

        cards.element(boundBy: 0).tap()

        let editButton = app.buttons["editRecordButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5), "点击记录应进入作品详情")
        XCTAssertTrue(app.staticTexts["detailTitle"].exists, "详情页应显示作品名称")

        let originalTitle = app.staticTexts["detailTitle"].label
        editButton.tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "点击编辑应进入编辑表单")
        XCTAssertEqual(titleField.value as? String, originalTitle, "编辑表单应回填原作品名称")

        clearText(in: titleField)
        titleField.typeText("Edited Title")

        let saveButton = app.buttons["saveRecordButton"]
        XCTAssertTrue(waitForEnabled(saveButton), "修改标题后保存应可用")
        saveButton.tap()

        XCTAssertTrue(editButton.waitForExistence(timeout: 10), "保存后应回到作品详情")
        XCTAssertTrue(
            waitForLabel(app.staticTexts["detailTitle"], containing: "Edited Title"),
            "详情页应显示修改后的作品名称"
        )

        // 回到当天列表与首页，记录数量不变，标题已经更新。
        app.buttons["detailBackButton"].tap()
        XCTAssertTrue(cards.element(boundBy: 0).waitForExistence(timeout: 5))
        XCTAssertEqual(cards.count, 5)
        XCTAssertTrue(cards.element(boundBy: 0).label.contains("Edited Title"))

        app.buttons["dayRecordsBackButton"].tap()
        XCTAssertTrue(dayCell.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(dayCell, containing: "5 条记录"), "编辑标题后首页仍应显示 5 条")
    }

    // MARK: - 删除

    @MainActor
    func testDeleteRemovesRecordFromDayAndHome() throws {
        let dayCell = try openDayTwelve()

        let cards = app.buttons.matching(identifier: "dayRecordCard")
        XCTAssertTrue(cards.element(boundBy: 4).waitForExistence(timeout: 5))

        cards.element(boundBy: 0).tap()

        let deleteButton = app.buttons["deleteRecordButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5), "详情页应有删除入口")
        deleteButton.tap()

        let confirmButton = app.buttons["删除"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "删除前应弹出确认")
        confirmButton.tap()

        XCTAssertTrue(app.buttons["dayRecordsBackButton"].waitForExistence(timeout: 5), "删除后应回到当天列表")
        XCTAssertTrue(waitForCount(cards, expected: 4), "当天列表应只剩 4 条记录：\(cards.count)")

        app.buttons["dayRecordsBackButton"].tap()
        XCTAssertTrue(dayCell.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(dayCell, containing: "4 条记录"), "首页格子应同步减少：\(dayCell.label)")
    }

    // MARK: - 持久化

    @MainActor
    func testRecordSurvivesRelaunch() throws {
        // 使用独立的磁盘库，并先清空，避免受上一次测试影响。
        app.terminate()
        app.launchArguments = ["-usePersistentTestStore", "-resetPersistentTestStore"]
        app.launch()

        let addButton = app.buttons["addRecordButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 15), "首页应可加载")
        addButton.tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Persisted Title")

        let saveButton = app.buttons["saveRecordButton"]
        XCTAssertTrue(waitForEnabled(saveButton), "填写标题后保存应可用")
        saveButton.tap()

        XCTAssertTrue(addButton.waitForExistence(timeout: 10), "保存后应返回首页")

        let today = app.buttons["day-\(isoDay(Date()))"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForLabel(today, containing: "1 条记录"), "新记录应先出现在首页")

        // 杀掉 App 再启动：同一磁盘库应保留记录。
        app.terminate()
        app.launchArguments = ["-usePersistentTestStore"]
        app.launch()

        XCTAssertTrue(addButton.waitForExistence(timeout: 15), "重启后首页应可加载")
        let persistedToday = app.buttons["day-\(isoDay(Date()))"]
        XCTAssertTrue(persistedToday.waitForExistence(timeout: 5))
        XCTAssertTrue(
            waitForLabel(persistedToday, containing: "1 条记录"),
            "重启后记录应仍然存在：\(persistedToday.label)"
        )

        // 打开当天列表确认标题也来自磁盘，然后删除以清理测试数据。
        persistedToday.tap()
        let cards = app.buttons.matching(identifier: "dayRecordCard")
        XCTAssertTrue(cards.element(boundBy: 0).waitForExistence(timeout: 5))
        XCTAssertTrue(cards.element(boundBy: 0).label.contains("Persisted Title"))

        cards.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["deleteRecordButton"].waitForExistence(timeout: 5))
        app.buttons["deleteRecordButton"].tap()
        XCTAssertTrue(app.buttons["删除"].waitForExistence(timeout: 5))
        app.buttons["删除"].tap()

        XCTAssertTrue(app.buttons["dayRecordsBackButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitForCount(cards, expected: 0), "清理后当天列表应为空")
    }

    // MARK: - 辅助

    @MainActor
    private func openDayTwelve() throws -> XCUIElement {
        let addButton = app.buttons["addRecordButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 15), "首页应可加载")

        let dayCell = app.buttons["day-\(isoDay(Date(), day: 12))"]
        XCTAssertTrue(dayCell.waitForExistence(timeout: 5), "当前月 12 号应存在")
        dayCell.tap()

        XCTAssertTrue(app.buttons["dayRecordsBackButton"].waitForExistence(timeout: 5), "点击日期应进入当天记录列表")
        return dayCell
    }

    @MainActor
    private func clearText(in element: XCUIElement) {
        element.tap()
        guard let value = element.value as? String, !value.isEmpty else { return }
        element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
    }

    private var currentCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func isoDay(_ date: Date, day: Int? = nil) -> String {
        var components = currentCalendar.dateComponents([.year, .month, .day], from: date)
        if let day {
            components.day = day
        }
        let target = currentCalendar.date(from: components) ?? date
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = currentCalendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: target)
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

    @MainActor
    private func waitForCount(
        _ query: XCUIElementQuery,
        expected: Int,
        timeout: TimeInterval = 8
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if query.count == expected { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return query.count == expected
    }

    @MainActor
    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
