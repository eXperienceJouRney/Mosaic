//
//  YearPickerView.swift
//  Mosaic
//
//  轻量的年份选择器：‹ 年份页 › + 3×4 年份网格，翻页步长 12 年。
//  与月份选择器同一套版式，避免为「选一年」单独造一种面板。
//

import SwiftUI

struct YearPickerView: View {
    let selection: Int
    var onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pageStart: Int

    private static let pageSize = 12
    private static let earliestYear = 1

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Picker.columnSpacing),
        count: 3
    )

    init(selection: Int, onSelect: @escaping (Int) -> Void) {
        self.selection = selection
        self.onSelect = onSelect
        _pageStart = State(initialValue: Self.pageStart(containing: selection))
    }

    var body: some View {
        VStack(spacing: Theme.Picker.sectionSpacing) {
            pageBar

            LazyVGrid(columns: columns, spacing: Theme.Picker.rowSpacing) {
                ForEach(pageStart..<(pageStart + Self.pageSize), id: \.self) { year in
                    yearButton(year)
                }
            }

            footer
        }
        .padding(.horizontal, Theme.Spacing.screenPadding + 6)
        .padding(.top, Theme.Picker.topPadding)
        .padding(.bottom, Theme.Picker.bottomPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Palette.paper)
    }

    // MARK: - 翻页

    private var pageBar: some View {
        HStack(spacing: 10) {
            pageStepButton(
                symbol: "chevron.left",
                label: "前十二年",
                identifier: "previousYearsPage",
                action: { stepPage(-Self.pageSize) }
            )

            Spacer(minLength: 0)

            Text("\(pageStart) – \(pageStart + Self.pageSize - 1)")
                .font(Theme.Typography.pickerYear)
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.ink)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            pageStepButton(
                symbol: "chevron.right",
                label: "后十二年",
                identifier: "nextYearsPage",
                action: { stepPage(Self.pageSize) }
            )
        }
        .frame(height: Theme.Picker.yearBarHeight)
    }

    private func pageStepButton(
        symbol: String,
        label: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Palette.iconButton)
                .frame(width: 30, height: 30)
                .background(Theme.Palette.soft, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(label)
    }

    // MARK: - 年份网格

    private func yearButton(_ year: Int) -> some View {
        let isSelected = year == selection
        let isCurrent = year == MosaicCalendar.year(of: .now)

        return Button {
            onSelect(year)
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Text(String(year))
                    .font(isSelected ? Theme.Typography.pickerMonthSelected : Theme.Typography.pickerMonth)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if isCurrent && !isSelected {
                    Circle()
                        .fill(Theme.Palette.accent.opacity(0.55))
                        .frame(width: 3, height: 3)
                }
            }
            .foregroundStyle(isSelected ? Theme.Palette.onAccent : Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Picker.monthHeight)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous)
                    .fill(isSelected ? Theme.Palette.accent : Theme.Palette.soft)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("year-\(year)")
        .accessibilityLabel(String(year))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - 底部操作

    private var footer: some View {
        HStack {
            Button {
                onSelect(MosaicCalendar.year(of: .now))
                dismiss()
            } label: {
                Text("回到今年")
                    .font(Theme.Typography.pickerAction)
                    .foregroundStyle(Theme.Palette.filterText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background {
                        Capsule().fill(Theme.Palette.soft)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("currentYearButton")
            .accessibilityLabel("回到今年")

            Spacer(minLength: 0)

            Button("取消") {
                dismiss()
            }
            .font(Theme.Typography.pickerAction)
            .foregroundStyle(Theme.Palette.muted)
            .buttonStyle(.plain)
            .accessibilityLabel("取消选择年份")
        }
    }

    // MARK: - 计算

    private func stepPage(_ delta: Int) {
        let next = max(Self.earliestYear, pageStart + delta)
        guard next != pageStart else { return }
        withAnimation(.easeInOut(duration: 0.16)) {
            pageStart = next
        }
    }

    /// 年份页按 12 年切分，保证选中项一开始就在可见页里。
    private static func pageStart(containing year: Int) -> Int {
        max(earliestYear, (year / pageSize) * pageSize)
    }
}

#Preview {
    YearPickerView(selection: 2026) { _ in }
        .frame(height: Theme.Picker.sheetHeight)
        .background(Theme.Palette.paper)
}
