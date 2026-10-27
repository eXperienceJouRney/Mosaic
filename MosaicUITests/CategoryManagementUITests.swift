//
//  CategoryManagementUITests.swift
//  MosaicUITests
//
//  分类管理回归：长按筛选栏进入编辑态、新建分类、删除分类。
//  启动参数 -resetMediaCategories 保证每次都从默认分类开始。
//

import Foundation
import XCTest

final class CategoryManagementUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-usePreviewContainer", "-resetMediaCategories"]
        app.launch()
    }

    @MainActor
    func testLongPressOpensManagementAndAddsCategory() throws {
        let movie = app.buttons["filter-movie"]
        XCTAssertTrue(movie.waitForExistence(timeout: 15), "筛选栏应显示电影分类")
        XCTAssertTrue(app.buttons["filter-all"].isSelected, "默认应筛选全部")

        // 长按进入管理态：不改变当前筛选，行尾出现「新分类」。
        movie.press(forDuration: 0.8)

        let addButton = app.buttons["filter-add-category"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "长按分类应进入编辑态")
        XCTAssertTrue(app.buttons["filter-all"].isSelected, "进入编辑态不应改变筛选")

        addButton.tap()

        let nameField = app.textFields["categoryNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "应弹出新建分类面板")
        nameField.tap()
        nameField.typeText("纪录片")

        let confirm = app.buttons["categoryAddConfirmButton"]
        XCTAssertTrue(waitForEnabled(confirm), "填写名称后应可添加")
        confirm.tap()

        let deleteBadge = app.buttons["删除分类 纪录片"]
        XCTAssertTrue(deleteBadge.waitForExistence(timeout: 5), "新分类应出现在筛选栏")

        attachScreenshot(named: "CategoryManagement")

        // 删除分类：只移除分类本身，不删除记录。
        deleteBadge.tap()
        let alert = app.alerts["删除分类"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "删除前应确认")
        alert.buttons["删除"].tap()

        XCTAssertTrue(deleteBadge.waitForNonExistence(timeout: 5), "删除后分类应消失")

        app.buttons["filter-edit-done"].tap()
        XCTAssertTrue(addButton.waitForNonExistence(timeout: 5), "完成后应退出编辑态")
    }

    // MARK: - 辅助

    @MainActor
    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
