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

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: onSelectMonth) {
                HStack(spacing: 5) {
                    Text(MosaicCalendar.monthTitle(month))
                        .font(Theme.Typography.month)
                        .tracking(Theme.Tracking.month)
                        .foregroundStyle(Theme.Palette.ink)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.Palette.muted)
                        .padding(.top, 3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("monthTitleButton")
            .accessibilityLabel("\(MosaicCalendar.monthTitle(month))，选择月份")
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            HStack(spacing: 7) {
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
