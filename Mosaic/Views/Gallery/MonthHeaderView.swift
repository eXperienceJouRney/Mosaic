//
//  MonthHeaderView.swift
//  Mosaic
//
//  月份是首屏唯一的标题：英文月份 + 年份，右侧两个圆形切换按钮。
//  点击标题打开月份选择器，方便跨月跳转。
//

import SwiftUI

struct MonthHeaderView: View {
    let month: Date
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onSelectMonth: () -> Void = {}
    var onToday: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: onSelectMonth) {
                HStack(spacing: 7) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(MosaicCalendar.monthName(Calendar.current.component(.month, from: month)))
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .tracking(Theme.Tracking.month)
                            .foregroundStyle(Theme.Palette.ink)
                        Text(String(Calendar.current.component(.year, from: month)))
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.8)
                            .foregroundStyle(Theme.Palette.muted)
                    }
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.Palette.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("monthTitleButton")
            .accessibilityLabel("\(MosaicCalendar.monthTitle(month))，选择月份")
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            HStack(spacing: 7) {
                if !Calendar.current.isDate(month, equalTo: .now, toGranularity: .month) {
                    Button(action: onToday) {
                        Text("回到今天")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Palette.filterText)
                            .padding(.horizontal, 9).padding(.vertical, 6)
                            .overlay(Capsule().stroke(Theme.Palette.hairline))
                    }
                    .buttonStyle(.plain)
                }
                Button(action: onPrevious) {
                    Text("‹")
                        .font(Theme.Typography.iconButton)
                        .foregroundStyle(Theme.Palette.iconButton)
                }
                .buttonStyle(CircleIconButtonStyle())
                .accessibilityIdentifier("previousMonthButton")
                .accessibilityLabel("上个月")

                Button(action: onNext) {
                    Text("›")
                        .font(Theme.Typography.iconButton)
                        .foregroundStyle(Theme.Palette.iconButton)
                }
                .buttonStyle(CircleIconButtonStyle())
                .accessibilityIdentifier("nextMonthButton")
                .accessibilityLabel("下个月")
            }
        }
        .padding(.top, Theme.Spacing.monthBarTop)
        .padding(.bottom, Theme.Spacing.monthBarBottom)
    }
}

#Preview {
    MonthHeaderView(month: .now, onPrevious: {}, onNext: {}, onSelectMonth: {})
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .background(Theme.Palette.paper)
}
