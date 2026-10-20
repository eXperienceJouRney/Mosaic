//
//  ScreenHeader.swift
//  Mosaic
//
//  当天记录 / 作品详情共用的轻量顶栏：返回箭头 + 一行标题 + 可选副标题。
//  不使用系统导航栏，保持与画廊一致的纸感留白。
//

import SwiftUI

struct ScreenHeader: View {
    let title: String
    var subtitle: String?
    var backIdentifier: String = "screenBackButton"
    var onBack: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Theme.ScreenHeader.spacing) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(Theme.Typography.backIcon)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(
                        width: Theme.ScreenHeader.backHitSize,
                        height: Theme.ScreenHeader.backHitSize
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(backIdentifier)
            .accessibilityLabel("返回")

            VStack(alignment: .leading, spacing: Theme.ScreenHeader.subtitleTop) {
                Text(title)
                    .font(Theme.Typography.screenTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityIdentifier("screenTitle")
                    .accessibilityAddTraits(.isHeader)

                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.screenSubtitle)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.top, Theme.Spacing.appTop)
        .padding(.bottom, Theme.ScreenHeader.bottom)
    }
}

#Preview {
    VStack {
        ScreenHeader(title: "October 12, 2026", subtitle: "5 条记录", onBack: {})
        Spacer()
    }
    .background(Theme.Palette.paper)
}
