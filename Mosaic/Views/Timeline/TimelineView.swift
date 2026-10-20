//
//  TimelineView.swift
//  Mosaic
//
//  第二页：沿着时间回看收藏过的故事。
//  年份是这一页唯一的标题（与画廊的月份标题同款），下面是分类筛选、
//  时间范围，以及按月份分组的时间轴。
//
//  三条筛选（年份 / 分类 / 范围）互不干扰，全部由 TimelineFeed 推导；
//  切换任一项都不会改写记录日期，也不会打断已经打开的分页。
//

import SwiftData
import SwiftUI

struct TimelineView: View {
    @Query(sort: \MediaItem.recordDate, order: .reverse)
    private var items: [MediaItem]

    @State private var year: Int = MosaicCalendar.year(of: .now)
    @State private var selectedCategoryID: String?
    @State private var range: TimelineRange = .all
    @State private var isYearPickerPresented = false
    @State private var selectedItem: MediaItem?
    @State private var isAddingRecord = false

    var body: some View {
        let feed = TimelineFeed(
            items: items,
            year: year,
            range: range,
            categoryID: selectedCategoryID
        )

        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                YearHeaderView(
                    year: year,
                    onPrevious: { shiftYear(-1) },
                    onNext: { shiftYear(1) },
                    onSelectYear: { isYearPickerPresented = true }
                )
                .padding(.horizontal, Theme.Spacing.screenPadding)

                MediaFilterBar(selection: $selectedCategoryID)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                TimelineRangeBar(selection: $range)
                    .padding(.horizontal, Theme.Spacing.screenPadding)

                timeline(feed)
            }
            .padding(.top, Theme.Spacing.appTop)

            AddRecordButton {
                isAddingRecord = true
            }
            .padding(.trailing, Theme.Spacing.fabTrailing)
            .padding(.bottom, Theme.Spacing.fabBottom)
        }
        .background(Theme.Palette.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("timelineScreen")
        .navigationDestination(item: $selectedItem) { item in
            RecordDetailView(item: item)
        }
        .sheet(isPresented: $isYearPickerPresented) {
            YearPickerView(selection: year) { picked in
                goToYear(picked)
            }
            .presentationDetents([.height(Theme.Picker.sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Theme.Radius.sheet)
            .presentationBackground(Theme.Palette.paper)
        }
        .fullScreenCover(isPresented: $isAddingRecord) {
            AddRecordView()
        }
    }

    // MARK: - 年份切换

    /// 左右按钮与年份选择器共用同一入口，保证边界处理一致。
    private func shiftYear(_ delta: Int) {
        goToYear(year + delta)
    }

    private func goToYear(_ target: Int) {
        let clamped = min(max(target, 1), 9999)
        guard clamped != year else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            year = clamped
        }
    }

    // MARK: - 时间轴

    @ViewBuilder
    private func timeline(_ feed: TimelineFeed) -> some View {
        ScrollView {
            if feed.isEmpty {
                emptyState
            } else {
                sections(feed)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func sections(_ feed: TimelineFeed) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(feed.sections) { section in
                Text(section.title.uppercased())
                    .font(Theme.Typography.timelineMonth)
                    .tracking(Theme.Tracking.timelineMonth)
                    .foregroundStyle(Theme.Palette.timelineMeta)
                    .padding(.leading, Theme.Timeline.dateColumnWidth + Theme.Timeline.columnGap)
                    .padding(.bottom, Theme.Timeline.monthBottom)
                    .accessibilityIdentifier("timelineMonthHeader")

                ForEach(section.items) { item in
                    TimelineEntryRow(item: item) {
                        selectedItem = item
                    }
                    .padding(.bottom, Theme.Timeline.entryBottom)
                }
            }
        }
        .padding(.top, Theme.Timeline.topPadding)
        .padding(.bottom, Theme.Timeline.bottomPadding)
        .padding(.horizontal, Theme.Spacing.screenPadding)
        .overlay(alignment: .topLeading) { timelineLine }
    }

    /// 贯穿整页的竖线。放在 LazyVStack 的 overlay 上，因此会随内容一起滚动。
    private var timelineLine: some View {
        Rectangle()
            .fill(Theme.Palette.timelineLine)
            .frame(width: 1)
            .padding(.leading, Theme.Spacing.screenPadding + Theme.Timeline.lineX)
            .padding(.top, Theme.Timeline.lineTop)
            .padding(.bottom, Theme.Timeline.lineBottom)
            .allowsHitTesting(false)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("这段时间还没有记录。")
            Text("换一年，或把时间范围切回「全部」再看看。")
        }
        .font(Theme.Typography.timelineEmpty)
        .foregroundStyle(Theme.Palette.muted)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Theme.Timeline.dateColumnWidth + Theme.Timeline.columnGap)
        .padding(.top, Theme.Timeline.emptyTop)
        .accessibilityIdentifier("timelineEmptyState")
    }
}

#Preview("时间轴 · 样例数据") {
    NavigationStack {
        TimelineView()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MosaicTabBar(selection: .constant(.timeline))
            }
    }
    .modelContainer(MosaicContainer.preview)
}

#Preview("时间轴 · 空数据") {
    NavigationStack {
        TimelineView()
    }
    .modelContainer(MosaicContainer.makeInMemory())
}
