//
//  RecordPersistenceTests.swift
//  MosaicTests
//
//  用真实磁盘上的 SwiftData 容器验证：
//  新增 → 关闭容器 → 重新打开仍然能读到记录；
//  编辑日期 / 换图 / 删除都会写回磁盘，并同步清理图片文件。
//

import Foundation
import SwiftData
import Testing
import UIKit
@testable import Mosaic

@MainActor
struct RecordPersistenceTests {
    // MARK: - 新增持久化

    @Test("记录在容器关闭并重新打开后仍然存在")
    func recordSurvivesContainerReopen() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }

        let identifier: UUID
        let fileName: String

        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)

            var draft = RecordDraft()
            draft.kind = .book
            draft.title = "海边的卡夫卡"
            draft.creator = "村上春树"
            draft.recordDate = Self.date(2026, 3, 14, hour: 21)
            draft.note = "十五岁的少年拖着影子走进四国。"
            draft.tagsText = "文学, 重读"

            let item = try await RecordStore.create(
                draft,
                image: fixture.makeImage(),
                context: context,
                imageStore: fixture.imageStore
            )

            identifier = item.id
            fileName = item.imageFileName
            #expect(fileName == fixture.imageStore.fileName(for: identifier))
            #expect(fixture.imageStore.contains(named: fileName))
            #expect(try context.fetchCount(FetchDescriptor<MediaItem>()) == 1)
        }

        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)
            let items = try context.fetch(FetchDescriptor<MediaItem>())

            #expect(items.count == 1)
            let item = try #require(items.first)
            #expect(item.id == identifier)
            #expect(item.title == "海边的卡夫卡")
            #expect(item.kind == .book)
            #expect(item.creator == "村上春树")
            #expect(item.note == "十五岁的少年拖着影子走进四国。")
            #expect(item.tags == ["文学", "重读"])
            #expect(MosaicCalendar.isoDayKey(item.recordDate) == "2026-03-14")
            #expect(item.imageFileName == fileName)
            #expect(fixture.imageStore.contains(named: fileName))
        }
    }

    // MARK: - 编辑 / 删除持久化

    @Test("编辑后的日期与图片会写回磁盘，删除后记录与图片都消失")
    func editsAndDeletesPersist() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }

        let oldDay = Self.date(2026, 3, 14)
        let newDay = Self.date(2026, 4, 2)

        let identifier: UUID
        let originalFileName: String

        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)

            var draft = RecordDraft()
            draft.kind = .book
            draft.title = "海边的卡夫卡"
            draft.recordDate = oldDay

            let item = try await RecordStore.create(
                draft,
                image: fixture.makeImage(),
                context: context,
                imageStore: fixture.imageStore
            )
            identifier = item.id
            originalFileName = item.imageFileName
        }

        // 编辑：改标题、改日期、换一张图。
        let updatedFileName: String
        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)
            let item = try #require(try context.fetch(FetchDescriptor<MediaItem>()).first)

            var draft = RecordDraft(item: item)
            draft.title = "海边的卡夫卡（重读）"
            draft.recordDate = Self.date(2026, 4, 2, hour: 22)

            try await RecordStore.update(
                item,
                with: draft,
                imageChange: .replace(fixture.makeImage(color: .systemBlue)),
                context: context,
                imageStore: fixture.imageStore
            )

            #expect(item.title == "海边的卡夫卡（重读）")
            #expect(MosaicCalendar.isoDayKey(item.recordDate) == "2026-04-02")
            #expect(item.imageFileName != originalFileName)
            #expect(!fixture.imageStore.contains(named: originalFileName), "旧图应在保存成功后被删除")
            #expect(fixture.imageStore.contains(named: item.imageFileName))

            updatedFileName = item.imageFileName
        }

        // 重新打开：日期、标题与新图片都在；旧日期格子不再包含它。
        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)
            let item = try #require(try context.fetch(FetchDescriptor<MediaItem>()).first)

            #expect(item.id == identifier)
            #expect(item.title == "海边的卡夫卡（重读）")
            #expect(item.imageFileName == updatedFileName)
            #expect(MosaicCalendar.isoDayKey(item.recordDate) == "2026-04-02")

            let index = DayIndex(items: [item])
            #expect(index.count(on: oldDay) == 0)
            #expect(index.count(on: newDay) == 1)
        }

        // 删除：记录与图片一起清理。
        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)
            let item = try #require(try context.fetch(FetchDescriptor<MediaItem>()).first)

            try RecordStore.delete(item, context: context, imageStore: fixture.imageStore)
        }

        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)
            let items = try context.fetch(FetchDescriptor<MediaItem>())

            #expect(items.isEmpty)
            #expect(!fixture.imageStore.contains(named: updatedFileName))
        }
    }

    @Test("移除图片会清空引用并删除磁盘文件")
    func removingImageClearsReferenceAndFile() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }

        let fileName: String
        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)

            var draft = RecordDraft()
            draft.title = "蓝"
            draft.kind = .movie

            let item = try await RecordStore.create(
                draft,
                image: fixture.makeImage(),
                context: context,
                imageStore: fixture.imageStore
            )
            fileName = item.imageFileName
            #expect(fixture.imageStore.contains(named: fileName))

            var edited = RecordDraft(item: item)
            edited.note = "只有蓝色，和声音。"
            try await RecordStore.update(
                item,
                with: edited,
                imageChange: .remove,
                context: context,
                imageStore: fixture.imageStore
            )

            #expect(!item.hasImage)
            #expect(item.pixelWidth == 0)
            #expect(item.pixelHeight == 0)
            #expect(!fixture.imageStore.contains(named: fileName))
        }

        do {
            let container = try fixture.makeContainer()
            let context = ModelContext(container)
            let item = try #require(try context.fetch(FetchDescriptor<MediaItem>()).first)

            #expect(!item.hasImage)
            #expect(item.note == "只有蓝色，和声音。")
        }
    }

    // MARK: - 工具

    private static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return MosaicCalendar.calendar.date(from: components)!
    }

    /// 每个测试使用独立的临时目录，避免相互污染。
    private struct Fixture {
        let root: URL
        let storeURL: URL
        let imageStore: ImageStore

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appendingPathComponent("MosaicPersistenceTests-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            storeURL = root.appendingPathComponent("Mosaic.store")
            imageStore = ImageStore(rootDirectory: root.appendingPathComponent("Images", isDirectory: true))
        }

        func makeContainer() throws -> ModelContainer {
            let configuration = ModelConfiguration(
                schema: MosaicContainer.schema,
                url: storeURL
            )
            return try ModelContainer(for: MosaicContainer.schema, configurations: configuration)
        }

        func makeImage(color: UIColor = .systemOrange) -> UIImage {
            let size = CGSize(width: 120, height: 160)
            return UIGraphicsImageRenderer(size: size).image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }

        func cleanUp() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
