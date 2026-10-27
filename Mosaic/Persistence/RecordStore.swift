//
//  RecordStore.swift
//  Mosaic
//
//  新增 / 编辑 / 删除记录的唯一入口，把「模型 + 图片文件」当成一个整体维护：
//  - 图片先落盘，再保存模型；保存失败会回滚并清理刚写入的图片。
//  - 替换图片时用新的文件名，成功后再删旧图，避免中途失败丢掉原图。
//  - 删除记录时一并删除原图与缩略图。
//
//  View 只负责收集草稿，数据一致性都收敛在这里，也方便单元测试。
//

import Foundation
import SwiftData
import UIKit

@MainActor
enum RecordStore {
    enum ImageChange {
        case unchanged
        case replace(UIImage)
        case remove
    }

    enum StoreError: LocalizedError {
        case imageSaveFailed
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .imageSaveFailed: return "图片保存失败，请重试。"
            case .saveFailed: return "记录保存失败，请重试。"
            }
        }
    }

    // MARK: - 新增

    @discardableResult
    static func create(
        _ draft: RecordDraft,
        image: UIImage?,
        context: ModelContext,
        imageStore: ImageStore = .shared
    ) async throws -> MediaItem {
        let identifier = UUID()
        var stored: ImageStore.StoredImage?

        if let image {
            stored = try await writeImage(image, identifier: identifier, store: imageStore)
        }

        let item = draft.makeItem(
            id: identifier,
            imageFileName: stored?.fileName ?? "",
            pixelWidth: stored?.pixelWidth ?? 0,
            pixelHeight: stored?.pixelHeight ?? 0
        )
        context.insert(item)

        do {
            try context.save()
        } catch {
            context.rollback()
            if let name = stored?.fileName {
                imageStore.delete(named: name)
            }
            throw StoreError.saveFailed
        }

        MediaCatalogStore.shared.remember(tags: draft.tags)

        return item
    }

    // MARK: - 编辑

    /// 修改字段与日期；图片按 `imageChange` 处理。
    /// 日期会由 `MediaItem.apply` 归一化到当天零点，因此日历会自动换格。
    static func update(
        _ item: MediaItem,
        with draft: RecordDraft,
        imageChange: ImageChange,
        context: ModelContext,
        imageStore: ImageStore = .shared
    ) async throws {
        let oldFileName = item.imageFileName
        var stored: ImageStore.StoredImage?

        if case .replace(let image) = imageChange {
            stored = try await writeImage(image, identifier: UUID(), store: imageStore)
        }

        item.apply(draft)
        switch imageChange {
        case .unchanged:
            break
        case .replace:
            if let stored {
                item.setImage(
                    fileName: stored.fileName,
                    pixelWidth: stored.pixelWidth,
                    pixelHeight: stored.pixelHeight
                )
            }
        case .remove:
            item.clearImage()
        }

        do {
            try context.save()
        } catch {
            // 未保存的字段改动与图片引用一起回滚，磁盘上的新图也要删掉。
            context.rollback()
            if let name = stored?.fileName {
                imageStore.delete(named: name)
            }
            throw StoreError.saveFailed
        }

        // 新图已经生效，旧图才可以从磁盘移除。
        if case .unchanged = imageChange {} else if !oldFileName.isEmpty {
            imageStore.delete(named: oldFileName)
        }
        MediaCatalogStore.shared.remember(tags: draft.tags)
    }

    // MARK: - 删除

    static func delete(
        _ item: MediaItem,
        context: ModelContext,
        imageStore: ImageStore = .shared
    ) throws {
        let fileName = item.imageFileName

        context.delete(item)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw StoreError.saveFailed
        }

        if !fileName.isEmpty {
            imageStore.delete(named: fileName)
        }
    }

    // MARK: - 图片

    /// UIImage 不能跨线程发送，但这里只做只读压缩，交给后台线程是安全的。
    private struct ImageWriteRequest: @unchecked Sendable {
        let image: UIImage
    }

    private static func writeImage(
        _ image: UIImage,
        identifier: UUID,
        store: ImageStore
    ) async throws -> ImageStore.StoredImage {
        let request = ImageWriteRequest(image: image)
        do {
            return try await Task.detached(priority: .userInitiated) {
                try store.save(request.image, identifier: identifier)
            }.value
        } catch {
            throw StoreError.imageSaveFailed
        }
    }
}
