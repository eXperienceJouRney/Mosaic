//
//  RecordKindPicker.swift
//  Mosaic
//
//  添加记录页的分类选择：与首页筛选栏同一套胶囊语言，
//  但这里是单选，必须始终有一个分类；选项来自 MediaCategoryStore，
//  因此筛选栏里新建 / 删除的分类会立刻反映到这里。
//

import SwiftUI

struct RecordKindPicker: View {
    @Binding var categoryID: String

    @State private var store = MediaCategoryStore.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Filter.pillSpacing) {
                ForEach(store.categories) { category in
                    chip(for: category)
                }
            }
            .padding(.horizontal, 1)
        }
        .accessibilityIdentifier("recordKindPicker")
        .onAppear(perform: normalizeSelection)
    }

    /// 记录原本的分类若已被删除，回退到第一个可用分类，避免出现没有选中项的表单。
    private func normalizeSelection() {
        guard !store.contains(id: categoryID), let first = store.categories.first else { return }
        categoryID = first.id
    }

    private func chip(for category: MediaCategory) -> some View {
        let isActive = category.id == categoryID

        return Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                categoryID = category.id
            }
        } label: {
            Text(category.title)
                .font(Theme.Typography.filter)
                .foregroundStyle(isActive ? Theme.Palette.onAccent : Theme.Palette.filterText)
                .padding(.horizontal, Theme.Filter.pillHorizontal)
                .padding(.vertical, Theme.Filter.pillVertical)
                .background {
                    Capsule().fill(isActive ? Theme.Palette.accent : Color.clear)
                }
                .overlay {
                    Capsule().strokeBorder(
                        isActive ? Theme.Palette.accent : Theme.Palette.filterBorder,
                        lineWidth: 1
                    )
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("kind-\(category.id)")
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview {
    RecordKindPickerPreviewHost()
}

private struct RecordKindPickerPreviewHost: View {
    @State private var categoryID = MediaKind.movie.rawValue

    var body: some View {
        RecordKindPicker(categoryID: $categoryID)
            .padding(.horizontal, Theme.Form.horizontalPadding)
            .background(Theme.Palette.paper)
    }
}
