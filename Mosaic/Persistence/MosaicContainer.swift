//
//  MosaicContainer.swift
//  Mosaic
//
//  SwiftData 容器的唯一入口。生产、预览、测试各用一套配置。
//  未来加字段时，在这里挂 SchemaMigrationPlan，避免改动散落各处。
//

import Foundation
import SwiftData

enum MosaicContainer {
    static let schema = Schema([MediaItem.self, MediaCollection.self])

    /// 正式 App 使用的容器。
    static let shared: ModelContainer = {
        do {
            let configuration = ModelConfiguration("Mosaic", schema: schema)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("无法创建 SwiftData 容器：\(error)")
        }
    }()

    /// 预览 / 测试使用的内存容器。
    static func makeInMemory() -> ModelContainer {
        do {
            let configuration = ModelConfiguration(
                "MosaicPreview",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("无法创建内存 SwiftData 容器：\(error)")
        }
    }

    /// SwiftUI 预览专用容器，带样例数据（仅 DEBUG 填充）。
    static let preview: ModelContainer = {
        let container = makeInMemory()
        #if DEBUG
        let context = ModelContext(container)
        PreviewData.populate(context)
        try? context.save()
        #endif
        return container
    }()

    // MARK: - 调试

    #if DEBUG
    /// UI 测试专用：固定位置的磁盘库，用来验证杀掉 App 再启动后记录仍在。
    /// 只有显式传入启动参数时才会用到，不会影响正式 App 的存储。
    static func makeUITestPersistentContainer(reset: Bool) -> ModelContainer {
        do {
            let fileManager = FileManager.default
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            let directory = base.appendingPathComponent("MosaicUITest", isDirectory: true)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            let storeURL = directory.appendingPathComponent("Mosaic.store")
            if reset {
                // SQLite 主文件与 WAL / SHM 一起清掉，保证测试从空库开始。
                for suffix in ["", "-shm", "-wal"] {
                    try? fileManager.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
                }
            }

            let configuration = ModelConfiguration("MosaicUITest", schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("无法创建 UI 测试持久化容器：\(error)")
        }
    }
    #endif

    /// 仅当启动参数包含 `-seedSampleData` 且库为空时写入样例数据。
    /// 在 Xcode Scheme → Run → Arguments 里加这个参数即可看到有内容的画廊。
    static func seedSampleDataIfRequested(in container: ModelContainer) {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-seedSampleData") else { return }

        let context = ModelContext(container)
        let existing = (try? context.fetchCount(FetchDescriptor<MediaItem>())) ?? 0
        guard existing == 0 else { return }

        PreviewData.populate(context)
        try? context.save()
        #endif
    }
}
