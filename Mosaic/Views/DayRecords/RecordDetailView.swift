//
//  RecordDetailView.swift
//  Mosaic
//
//  作品详情：完整图片 + 类型 / 日期 / 作者 / 标签 / 个人感受。
//  编辑复用添加记录页；删除走系统确认弹窗，删除成功后连同图片一起清理。
//

import SwiftData
import SwiftUI

struct RecordDetailView: View {
    let item: MediaItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var categoryStore = MediaCategoryStore.shared
    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var isDeleted = false
    @State private var errorMessage = ""
    @State private var isShowingError = false

    var body: some View {
        ZStack {
            Theme.Palette.paper.ignoresSafeArea()

            // 删除后 SwiftData 模型已经销毁，先收起内容，避免在退场动画里再读字段。
            if !isDeleted {
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $isEditing) {
            AddRecordView(editingItem: item)
        }
        .confirmationDialog(
            "删除这条记录？",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: deleteRecord)
            Button("取消", role: .cancel) {}
        } message: {
            Text("「\(item.title)」及其图片将从此设备移除，无法恢复。")
        }
        .alert("无法完成", isPresented: $isShowingError) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 内容

    private var content: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: "记录",
                subtitle: MosaicCalendar.fullDateTitle(item.recordDate),
                backIdentifier: "detailBackButton",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    RecordPhotoView(
                        fileName: item.imageFileName,
                        symbolName: category.symbolName
                    )
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.Detail.photoHeight)
                        .clipShape(
                            RoundedRectangle(cornerRadius: Theme.Detail.photoCorner, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Detail.photoCorner, style: .continuous)
                                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
                        }

                    metaRow
                        .padding(.top, Theme.Detail.contentTop)

                    Text(item.title)
                        .font(Theme.Typography.detailTitle)
                        .tracking(Theme.Tracking.detailTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Theme.Detail.titleSpacing)
                        .accessibilityIdentifier("detailTitle")

                    if !creatorText.isEmpty {
                        creatorRow
                            .padding(.top, Theme.Detail.metaSpacing)
                    }

                    if !item.tags.isEmpty {
                        tagRow
                            .padding(.top, Theme.Detail.sectionSpacing)
                    }

                    if !noteText.isEmpty {
                        noteSection
                            .padding(.top, Theme.Detail.sectionSpacing)
                    }

                    actions
                        .padding(.top, Theme.Detail.actionTop)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, Theme.Detail.contentPadding)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - 元信息

    private var metaRow: some View {
        HStack(spacing: 8) {
            Text("\(category.title) · \(MosaicCalendar.fullDateTitle(item.recordDate))")
                .font(Theme.Typography.detailMeta)
                .foregroundStyle(Theme.Palette.muted)
                .accessibilityIdentifier("detailMeta")

            Spacer(minLength: 0)

            if item.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < item.rating ? "star.fill" : "star")
                            .font(.system(size: 8, weight: .regular))
                    }
                }
                .foregroundStyle(Theme.Palette.muted.opacity(0.75))
                .accessibilityLabel("\(item.rating) 星")
            }
        }
    }

    private var creatorRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(category.creatorFieldLabel)
                .font(Theme.Typography.formLabel)
                .foregroundStyle(Theme.Palette.muted)

            Text(creatorText)
                .font(Theme.Typography.detailCreator)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("detailCreator")
    }

    private var tagRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Detail.tagSpacing) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(Theme.Typography.tag)
                        .foregroundStyle(Theme.Palette.filterText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .overlay {
                            Capsule().strokeBorder(Theme.Palette.tagBorder, lineWidth: 1)
                        }
                }
            }
        }
        .accessibilityIdentifier("detailTags")
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("个人感受")
                .font(Theme.Typography.formLabel)
                .foregroundStyle(Theme.Palette.muted)

            Text(noteText)
                .font(Theme.Typography.detailBody)
                .foregroundStyle(Theme.Palette.ink)
                .lineSpacing(Theme.Detail.noteLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("detailNote")
        }
    }

    // MARK: - 操作

    private var actions: some View {
        VStack(spacing: Theme.Detail.actionSpacing) {
            Button {
                isEditing = true
            } label: {
                Text("编辑记录")
                    .font(Theme.Typography.detailAction)
                    .foregroundStyle(Theme.Palette.onAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Capsule().fill(Theme.Palette.accent))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("editRecordButton")

            Button {
                isConfirmingDelete = true
            } label: {
                Text("删除记录")
                    .font(Theme.Typography.deleteAction)
                    .foregroundStyle(Theme.Palette.danger)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("deleteRecordButton")
        }
    }

    // MARK: - 派生文本

    private var category: MediaCategory {
        categoryStore.category(for: item.categoryID)
    }

    private var creatorText: String {
        item.creator.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var noteText: String {
        item.note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - 删除

    private func deleteRecord() {
        isDeleted = true

        do {
            try RecordStore.delete(item, context: modelContext)
            dismiss()
        } catch {
            isDeleted = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "删除失败，请重试。"
            isShowingError = true
        }
    }
}

#Preview("记录详情") {
    let container = MosaicContainer.makeInMemory()
    let context = ModelContext(container)
    let item = MediaItem(
        title: "海边的卡夫卡",
        creator: "村上春树",
        kind: .book,
        rating: 4,
        note: "十五岁的少年拖着影子走进四国。读到最后一页时，窗外正好下雨。",
        recordDate: .now,
        tags: ["文学", "重读", "non fiction"]
    )
    context.insert(item)

    return NavigationStack {
        RecordDetailView(item: item)
    }
    .modelContainer(container)
}
