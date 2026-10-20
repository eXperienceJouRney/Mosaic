//
//  CategoryAddSheet.swift
//  Mosaic
//
//  筛选栏编辑态里的「新建分类」面板：只收一个标题，
//  重名与空标题就地拦截，添加成功后回到筛选栏继续管理。
//

import SwiftUI

struct CategoryAddSheet: View {
    /// 已有分类标题（含固定的「全部」），用来拦截重名。
    let existingTitles: [String]
    /// 返回 false 表示最终没能加入（例如与刚创建的分类撞名），面板保持打开。
    var onAdd: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var didAttemptSubmit = false
    @State private var didFailToAdd = false
    @FocusState private var isFocused: Bool

    private var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicate: Bool {
        existingTitles.contains {
            $0.compare(normalizedTitle, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var canAdd: Bool {
        !normalizedTitle.isEmpty
            && !isDuplicate
            && normalizedTitle.count <= Theme.Filter.maxTitleLength
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Filter.sheetSectionSpacing) {
            header
            nameField
            errorHint
            actions
        }
        .padding(.horizontal, Theme.Filter.sheetHorizontal)
        .padding(.top, Theme.Filter.sheetTop)
        .padding(.bottom, Theme.Filter.sheetBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Palette.paper)
        .task {
            isFocused = true
        }
    }

    // MARK: - 内容

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Filter.sheetTitleSpacing) {
            Text("新建分类")
                .font(Theme.Typography.sheetTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)

            Text("新分类会出现在筛选栏和记录类型里。")
                .font(Theme.Typography.formLabel)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var nameField: some View {
        TextField("分类名称，例如：纪录片", text: $title)
            .font(Theme.Typography.formField)
            .foregroundStyle(Theme.Palette.ink)
            .focused($isFocused)
            .submitLabel(.done)
            .onSubmit(add)
            .padding(Theme.Filter.sheetFieldPadding)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                    .fill(Theme.Palette.fieldBackground)
            }
            .accessibilityIdentifier("categoryNameField")
            .accessibilityLabel("分类名称")
    }

    private var errorText: String? {
        guard didAttemptSubmit else { return nil }
        if didFailToAdd { return "无法添加这个分类" }
        if normalizedTitle.isEmpty { return "请输入分类名称" }
        if isDuplicate { return "名称已被占用" }
        if normalizedTitle.count > Theme.Filter.maxTitleLength {
            return "名称最多 \(Theme.Filter.maxTitleLength) 个字"
        }
        return nil
    }

    @ViewBuilder
    private var errorHint: some View {
        if let errorText {
            Text(errorText)
                .font(Theme.Typography.formLabel)
                .foregroundStyle(Theme.Palette.danger)
        }
    }

    private var actions: some View {
        HStack(spacing: Theme.Filter.sheetActionSpacing) {
            Spacer(minLength: 0)

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
            .accessibilityIdentifier("categoryAddCancelButton")

            Button(action: add) {
                Text("添加")
                    .font(Theme.Typography.formActionEmphasis)
                    .foregroundStyle(Theme.Palette.onAccent)
                    .padding(.horizontal, Theme.Form.saveHorizontal)
                    .frame(minWidth: Theme.Form.saveMinWidth, minHeight: Theme.Form.actionHitHeight)
                    .background(Capsule().fill(Theme.Palette.accent))
                    .opacity(canAdd ? 1 : 0.24)
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
            .accessibilityIdentifier("categoryAddConfirmButton")
            .accessibilityLabel("添加分类")
        }
    }

    // MARK: - 提交

    private func add() {
        didAttemptSubmit = true
        didFailToAdd = false
        guard canAdd else { return }

        guard onAdd(normalizedTitle) else {
            didFailToAdd = true
            return
        }
        dismiss()
    }
}

#Preview {
    CategoryAddSheet(existingTitles: ["全部", "电影", "书籍"], onAdd: { _ in true })
}
