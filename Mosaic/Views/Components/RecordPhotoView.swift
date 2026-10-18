//
//  RecordPhotoView.swift
//  Mosaic
//
//  详情页的大图：从原图降采样，scaledToFit 保留完整构图。
//  与日历缩略图不同，这里不裁切，横向图片也能完整显示。
//

import SwiftUI

struct RecordPhotoView: View {
    let fileName: String
    var symbolName: String?
    var maxPixel: CGFloat = 1600

    @State private var image: UIImage?
    @State private var loadedFileName: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Theme.Palette.fieldBackground

            if let image, loadedFileName == fileName {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if fileName.isEmpty {
                placeholderSymbol
            } else if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.Palette.muted)
            }
        }
        .task(id: fileName) {
            await load()
        }
    }

    private var placeholderSymbol: some View {
        Image(systemName: symbolName ?? MediaKind.other.symbolName)
            .font(.system(size: 34, weight: .light))
            .foregroundStyle(Theme.Palette.muted.opacity(0.5))
    }

    @MainActor
    private func load() async {
        if loadedFileName != fileName {
            image = nil
            loadedFileName = nil
        }

        guard !fileName.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        let loaded = await ImageStore.shared.originalImageAsync(named: fileName, maxPixel: maxPixel)
        if Task.isCancelled { return }

        loadedFileName = fileName
        image = loaded
        isLoading = false
    }
}

#Preview {
    RecordPhotoView(fileName: "", symbolName: MediaKind.book.symbolName)
        .frame(height: Theme.Detail.photoHeight)
        .background(Theme.Palette.paper)
}
