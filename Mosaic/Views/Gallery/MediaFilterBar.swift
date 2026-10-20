//
//  MediaFilterBar.swift
//  Mosaic
//
//  横向滚动的分类筛选栏：全部 + 当前分类（默认 电影 / 书籍 / 漫画 / 音乐 / 播客 / 游戏 / 其他）。
//  选中项为深色胶囊，其余为细描边胶囊。
//
//  长按任意分类进入编辑态：胶囊变成虚线并出现删除标记，
//  行尾多出「＋ 新分类」与「完成」，可以增删分类；删除只影响筛选与表单选项，
//  已有记录不会被删除，只会回退显示成「其他」。
//

import SwiftUI
import UIKit

struct MediaFilterBar: View {
    @Binding var selection: String?

    @State private var store = MediaCategoryStore.shared
    @State private var isEditing = false
    @State private var isAddingCategory = false
    @State private var pendingDeletion: MediaCategory?
    @State private var isConfirmingDeletion = false
    @State private var alertMessage = ""
    @State private var isShowingAlert = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Filter.pillSpacing) {
                    allPill

                    ForEach(store.categories) { category in
                        categoryPill(category)
                    }

                    if isEditing {
                        addCategoryPill
                        donePill
                    }
                }
                .padding(.horizontal, 1)
                .animation(.easeInOut(duration: Theme.Filter.editAnimationDuration), value: isEditing)
            }
            .onChange(of: isEditing) { _, editing in
                // 分类一多，新出现的操作按钮可能被挤到屏幕外，进入编辑态时滚到行尾。
                guard editing else { return }
                withAnimation(.easeInOut(duration: Theme.Filter.editAnimationDuration)) {
                    proxy.scrollTo(Theme.Filter.addPillID, anchor: .trailing)
                }
            }
        }
        .padding(.bottom, Theme.Spacing.filterBottom)
        .onChange(of: store.categories) { _, categories in
            // 当前选中的分类被删掉时回到「全部」，避免出现「筛选着不存在的分类」。
            if let selection, !categories.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
        .alert("删除分类", isPresented: $isConfirmingDeletion, presenting: pendingDeletion) { category in
            Button("删除", role: .destructive) {
                delete(category)
            }
            Button("取消", role: .cancel) {
                pendingDeletion = nil
            }
        } message: { category in
            Text("「\(category.title)」下的记录不会被删除，仍可在「全部」中查看。")
        }
        .alert("无法删除", isPresented: $isShowingAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isAddingCategory) {
            CategoryAddSheet(existingTitles: ["全部"] + store.categories.map(\.title)) { title in
                store.add(title: title) != nil
            }
            .presentationDetents([.height(Theme.Filter.sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.Radius.sheet)
            .presentationBackground(Theme.Palette.paper)
        }
    }

    // MARK: - 全部

    private var allPill: some View {
        pillLabel("全部", isActive: selection == nil, isEditing: false)
            .contentShape(Capsule())
            .onTapGesture {
                selection = nil
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("filter-all")
            .accessibilityLabel("全部")
            .accessibilityAddTraits(selection == nil ? [.isButton, .isSelected] : [.isButton])
    }

    // MARK: - 分类

    @ViewBuilder
    private func categoryPill(_ category: MediaCategory) -> some View {
        let isActive = selection == category.id

        if isEditing {
            editingPill(category, isActive: isActive)
        } else {
            pillLabel(category.title, isActive: isActive, isEditing: false)
                .contentShape(Capsule())
                .onTapGesture {
                    selection = category.id
                }
                .onLongPressGesture(minimumDuration: Theme.Filter.longPressDuration) {
                    enterEditing()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("filter-\(category.id)")
                .accessibilityLabel(category.title)
                .accessibilityHint("长按管理分类")
                .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : [.isButton])
        }
    }

    private func editingPill(_ category: MediaCategory, isActive: Bool) -> some View {
        HStack(spacing: Theme.Filter.deleteBadgeSpacing) {
            Text(category.title)
                .font(Theme.Typography.filter)
                .foregroundStyle(isActive ? Theme.Palette.onAccent : Theme.Palette.filterText)

            Button {
                requestDeletion(of: category)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: Theme.Filter.deleteBadgeSize, weight: .semibold))
                    .foregroundStyle(isActive ? Theme.Palette.onAccent.opacity(0.8) : Theme.Palette.danger)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("filter-delete-\(category.id)")
            .accessibilityLabel("删除分类 \(category.title)")
        }
        .padding(.horizontal, Theme.Filter.pillHorizontal)
        .padding(.vertical, Theme.Filter.pillVertical)
        .background {
            Capsule().fill(isActive ? Theme.Palette.accent : Color.clear)
        }
        .overlay {
            Capsule().strokeBorder(
                isActive ? Theme.Palette.accent : Theme.Palette.danger.opacity(0.45),
                style: StrokeStyle(lineWidth: 1, dash: Theme.Filter.editDash)
            )
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - 编辑态操作

    private var addCategoryPill: some View {
        Button {
            isAddingCategory = true
        } label: {
            HStack(spacing: Theme.Filter.addIconSpacing) {
                Image(systemName: "plus")
                    .font(.system(size: Theme.Filter.addIconSize, weight: .semibold))

                Text("新分类")
                    .font(Theme.Typography.filter)
            }
            .foregroundStyle(Theme.Palette.danger)
            .padding(.horizontal, Theme.Filter.pillHorizontal)
            .padding(.vertical, Theme.Filter.pillVertical)
            .overlay {
                Capsule().strokeBorder(
                    Theme.Palette.danger.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1, dash: Theme.Filter.editDash)
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("filter-add-category")
        .accessibilityLabel("新建分类")
        .id(Theme.Filter.addPillID)
    }

    private var donePill: some View {
        Button {
            withAnimation(.easeInOut(duration: Theme.Filter.editAnimationDuration)) {
                isEditing = false
            }
        } label: {
            Text("完成")
                .font(Theme.Typography.filter)
                .foregroundStyle(Theme.Palette.muted)
                .padding(.horizontal, Theme.Filter.pillHorizontal)
                .padding(.vertical, Theme.Filter.pillVertical)
                .overlay {
                    Capsule().strokeBorder(Theme.Palette.filterBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("filter-edit-done")
        .accessibilityLabel("完成分类管理")
    }

    // MARK: - 胶囊外观

    private func pillLabel(_ title: String, isActive: Bool, isEditing: Bool) -> some View {
        Text(title)
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
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: isEditing ? Theme.Filter.editDash : []
                    )
                )
            }
    }

    // MARK: - 增删

    private func enterEditing() {
        guard !isEditing else { return }

        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeInOut(duration: Theme.Filter.editAnimationDuration)) {
            isEditing = true
        }
    }

    private func requestDeletion(of category: MediaCategory) {
        guard store.canDelete else {
            alertMessage = "至少保留一个分类，才能继续筛选记录。"
            isShowingAlert = true
            return
        }

        guard store.isDeletable(category) else {
            alertMessage = "「其他」会承接已删除分类的记录，不能删除。"
            isShowingAlert = true
            return
        }

        pendingDeletion = category
        isConfirmingDeletion = true
    }

    private func delete(_ category: MediaCategory) {
        if selection == category.id {
            selection = nil
        }
        store.delete(category)
        pendingDeletion = nil
    }
}

#Preview {
    MediaFilterBarPreviewHost()
}

private struct MediaFilterBarPreviewHost: View {
    @State private var selection: String?

    var body: some View {
        MediaFilterBar(selection: $selection)
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .background(Theme.Palette.paper)
    }
}
