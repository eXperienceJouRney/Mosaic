//
//  YearHeaderView.swift
//  Mosaic
//
//  时间轴页唯一的标题：年份 + 左右切换按钮，外观与画廊的月份标题一致。
//  点击年份打开年份选择器，方便跨年跳转。
//

import SwiftUI

struct YearHeaderView: View {
    let year: Int
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onSelectYear: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: onSelectYear) {
                HStack(spacing: 5) {
                    Text(String(year))
                        .font(Theme.Typography.month)
                        .tracking(Theme.Tracking.month)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Palette.ink)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.Palette.muted)
                        .padding(.top, 3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("yearTitleButton")
            .accessibilityLabel("\(year)，选择年份")
            .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            HStack(spacing: 7) {
                Button(action: onPrevious) {
                    Text("‹")
                        .font(Theme.Typography.iconButton)
                        .foregroundStyle(Theme.Palette.iconButton)
                }
                .buttonStyle(CircleIconButtonStyle())
                .accessibilityIdentifier("previousYearButton")
                .accessibilityLabel("上一年")

                Button(action: onNext) {
                    Text("›")
                        .font(Theme.Typography.iconButton)
                        .foregroundStyle(Theme.Palette.iconButton)
                }
                .buttonStyle(CircleIconButtonStyle())
                .accessibilityIdentifier("nextYearButton")
                .accessibilityLabel("下一年")
            }
        }
        .padding(.top, Theme.Spacing.monthBarTop)
        .padding(.bottom, Theme.Spacing.monthBarBottom)
    }
}

#Preview {
    YearHeaderView(year: 2026, onPrevious: {}, onNext: {}, onSelectYear: {})
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .background(Theme.Palette.paper)
}
