//
//  RecordThumbnail.swift
//  Mosaic
//
//  按文件名异步加载缩略图。解码在后台完成，命中缓存时不产生磁盘读取。
//  没有图片时显示中性色块与类型符号，不使用渐变或剪影装饰。
//

import SwiftUI

struct RecordThumbnail: View {
    let fileName: String
    var symbolName: String?
    var maxPixel: CGFloat = 360

    @State private var image: UIImage?
    @State private var loadedFileName: String?

    var body: some View {
        ZStack {
            placeholder

            // 只有加载结果与当前文件名匹配时才显示，避免换月 / 换分类时
            // 短暂看到上一个月的图片。
            if let image, loadedFileName == fileName {
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
        }
        .task(id: fileName) {
            await load()
        }
    }

    private var placeholder: some View {
        GeometryReader { proxy in
            ZStack {
                Theme.Palette.thumbPlaceholder

                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: min(proxy.size.width, proxy.size.height) * 0.3, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
        }
    }

    @MainActor
    private func load() async {
        if loadedFileName != fileName {
            image = nil
            loadedFileName = nil
        }

        guard !fileName.isEmpty else {
            image = nil
            return
        }

        let loaded = await ImageStore.shared.thumbnailAsync(named: fileName, maxPixel: maxPixel)
        if Task.isCancelled { return }

        loadedFileName = fileName
        image = loaded
    }
}
