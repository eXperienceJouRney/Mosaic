//
//  ImageStore.swift
//  Mosaic
//
//  图片落盘层：原图与缩略图分开存放，模型只保存文件名。
//  - 原图：Application Support/Mosaic/Originals（随 iCloud 备份）
//  - 缩略图：Application Support/Mosaic/Thumbnails（可随时重建）
//
//  所有解码都走 CGImageSource 降采样，避免把整张大图读进内存。
//

import Foundation
import ImageIO
import UIKit

final class ImageStore: @unchecked Sendable {
    static let shared = ImageStore()

    enum StoreError: LocalizedError {
        case encodeFailed

        var errorDescription: String? {
            switch self {
            case .encodeFailed: return "图片压缩失败"
            }
        }
    }

    struct StoredImage {
        let fileName: String
        let pixelWidth: Double
        let pixelHeight: Double
    }

    let rootDirectory: URL
    let originalsDirectory: URL
    let thumbnailsDirectory: URL

    private let thumbnailCache = NSCache<NSString, UIImage>()

    /// - Parameter rootDirectory: 传入自定义目录便于测试；默认使用 Application Support/Mosaic。
    init(rootDirectory: URL? = nil) {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        self.rootDirectory = rootDirectory ?? base.appendingPathComponent("Mosaic", isDirectory: true)
        self.originalsDirectory = self.rootDirectory.appendingPathComponent("Originals", isDirectory: true)
        self.thumbnailsDirectory = self.rootDirectory.appendingPathComponent("Thumbnails", isDirectory: true)

        for directory in [self.originalsDirectory, self.thumbnailsDirectory] {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        thumbnailCache.countLimit = 400
        thumbnailCache.totalCostLimit = 64 * 1024 * 1024
    }

    // MARK: - 命名

    func fileName(for identifier: UUID) -> String {
        "\(identifier.uuidString).jpg"
    }

    func contains(named name: String) -> Bool {
        guard !name.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: originalsDirectory.appendingPathComponent(name).path)
    }

    // MARK: - 写入 / 删除

    @discardableResult
    func save(_ image: UIImage, identifier: UUID = UUID()) throws -> StoredImage {
        let name = fileName(for: identifier)
        let originalURL = originalsDirectory.appendingPathComponent(name)

        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw StoreError.encodeFailed
        }
        try data.write(to: originalURL, options: .atomic)

        if let thumbnailData = Self.downsampleJPEG(at: originalURL, maxPixel: 512) {
            try? thumbnailData.write(
                to: thumbnailsDirectory.appendingPathComponent(name),
                options: .atomic
            )
        }

        // 同一个 identifier 覆盖写入时（例如重新生成样例图），旧缓存必须失效。
        thumbnailCache.removeAllObjects()

        return StoredImage(
            fileName: name,
            pixelWidth: Double(image.size.width * image.scale),
            pixelHeight: Double(image.size.height * image.scale)
        )
    }

    func delete(named name: String) {
        guard !name.isEmpty else { return }
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: originalsDirectory.appendingPathComponent(name))
        try? fileManager.removeItem(at: thumbnailsDirectory.appendingPathComponent(name))
        thumbnailCache.removeAllObjects()
    }

    /// 删除所有不在 `names` 中的图片文件，返回删除数量。
    /// 注意：调用前必须确保 `names` 包含数据库中全部 imageFileName。
    @discardableResult
    func prune(keeping names: Set<String>) -> Int {
        let fileManager = FileManager.default
        var removed = 0
        for directory in [originalsDirectory, thumbnailsDirectory] {
            let contents = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            for url in contents where !names.contains(url.lastPathComponent) {
                try? fileManager.removeItem(at: url)
                removed += 1
            }
        }
        thumbnailCache.removeAllObjects()
        return removed
    }

    // MARK: - 读取

    func original(named name: String) -> UIImage? {
        guard !name.isEmpty else { return nil }
        return UIImage(contentsOfFile: originalsDirectory.appendingPathComponent(name).path)
    }

    /// 同步读取缩略图（带内存缓存），只应在主线程以外或小图上使用。
    func thumbnail(named name: String, maxPixel: CGFloat = 360) -> UIImage? {
        guard !name.isEmpty else { return nil }

        let key = cacheKey(named: name, source: "thumbnail", maxPixel: maxPixel)
        if let cached = thumbnailCache.object(forKey: key) { return cached }

        guard let image = loadThumbnailFromDisk(named: name, maxPixel: maxPixel) else { return nil }
        thumbnailCache.setObject(image, forKey: key, cost: image.memoryCost)
        return image
    }

    /// 异步读取缩略图：命中缓存直接返回，否则在后台降采样。
    func thumbnailAsync(named name: String, maxPixel: CGFloat = 360) async -> UIImage? {
        guard !name.isEmpty else { return nil }

        let key = cacheKey(named: name, source: "thumbnail", maxPixel: maxPixel)
        if let cached = thumbnailCache.object(forKey: key) { return cached }

        let thumbnails = thumbnailsDirectory
        let originals = originalsDirectory
        let cache = thumbnailCache

        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let thumbURL = thumbnails.appendingPathComponent(name)
            let sourceURL = FileManager.default.fileExists(atPath: thumbURL.path)
                ? thumbURL
                : originals.appendingPathComponent(name)
            return Self.downsample(at: sourceURL, maxPixel: maxPixel)
        }.value

        guard let image else { return nil }
        cache.setObject(image, forKey: key, cost: image.memoryCost)
        return image
    }

    /// 异步读取原图（按 maxPixel 降采样，仍然保留完整构图）。
    /// 详情页使用这个方法，避免误用到 512px 的缩略图。
    func originalImageAsync(named name: String, maxPixel: CGFloat = 1600) async -> UIImage? {
        guard !name.isEmpty else { return nil }

        let key = cacheKey(named: name, source: "original", maxPixel: maxPixel)
        if let cached = thumbnailCache.object(forKey: key) { return cached }

        let originals = originalsDirectory
        let cache = thumbnailCache

        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            Self.downsample(at: originals.appendingPathComponent(name), maxPixel: maxPixel)
        }.value

        guard let image else { return nil }
        cache.setObject(image, forKey: key, cost: image.memoryCost)
        return image
    }

    // MARK: - 内部

    private func cacheKey(named name: String, source: String, maxPixel: CGFloat) -> NSString {
        "\(name)#\(source)#\(Int(maxPixel))" as NSString
    }

    private func loadThumbnailFromDisk(named name: String, maxPixel: CGFloat) -> UIImage? {
        let thumbURL = thumbnailsDirectory.appendingPathComponent(name)
        let sourceURL = FileManager.default.fileExists(atPath: thumbURL.path)
            ? thumbURL
            : originalsDirectory.appendingPathComponent(name)
        return Self.downsample(at: sourceURL, maxPixel: maxPixel)
    }

    private static func downsample(at url: URL, maxPixel: CGFloat) -> UIImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private static func downsampleJPEG(at url: URL, maxPixel: CGFloat) -> Data? {
        guard let image = downsample(at: url, maxPixel: maxPixel) else { return nil }
        return image.jpegData(compressionQuality: 0.8)
    }
}

private extension UIImage {
    var memoryCost: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
