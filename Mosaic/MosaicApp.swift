//
//  MosaicApp.swift
//  Mosaic
//
//  Created by RayTse.
//

import SwiftData
import SwiftUI

@main
struct MosaicApp: App {
    private let container: ModelContainer

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments

        // UI 测试专用：真实磁盘库 + 可选重置，用来验证重启后数据仍在。
        if arguments.contains("-usePersistentTestStore") {
            container = MosaicContainer.makeUITestPersistentContainer(
                reset: arguments.contains("-resetPersistentTestStore")
            )
            return
        }

        // UI 测试可用 -useEmptyStore：干净的内存库，用来断言新增记录的条数。
        if arguments.contains("-useEmptyStore") {
            container = MosaicContainer.makeInMemory()
            return
        }

        // UI 测试与演示可用 -usePreviewContainer：每次启动都是干净的内存库 + 样例数据。
        if arguments.contains("-usePreviewContainer") {
            container = MosaicContainer.preview
            return
        }
        #endif

        container = MosaicContainer.shared
        // DEBUG 下可用启动参数 -seedSampleData 往持久库灌入样例数据。
        MosaicContainer.seedSampleDataIfRequested(in: container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
