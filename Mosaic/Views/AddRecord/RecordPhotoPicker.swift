//
//  RecordPhotoPicker.swift
//  Mosaic
//
//  使用系统 PhotosPicker（不需要相册权限弹窗）选择一张图片。
//  取消选择时 PhotosPicker 自己关闭，绑定值保持不变，表单原样留在原地。
//

import PhotosUI
import SwiftUI

struct RecordPhotoPicker: View {
    @Binding var selection: PhotosPickerItem?
    let image: UIImage?
    var isLoading: Bool = false
    var onRemove: () -> Void = {}

    private let corner = RoundedRectangle(cornerRadius: Theme.Form.photoCorner, style: .continuous)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: $selection, matching: .images) {
                photoContent
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("photoPickerButton")
            .accessibilityLabel(image == nil ? "选择图片" : "更换图片")

            if image != nil {
                removeButton
            }
        }
    }

    // MARK: - 内容

    private var photoContent: some View {
        ZStack {
            Theme.Palette.fieldBackground

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                emptyPrompt
            }

            if isLoading {
                loadingOverlay
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Theme.Form.photoHeight)
        .clipped()
        .clipShape(corner)
        .overlay {
            corner.strokeBorder(Theme.Palette.hairline, lineWidth: 1)
        }
        .contentShape(corner)
    }

    private var emptyPrompt: some View {
        VStack(spacing: 7) {
            Image(systemName: "photo")
                .font(.system(size: Theme.Form.photoIconSize, weight: .light))
            Text("选择图片")
                .font(Theme.Typography.formPhotoPrompt)
        }
        .foregroundStyle(Theme.Palette.muted)
    }

    private var loadingOverlay: some View {
        ZStack {
            Theme.Palette.fieldBackground.opacity(0.72)
            ProgressView()
                .tint(Theme.Palette.muted)
        }
    }

    private var removeButton: some View {
        Button {
            onRemove()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Palette.onAccent)
                .frame(
                    width: Theme.Form.photoRemoveSize,
                    height: Theme.Form.photoRemoveSize
                )
                .background(Circle().fill(Theme.Palette.accent.opacity(0.78)))
        }
        .buttonStyle(.plain)
        .padding(Theme.Form.photoRemovePadding)
        .accessibilityIdentifier("removePhotoButton")
        .accessibilityLabel("移除图片")
    }
}

#Preview {
    RecordPhotoPickerPreviewHost()
}

private struct RecordPhotoPickerPreviewHost: View {
    @State private var selection: PhotosPickerItem?

    var body: some View {
        RecordPhotoPicker(selection: $selection, image: nil)
            .padding(Theme.Form.horizontalPadding)
            .background(Theme.Palette.paper)
    }
}
