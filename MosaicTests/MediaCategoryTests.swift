//
//  MediaCategoryTests.swift
//  MosaicTests
//
//  分类管理的纯逻辑：默认分类、增删规则、持久化，
//  以及自定义分类在记录 / 筛选里的表现。
//

import Foundation
import Testing
@testable import Mosaic

struct MediaCategoryTests {
    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return MosaicCalendar.calendar.date(from: components)!
    }

    /// 每个用例一份独立的 UserDefaults，避免互相污染。
    private func makeStore() -> (store: MediaCategoryStore, defaults: UserDefaults, suite: String) {
        let suite = "MosaicCategoryTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (MediaCategoryStore(defaults: defaults), defaults, suite)
    }

    private func cleanUp(_ defaults: UserDefaults, _ suite: String) {
        defaults.removePersistentDomain(forName: suite)
    }

    // MARK: - 默认值

    @Test("首次启动按参考稿顺序给出内置分类")
    func seedsBuiltInCategoriesInOrder() {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        #expect(fixture.store.categories.map(\.id) == MediaKind.filterOrder.map(\.rawValue))
        #expect(fixture.store.categories.map(\.title) == ["电影", "书籍", "漫画", "音乐", "播客", "游戏", "其他"])
        #expect(fixture.store.categories.allSatisfy { $0.isBuiltIn })
    }

    // MARK: - 新增

    @Test("新增分类会去掉首尾空白并持久化")
    func addingCategoryPersists() throws {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        let added = try #require(fixture.store.add(title: "  纪录片 "))

        #expect(added.title == "纪录片")
        #expect(added.symbolName == "tag")
        #expect(!added.isBuiltIn)

        // 用同一份 defaults 重新加载，分类仍在末尾。
        let reloaded = MediaCategoryStore(defaults: fixture.defaults)
        #expect(reloaded.categories.last?.title == "纪录片")
        #expect(reloaded.categories.count == MediaCategory.allBuiltIn.count + 1)
    }

    @Test("空标题与重名分类不会重复加入")
    func rejectsEmptyAndDuplicateTitles() {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        #expect(fixture.store.add(title: "   ") == nil)
        #expect(fixture.store.add(title: "电影") == nil)
        #expect(fixture.store.categories.count == MediaCategory.allBuiltIn.count)
    }

    // MARK: - 删除

    @Test("删除分类后，旧记录回退显示为「其他」但不丢数据")
    func deletingCategoryKeepsRecords() {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        let book = MediaCategory.builtIn(.book)
        let item = MediaItem(title: "海边的卡夫卡", kind: .book, recordDate: date(2026, 3, 8))

        #expect(fixture.store.delete(book))
        #expect(!fixture.store.contains(id: book.id))

        // 记录自身的分类 id 没有变化，只是展示回退。
        #expect(item.categoryID == MediaKind.book.rawValue)
        #expect(fixture.store.category(for: item.categoryID).title == "其他")

        // 重新加载后删除结果仍在。
        let reloaded = MediaCategoryStore(defaults: fixture.defaults)
        #expect(!reloaded.contains(id: book.id))
    }

    @Test("至少保留一个分类")
    func keepsAtLeastOneCategory() {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        var remaining = fixture.store.categories
        while remaining.count > 1 {
            #expect(fixture.store.delete(remaining[0]))
            remaining = fixture.store.categories
        }

        #expect(remaining.count == 1)
        #expect(!fixture.store.delete(remaining[0]))
        #expect(fixture.store.categories.count == 1)
    }

    @Test("「全部」是保留名称，「其他」不允许删除")
    func reservesAllTitleAndOtherCategory() {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        #expect(fixture.store.add(title: "全部") == nil)
        #expect(fixture.store.categories.count == MediaCategory.allBuiltIn.count)

        #expect(!fixture.store.delete(MediaCategory.builtIn(.other)))
        #expect(fixture.store.contains(id: MediaKind.other.rawValue))
        #expect(fixture.store.isDeletable(MediaCategory.builtIn(.book)))
    }

    // MARK: - 自定义分类与记录

    @Test("自定义分类使用通用表单文案")
    func customCategoryUsesGenericLabels() {
        let category = MediaCategory.custom(title: "纪录片")

        #expect(category.titleFieldLabel == "作品名称")
        #expect(category.creatorFieldLabel == "创作者")
        #expect(!category.titleFieldPlaceholder.isEmpty)
        #expect(category.timelineActionLabel == "SAVED")
    }

    @Test("自定义分类可以写入记录并按分类筛选")
    func customCategoryFiltersRecords() throws {
        let fixture = makeStore()
        defer { cleanUp(fixture.defaults, fixture.suite) }

        let custom = try #require(fixture.store.add(title: "纪录片"))
        let categoryID = custom.id
        let day = date(2026, 5, 4)

        var draft = RecordDraft()
        draft.categoryID = categoryID
        draft.title = "但是还有书籍"
        draft.recordDate = day
        let item = draft.makeItem()

        #expect(item.categoryID == categoryID)
        #expect(item.kind == .other)
        #expect(fixture.store.category(for: item.categoryID).title == "纪录片")

        let movie = MediaItem(title: "花样年华", kind: .movie, recordDate: day)
        let index = DayIndex(items: [item, movie], categoryID: categoryID)
        #expect(index.count(on: day) == 1)
        #expect(index.items(on: day).first === item)

        let feed = TimelineFeed(
            items: [item, movie],
            year: 2026,
            range: .all,
            categoryID: categoryID,
            today: date(2026, 10, 18)
        )
        #expect(feed.totalCount == 1)
        #expect(feed.sections.first?.items.first === item)
    }

    @Test("编辑记录时分类写回 kindRaw")
    func applyingDraftUpdatesCategoryID() {
        let item = MediaItem(title: "旧标题", kind: .book)
        var draft = RecordDraft(item: item)
        draft.categoryID = MediaCategory.custom(title: "纪录片").id
        draft.title = "新标题"

        item.apply(draft)

        #expect(item.title == "新标题")
        #expect(item.categoryID == draft.categoryID)
        #expect(item.kind == .other)
    }
}
