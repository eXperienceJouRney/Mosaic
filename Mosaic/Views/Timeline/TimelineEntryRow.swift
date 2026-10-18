//
//  TimelineEntryRow.swift
//  Mosaic
//
//  时间轴的一条记录：左列日期 + 中缝节点，右侧「分类 / 动作」小字、
//  标题 / 创作者 / 感受，以及一张 112×125 的封面。
//  封面沿用日历缩略图，没有图片时显示类型符号占位。
//

import SwiftData
import SwiftUI

struct TimelineEntryRow: View {
    let item: MediaItem
    var onTap: () -> Void

    @State private var categoryStore = MediaCategoryStore.shared

    private var category: MediaCategory {
        categoryStore.category(for: item.categoryID)
    }

    private var creatorText: String {
        item.creator.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var noteText: String {
        item.note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Timeline.columnGap) {
                dateColumn
                content
            }
            .overlay(alignment: .topLeading) { dot }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("timelineEntry-\(MosaicCalendar.isoDayKey(item.recordDate))")
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - 左列日期

    private var dateColumn: some View {
        VStack(spacing: Theme.Timeline.weekdayTop) {
            Text(String(format: "%02d", MosaicCalendar.dayNumber(of: item.recordDate)))
                .font(Theme.Typography.timelineDay)
                .monospacedDigit()
                .foregroundStyle(Theme.Palette.ink)

            Text(MosaicCalendar.weekdayShortLabel(item.recordDate))
                .font(Theme.Typography.timelineWeekday)
                .foregroundStyle(Theme.Palette.weekdayLabel)
        }
        .frame(width: Theme.Timeline.dateColumnWidth)
        .padding(.top, Theme.Timeline.dateTop)
    }

    // MARK: - 中缝节点

    private var dot: some View {
        ZStack {
            Circle()
                .fill(Theme.Palette.paper)
                .frame(width: Theme.Timeline.dotRingSize, height: Theme.Timeline.dotRingSize)

            Circle()
                .fill(Theme.Palette.timelineDot)
                .frame(width: Theme.Timeline.dotSize, height: Theme.Timeline.dotSize)
        }
        .padding(.leading, Theme.Timeline.dotCenterX - Theme.Timeline.dotRingSize / 2)
        .padding(.top, Theme.Timeline.dotCenterY - Theme.Timeline.dotRingSize / 2)
        .allowsHitTesting(false)
    }

    // MARK: - 右侧内容

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(category.title)
                Spacer(minLength: 8)
                Text(category.timelineActionLabel)
            }
            .font(Theme.Typography.timelineMeta)
            .tracking(Theme.Tracking.timelineLabel)
            .foregroundStyle(Theme.Palette.timelineMeta)

            HStack(alignment: .center, spacing: Theme.Timeline.copyToCover) {
                copy
                cover
            }
            .padding(.top, Theme.Timeline.metaToMain)
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.title)
                .font(Theme.Typography.timelineEntryTitle)
                .tracking(Theme.Tracking.timelineEntryTitle)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if !creatorText.isEmpty {
                Text(creatorText)
                    .font(Theme.Typography.timelineCreator)
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
                    .padding(.top, Theme.Timeline.titleToCreator)
            }

            if !noteText.isEmpty {
                Text(noteText)
                    .font(Theme.Typography.timelineNote)
                    .foregroundStyle(Theme.Palette.secondaryInk)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .padding(.top, Theme.Timeline.creatorToNote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cover: some View {
        RecordThumbnail(
            fileName: item.imageFileName,
            symbolName: category.symbolName,
            maxPixel: 360
        )
            .frame(width: Theme.Timeline.coverWidth, height: Theme.Timeline.coverHeight)
            .clipShape(
                RoundedRectangle(cornerRadius: Theme.Timeline.coverCorner, style: .continuous)
            )
    }

    private var accessibilityText: String {
        let date = MosaicCalendar.fullDateTitle(item.recordDate)
        let creator = creatorText.isEmpty ? category.title : "\(category.title)，\(creatorText)"
        return "\(item.title)，\(creator)，\(date)"
    }
}

#Preview("时间轴条目") {
    let container = MosaicContainer.makeInMemory()
    let context = ModelContext(container)
    let item = MediaItem(
        title: "海边的卡夫卡",
        creator: "村上春树",
        kind: .book,
        note: "十五岁的少年拖着影子走进四国。读到最后一页时，窗外正好下雨。",
        recordDate: .now
    )
    context.insert(item)

    return TimelineEntryRow(item: item, onTap: {})
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .padding(.vertical, 16)
        .background(Theme.Palette.paper)
        .modelContainer(container)
}
