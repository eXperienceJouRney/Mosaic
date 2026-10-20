//
//  AddRecordView.swift
//  Mosaic
//
//  添加 / 编辑记录共用同一张表单：一张图、七个类型、少量可选字段。
//  - 新建：图片先落盘，再插入 SwiftData，首页 @Query 自动放进对应日期。
//  - 编辑：用草稿回填，保存后才写回模型；取消不会改动原记录。
//
//  数据一致性（图片文件、回滚、旧图清理）统一交给 RecordStore。
//

import PhotosUI
import SwiftData
import SwiftUI

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// 传入已有记录即进入编辑模式；nil 表示新建。
    let editingItem: MediaItem?

    @State private var draft: RecordDraft
    @State private var categoryStore = MediaCategoryStore.shared
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoadingPhoto = false
    @State private var photoLoadToken = UUID()
    @State private var didLoadEditingPhoto = false
    @State private var photoChanged = false
    @State private var isSaving = false
    @State private var errorMessage = ""
    @State private var isShowingError = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case creator
        case note
        case tags
    }

    init(editingItem: MediaItem? = nil) {
        self.editingItem = editingItem
        var initial = editingItem.map { RecordDraft(item: $0) } ?? RecordDraft()

        // 记录所属分类可能已经在筛选栏里被删除，此时回退到第一个可用分类，
        // 保证表单里始终有选中的类型。
        let store = MediaCategoryStore.shared
        if !store.contains(id: initial.categoryID) {
            initial.categoryID = store.categories.first?.id ?? MediaKind.movie.rawValue
        }

        _draft = State(initialValue: initial)
    }

    private var isEditing: Bool { editingItem != nil }

    /// 当前分类的展示信息，自定义分类由 MediaCategory 提供通用文案。
    private var category: MediaCategory {
        categoryStore.category(for: draft.categoryID)
    }

    private var canSave: Bool {
        draft.isValid && !isSaving && !isLoadingPhoto
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Form.sectionSpacing) {
                    RecordPhotoPicker(
                        selection: $pickerItem,
                        image: selectedImage,
                        isLoading: isLoadingPhoto,
                        onRemove: removePhoto
                    )

                    RecordKindPicker(categoryID: $draft.categoryID)

                    titleField

                    fieldRows

                    noteField
                }
                .padding(.horizontal, Theme.Form.horizontalPadding)
                .padding(.top, Theme.Form.topPadding)
                .padding(.bottom, Theme.Form.bottomPadding)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Theme.Palette.paper.ignoresSafeArea())
        .tint(Theme.Palette.accent)
        .task {
            await loadEditingPhotoIfNeeded()
        }
        .onChange(of: pickerItem) { _, newItem in
            loadPhoto(from: newItem)
        }
        .alert("无法完成", isPresented: $isShowingError) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 顶栏

    private var topBar: some View {
        ZStack {
            Text(isEditing ? "编辑记录" : "新记录")
                .font(Theme.Typography.formPageTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Text("取消")
                        .font(Theme.Typography.formAction)
                        .foregroundStyle(Theme.Palette.muted)
                        .frame(height: Theme.Form.actionHitHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("addRecordCancelButton")
                .accessibilityLabel(isEditing ? "取消编辑" : "取消添加")

                Spacer(minLength: 12)

                saveButton
            }
        }
        .padding(.horizontal, Theme.Form.horizontalPadding)
        .padding(.vertical, Theme.Form.topBarVertical)
    }

    private var saveButton: some View {
        Button(action: save) {
            Group {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Theme.Palette.onAccent)
                } else {
                    Text("保存")
                        .font(Theme.Typography.formActionEmphasis)
                }
            }
            .foregroundStyle(Theme.Palette.onAccent)
            .padding(.horizontal, Theme.Form.saveHorizontal)
            .frame(minWidth: Theme.Form.saveMinWidth, minHeight: Theme.Form.actionHitHeight)
            .background(Capsule().fill(Theme.Palette.accent))
            .opacity(canSave ? 1 : 0.24)
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .accessibilityIdentifier("saveRecordButton")
        .accessibilityLabel("保存记录")
        .accessibilityHint("作品名称未填写时不可保存")
    }

    // MARK: - 字段

    private var titleField: some View {
        VStack(alignment: .leading, spacing: Theme.Form.fieldSpacing) {
            fieldLabel(category.titleFieldLabel)

            TextField(category.titleFieldPlaceholder, text: $draft.title)
                .font(Theme.Typography.formTitleField)
                .foregroundStyle(Theme.Palette.ink)
                .focused($focusedField, equals: .title)
                .submitLabel(.done)
                .accessibilityIdentifier("titleField")
                .padding(.bottom, Theme.Form.fieldSpacing)
                .overlay(alignment: .bottom) { hairline }
        }
    }

    private var fieldRows: some View {
        VStack(spacing: 0) {
            creatorRow
            hairline
            dateRow
            hairline
            tagsRow
        }
    }

    private var creatorRow: some View {
        HStack(spacing: 8) {
            rowLabel(category.creatorFieldLabel)

            TextField("选填", text: $draft.creator)
                .font(Theme.Typography.formField)
                .foregroundStyle(Theme.Palette.ink)
                .focused($focusedField, equals: .creator)
                .submitLabel(.next)
                .accessibilityIdentifier("creatorField")
        }
        .padding(.vertical, Theme.Form.rowVertical)
    }

    private var dateRow: some View {
        HStack(spacing: 8) {
            rowLabel("记录日期")

            Spacer(minLength: 0)

            DatePicker(
                "记录日期",
                selection: $draft.recordDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .accessibilityIdentifier("recordDatePicker")
            .accessibilityLabel("记录日期")
        }
        .padding(.vertical, Theme.Form.rowVertical)
    }

    private var tagsRow: some View {
        HStack(spacing: 8) {
            rowLabel("标签")

            TextField("用逗号分隔，选填", text: $draft.tagsText)
                .font(Theme.Typography.formField)
                .foregroundStyle(Theme.Palette.ink)
                .focused($focusedField, equals: .tags)
                .submitLabel(.done)
                .accessibilityIdentifier("tagsField")
        }
        .padding(.vertical, Theme.Form.rowVertical)
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: Theme.Form.fieldSpacing) {
            fieldLabel("个人感受")

            ZStack(alignment: .topLeading) {
                if draft.note.isEmpty {
                    Text("选填，写下一点当时的感受")
                        .font(Theme.Typography.formField)
                        .foregroundStyle(Theme.Palette.fieldPlaceholder)
                        .padding(.horizontal, Theme.Form.notePadding)
                        .padding(.vertical, Theme.Form.notePadding)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $draft.note)
                    .font(Theme.Typography.formField)
                    .foregroundStyle(Theme.Palette.ink)
                    .scrollContentBackground(.hidden)
                    .focused($focusedField, equals: .note)
                    .padding(Theme.Form.noteTextInset)
                    .frame(height: Theme.Form.noteHeight)
                    .accessibilityIdentifier("noteEditor")
            }
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                    .fill(Theme.Palette.fieldBackground)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.formLabel)
            .foregroundStyle(Theme.Palette.muted)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.formLabel)
            .foregroundStyle(Theme.Palette.muted)
            .frame(width: Theme.Form.rowLabelWidth, alignment: .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Theme.Palette.hairline)
            .frame(height: 1)
    }

    // MARK: - 图片

    /// 编辑模式先把已有图片显示出来；它只是预览，用户不换图就不会重新编码。
    private func loadEditingPhotoIfNeeded() async {
        guard let editingItem, !didLoadEditingPhoto else { return }
        didLoadEditingPhoto = true

        guard !editingItem.imageFileName.isEmpty, !photoChanged else { return }

        isLoadingPhoto = true
        let image = await ImageStore.shared.thumbnailAsync(
            named: editingItem.imageFileName,
            maxPixel: 1200
        )
        guard !Task.isCancelled else { return }

        if !photoChanged {
            selectedImage = image
        }
        isLoadingPhoto = false
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        let token = UUID()
        photoLoadToken = token
        isLoadingPhoto = true

        Task { @MainActor in
            defer {
                if photoLoadToken == token {
                    isLoadingPhoto = false
                }
            }

            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw PhotoLoadError.unreadable
                }
                // 用户快速换图时，只接受最后一次选择的结果。
                guard photoLoadToken == token else { return }
                selectedImage = image
                photoChanged = true
            } catch {
                guard photoLoadToken == token else { return }
                presentError("无法读取所选图片，请换一张再试。")
            }
        }
    }

    private func removePhoto() {
        photoLoadToken = UUID()
        pickerItem = nil
        selectedImage = nil
        isLoadingPhoto = false
        photoChanged = true
    }

    // MARK: - 保存

    private func save() {
        guard canSave else { return }

        focusedField = nil
        isSaving = true

        let draft = draft
        let image = selectedImage
        let imageChange: RecordStore.ImageChange = {
            guard isEditing, photoChanged else { return .unchanged }
            guard let image else { return .remove }
            return .replace(image)
        }()

        Task { @MainActor in
            do {
                if let editingItem {
                    try await RecordStore.update(
                        editingItem,
                        with: draft,
                        imageChange: imageChange,
                        context: modelContext
                    )
                } else {
                    try await RecordStore.create(
                        draft,
                        image: image,
                        context: modelContext
                    )
                }

                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                presentError((error as? LocalizedError)?.errorDescription ?? "保存失败，请重试。")
            }
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }

    private enum PhotoLoadError: Error {
        case unreadable
    }
}

#Preview("添加记录") {
    AddRecordView()
        .modelContainer(MosaicContainer.makeInMemory())
}

#Preview("编辑记录") {
    let container = MosaicContainer.makeInMemory()
    let context = ModelContext(container)
    let item = MediaItem(
        title: "花样年华",
        creator: "王家卫",
        kind: .movie,
        note: "那些消逝了的岁月。",
        recordDate: .now,
        tags: ["香港", "重看"]
    )
    context.insert(item)

    return AddRecordView(editingItem: item)
        .modelContainer(container)
}
