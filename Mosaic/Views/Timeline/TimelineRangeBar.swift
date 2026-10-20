//
//  TimelineRangeBar.swift
//  Mosaic
//
//  筛选栏下面的一行：左侧「YOUR COLLECTION」标签，右侧浅色胶囊里的三段切换。
//  顶部分隔线只占版心宽度，与参考稿的 border-top 一致。
//

import SwiftUI

struct TimelineRangeBar: View {
    @Binding var selection: TimelineRange

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.Palette.hairline)
                .frame(height: 1)

            HStack(spacing: 0) {
                Text("YOUR COLLECTION")
                    .font(Theme.Typography.timelineRangeLabel)
                    .tracking(Theme.Tracking.timelineMonth)
                    .foregroundStyle(Theme.Palette.timelineMeta)

                Spacer(minLength: 8)

                HStack(spacing: Theme.Timeline.segmentGap) {
                    ForEach(TimelineRange.allCases) { range in
                        segment(range)
                    }
                }
                .padding(Theme.Timeline.segmentPadding)
                .background(Capsule().fill(Theme.Palette.segmentBackground))
            }
            .padding(.top, Theme.Timeline.rangeTop)
            .padding(.bottom, Theme.Timeline.rangeBottom)
        }
    }

    private func segment(_ range: TimelineRange) -> some View {
        let isSelected = selection == range

        return Button {
            selection = range
        } label: {
            Text(range.title)
                .font(Theme.Typography.timelineSegment)
                .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.segmentText)
                .padding(.horizontal, Theme.Timeline.segmentHorizontal)
                .padding(.vertical, Theme.Timeline.segmentVertical)
                .background {
                    Capsule().fill(isSelected ? Theme.Palette.surface : Color.clear)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("timelineRange-\(range.rawValue)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(range.title)
    }
}

#Preview {
    TimelineRangeBarPreviewHost()
}

private struct TimelineRangeBarPreviewHost: View {
    @State private var selection: TimelineRange = .all

    var body: some View {
        TimelineRangeBar(selection: $selection)
            .padding(.horizontal, Theme.Spacing.screenPadding)
            .background(Theme.Palette.paper)
    }
}
