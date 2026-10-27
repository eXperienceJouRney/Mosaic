//
//  AddRecordUITests.swift
//  MosaicUITests
//
//  新增记录流程回归：入口、类型切换、必填校验、保存后落在当天格子、取消不落库。
//  使用 -useEmptyStore 启动，避免样例数据干扰条数断言。
//

import Foundation
import XCTest

final class AddRecordUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useEmptyStore", "-resetMediaCategories"]
        app.launch()
    }

    @MainActor
    func testAddRecordAppearsOnItsCalendarDay() throws {
        ensureGalleryTabSelected()

        let addButton = app.buttons["addRecordButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 15), "首页应有添加按钮")
        addButton.tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "点击添加按钮应进入添加记录页")

        let saveButton = app.buttons["saveRecordButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertFalse(saveButton.isEnabled, "未填作品名称时保存应不可用")

        // 七种类型都在，切到书籍后字段名换成「书名 / 作者」。
        for kind in ["movie", "book", "comic", "music", "podcast", "game", "other"] {
            XCTAssertTrue(app.buttons["kind-\(kind)"].exists, "缺少类型：\(kind)")
        }
        XCTAssertTrue(app.buttons["kind-movie"].isSelected, "默认类型应为电影")

        attachScreenshot(named: "AddRecordForm")

        app.buttons["kind-book"].tap()
        XCTAssertTrue(app.buttons["kind-book"].isSelected)
        XCTAssertTrue(app.staticTexts["书名"].waitForExistence(timeout: 3), "书籍应显示「书名」")
        XCTAssertTrue(app.staticTexts["作者"].waitForExistence(timeout: 3), "书籍应显示「作者」")

        titleField.tap()
        titleField.typeText("Kafka on the Shore")
        XCTAssertTrue(waitForEnabled(saveButton), "填写作品名称后保存应可用")

        let creatorField = app.textFields["creatorField"]
        creatorField.tap()
        creatorField.typeText("Murakami")

        saveButton.tap()

        XCTAssertTrue(titleField.waitForNonExistence(timeout: 10), "保存后应返回首页")
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "首页应重新可见")

        let today = app.buttons["day-\(isoDay(Date()))"]
        XCTAssertTrue(today.waitForExistence(timeout: 5), "首页应显示今天所在的日历格")
        XCTAssertTrue(
            waitForLabel(today, containing: "1 条记录"),
            "新记录应出现在今天的格子里：\(today.label)"
        )

        attachScreenshot(named: "GalleryAfterSave")

        // 分类筛选仍然可用：切到电影时该格子为空，切回书籍又恢复。
        app.buttons["filter-movie"].tap()
        XCTAssertTrue(app.buttons["filter-movie"].isSelected)
        XCTAssertTrue(
            waitForLabelNotContaining(today, text: "条记录"),
            "电影筛选下今天的记录应被隐藏：\(today.label)"
        )

        app.buttons["filter-book"].tap()
        XCTAssertTrue(
            waitForLabel(today, containing: "1 条记录"),
            "书籍筛选下今天的记录应重新出现：\(today.label)"
        )

        app.buttons["filter-all"].tap()
        XCTAssertTrue(app.buttons["filter-all"].isSelected)
        XCTAssertTrue(waitForLabel(today, containing: "1 条记录"))
    }

    @MainActor
    func testCancelingPhotoPickerReturnsToForm() throws {
        ensureGalleryTabSelected()
        let addButton = app.buttons["addRecordButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 15))
        addButton.tap()

        let photoPicker = app.buttons["photoPickerButton"]
        XCTAssertTrue(photoPicker.waitForExistence(timeout: 5), "表单应提供系统照片选择器入口")
        photoPicker.tap()

        // 系统照片选择器是独立进程的界面，按钮文案随系统语言变化。
        let cancel = app.buttons["Cancel"]
        let cancelChinese = app.buttons["取消"]

        if cancel.waitForExistence(timeout: 10) {
            cancel.tap()
        } else if cancelChinese.waitForExistence(timeout: 5) {
            cancelChinese.tap()
        } else {
            XCTFail("系统照片选择器未出现取消按钮")
        }

        XCTAssertTrue(
            app.textFields["titleField"].waitForExistence(timeout: 5),
            "取消选择图片后应回到表单而不是退出添加页"
        )
        XCTAssertTrue(photoPicker.exists, "图片入口应保持可用")
    }

    @MainActor
    func testSelectingPhotoShowsPreviewAndSavesWithImage() throws {
        ensureGalleryTabSelected()
        let addButton = app.buttons["addRecordButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 15))
        addButton.tap()

        let photoPicker = app.buttons["photoPickerButton"]
        XCTAssertTrue(photoPicker.waitForExistence(timeout: 5))
        photoPicker.tap()

        let photo = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        guard photo.waitForExistence(timeout: 10) else {
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
            throw XCTSkip("模拟器相册为空，跳过图片选择回归")
        }
        // 系统照片选择器的网格元素不报告 hittable，按坐标点按更稳定。
        tapCenter(of: photo)

        let removePhoto = app.buttons["removePhotoButton"]
        XCTAssertTrue(removePhoto.waitForExistence(timeout: 10), "选择图片后应显示预览")
        XCTAssertEqual(photoPicker.label, "更换图片", "有图片后入口应提示更换")

        // 移除后回到空态，再重新选一张，覆盖取消与重选路径。
        removePhoto.tap()
        XCTAssertTrue(photoPicker.waitForExistence(timeout: 5))
        XCTAssertFalse(removePhoto.exists, "移除图片后不应再显示预览删除按钮")

        photoPicker.tap()
        let secondPhoto = app.images.matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(secondPhoto.waitForExistence(timeout: 10))
        tapCenter(of: secondPhoto)
        XCTAssertTrue(removePhoto.waitForExistence(timeout: 10))

        let titleField = app.textFields["titleField"]
        titleField.tap()
        titleField.typeText("Photo Record")
        app.buttons["saveRecordButton"].tap()

        XCTAssertTrue(titleField.waitForNonExistence(timeout: 20), "带图保存后应返回首页")

        let today = app.buttons["day-\(isoDay(Date()))"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(
            waitForLabel(today, containing: "1 条记录"),
            "带图记录也应出现在今天的格子里：\(today.label)"
        )
    }

    @MainActor
    func testCancelReturnsHomeWithoutCreatingRecord() throws {
        ensureGalleryTabSelected()

        let today = app.buttons["day-\(isoDay(Date()))"]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        let labelBeforeCancel = today.label

        let addButton = app.buttons["addRecordButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 15))
        addButton.tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Draft only")

        app.buttons["addRecordCancelButton"].tap()

        XCTAssertTrue(titleField.waitForNonExistence(timeout: 5), "取消后应回到首页")
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "首页应重新可见")

        XCTAssertEqual(today.label, labelBeforeCancel, "取消后不应创建记录：\(today.label)")
    }

    // MARK: - 辅助

    private var currentCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    private func isoDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = currentCalendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    @MainActor
    private func ensureGalleryTabSelected() {
        let galleryTab = app.buttons["galleryTabButton"]
        XCTAssertTrue(galleryTab.waitForExistence(timeout: 10), "应显示 Gallery / Timeline 底部导航")
        if !galleryTab.isSelected {
            galleryTab.tap()
        }
        XCTAssertTrue(
            app.buttons["addRecordButton"].waitForExistence(timeout: 10),
            "应回到 Gallery 并显示添加按钮"
        )
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
    private func waitForLabelNotContaining(
        _ element: XCUIElement,
        text: String,
        timeout: TimeInterval = 5
    ) -> Bool {
        let predicate = NSPredicate(format: "NOT (label CONTAINS %@)", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func tapCenter(of element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    @MainActor
    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
