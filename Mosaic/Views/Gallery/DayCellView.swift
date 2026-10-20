//
//  DayCellView.swift
//  Mosaic
//
//  日历的一格：顶部是低对比日号，下方是 4:3 的图片区。
//  1 张铺满，2 张左右并列，3–4 张 2×2 拼贴，超过 4 张显示 +N。
//

import SwiftUI

struct DayCellView: View {
    let day: MonthGrid.Day
    let items: [MediaItem]
    var onTap: () -> Void

    @State private var categoryStore = MediaCategoryStore.shared

    private var isToday: Bool { MosaicCalendar.isToday(day.date) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                dayNumber
                photoArea
            }
            .overlay(alignment: .bottomTrailing) { moreBadge }
        }
        .buttonStyle(DayCellButtonStyle())
        .opacity(day.isInMonth ? 1 : 0.33)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("day-\(MosaicCalendar.isoDayKey(day.date))")
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - 日号

    private var dayNumber: some View {
        Text("\(day.number)")
            .font(isToday ? Theme.Typography.dayNumberToday : Theme.Typography.dayNumber)
            .foregroundStyle(isToday ? Theme.Palette.ink : Theme.Palette.dayNumber)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.top, 4)
            .frame(height: Theme.Spacing.dayNumberHeight, alignment: .top)
    }

    // MARK: - 图片区（4:3）

    @ViewBuilder
    private var photoArea: some View {
        if items.isEmpty {
            // 空日期也占住 4:3 的高度，保证整行对齐。
            Color.clear
                .aspectRatio(Theme.Grid.photoAspectRatio, contentMode: .fit)
        } else {
            collage
                .aspectRatio(Theme.Grid.photoAspectRatio, contentMode: .fit)
        }
    }

    @ViewBuilder
    private var collage: some View {
        switch min(items.count, 4) {
        case 1:
            thumb(items[0])
        case 2:
            HStack(spacing: Theme.Grid.collageSpacing) {
                thumb(items[0])
                thumb(items[1])
            }
        case 3:
            VStack(spacing: Theme.Grid.collageSpacing) {
                HStack(spacing: Theme.Grid.collageSpacing) {
                    thumb(items[0])
                    thumb(items[1])
                }
                HStack(spacing: Theme.Grid.collageSpacing) {
                    thumb(items[2])
                    Color.clear
                }
            }
        default:
            VStack(spacing: Theme.Grid.collageSpacing) {
                HStack(spacing: Theme.Grid.collageSpacing) {
                    thumb(items[0])
                    thumb(items[1])
                }
                HStack(spacing: Theme.Grid.collageSpacing) {
                    thumb(items[2])
                    thumb(items[3])
                }
            }
        }
    }

    private func thumb(_ item: MediaItem) -> some View {
        let category = categoryStore.category(for: item.categoryID)
        return RecordThumbnail(
            fileName: item.imageFileName,
            symbolName: category.symbolName,
            maxPixel: 240
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.thumb, style: .continuous))
    }

    @ViewBuilder
    private var moreBadge: some View {
        if items.count > 4 {
            Text("+\(items.count - 4)")
                .font(Theme.Typography.moreCount)
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Capsule().fill(Theme.Palette.accent.opacity(0.8)))
                .padding(3)
                .allowsHitTesting(false)
        }
    }

    private var accessibilityText: String {
        let base = MosaicCalendar.fullDateTitle(day.date)
        return items.isEmpty ? base : "\(base)，\(items.count) 条记录"
    }
}

/// 按下时出现柔面底色与细描边，对应参考稿的 hover 态。
private struct DayCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.cell, style: .continuous)
                    .fill(configuration.isPressed ? Theme.Palette.pressBackground : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.cell, style: .continuous)
                    .strokeBorder(
                        configuration.isPressed ? Theme.Palette.pressBorder : Color.clear,
                        lineWidth: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.cell, style: .continuous))
    }
}
