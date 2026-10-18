//
//  MonthPickerView.swift
//  Mosaic
//
//  轻量的月份选择器：年份左右切换 + 3×4 月份网格。
//  只负责挑选一个「月首日期」，日历本身仍由 MonthGrid 统一生成。
//

import SwiftUI

struct MonthPickerView: View {
    let selection: Date
    var onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayedYear: Int

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Picker.columnSpacing),
        count: 3
    )

    init(selection: Date, onSelect: @escaping (Date) -> Void) {
        self.selection = selection
        self.onSelect = onSelect
        _displayedYear = State(initialValue: MosaicCalendar.year(of: selection))
    }

    var body: some View {
        VStack(spacing: Theme.Picker.sectionSpacing) {
            yearBar

            LazyVGrid(columns: columns, spacing: Theme.Picker.rowSpacing) {
                ForEach(1...12, id: \.self) { month in
                    monthButton(month)
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

    // MARK: - 年份

    private var yearBar: some View {
        HStack(spacing: 10) {
            yearStepButton(
                symbol: "chevron.left",
                label: "上一年",
                identifier: "previousYearButton",
                action: { stepYear(-1) }
            )

            Spacer(minLength: 0)

            Text(String(displayedYear))
                .font(Theme.Typography.pickerYear)
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.ink)
                .contentTransition(.numericText())
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            yearStepButton(
                symbol: "chevron.right",
                label: "下一年",
                identifier: "nextYearButton",
                action: { stepYear(1) }
            )
        }
        .frame(height: Theme.Picker.yearBarHeight)
    }

    private func yearStepButton(
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

    // MARK: - 月份网格

    private func monthButton(_ month: Int) -> some View {
        let monthStart = MosaicCalendar.startOfMonth(year: displayedYear, month: month)
        let isSelected = MosaicCalendar.isSameMonth(monthStart, selection)
        let isCurrent = MosaicCalendar.isSameMonth(monthStart, .now)

        return Button {
            onSelect(monthStart)
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Text(MosaicCalendar.monthName(month))
                    .font(isSelected ? Theme.Typography.pickerMonthSelected : Theme.Typography.pickerMonth)
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
        .accessibilityIdentifier("month-\(displayedYear)-\(month)")
        .accessibilityLabel("\(MosaicCalendar.monthName(month)) \(displayedYear)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - 底部操作

    private var footer: some View {
        HStack {
            Button {
                onSelect(MosaicCalendar.startOfMonth(.now))
                dismiss()
            } label: {
                Text("回到本月")
                    .font(Theme.Typography.pickerAction)
                    .foregroundStyle(Theme.Palette.filterText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background {
                        Capsule().fill(Theme.Palette.soft)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("currentMonthButton")
            .accessibilityLabel("回到本月")

            Spacer(minLength: 0)

            Button("取消") {
                dismiss()
            }
            .font(Theme.Typography.pickerAction)
            .foregroundStyle(Theme.Palette.muted)
            .buttonStyle(.plain)
            .accessibilityLabel("取消选择月份")
        }
    }

    private func stepYear(_ delta: Int) {
        let next = min(max(displayedYear + delta, 1), 9999)
        guard next != displayedYear else { return }
        withAnimation(.easeInOut(duration: 0.16)) {
            displayedYear = next
        }
    }
}

#Preview {
    MonthPickerView(selection: .now) { _ in }
        .frame(height: 336)
        .background(Theme.Palette.paper)
}
