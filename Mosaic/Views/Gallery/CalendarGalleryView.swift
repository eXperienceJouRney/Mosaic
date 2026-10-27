//
//  CalendarGalleryView.swift
//  Mosaic
//
//  首页：月份标题 + 分类筛选 + 七列日历 + 添加按钮。
//  没有 App 标题、Logo 或欢迎语，画廊本身就是首屏。
//
//  状态只有两个：当前月份锚点与当前分类。
//  日历网格和按天索引都由这两者推导，切换任一项都不会改写记录日期。
//

import SwiftData
import SwiftUI

struct CalendarGalleryView: View {
    var isActive = true

    @Query(sort: \MediaItem.recordDate, order: .reverse)
    private var items: [MediaItem]

    @State private var monthAnchor: Date = MosaicCalendar.startOfMonth(.now)
    @State private var selectedCategoryID: String?
    @State private var isMonthPickerPresented = false
    @State private var isAddingRecord = false
    @State private var selectedDay: Date?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Grid.spacing),
        count: Theme.Grid.columnCount
    )

    var body: some View {
        let grid = MonthGrid(monthContaining: monthAnchor)
        let index = DayIndex(items: items, categoryID: selectedCategoryID)

        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        MonthHeaderView(
                            month: monthAnchor,
                            onPrevious: { shiftMonth(-1) },
                            onNext: { shiftMonth(1) },
                            onSelectMonth: { isMonthPickerPresented = true },
                            onToday: { goToMonth(.now) }
                        )
                        .padding(.horizontal, Theme.Spacing.screenPadding)

                        MediaFilterBar(selection: $selectedCategoryID)
                            .padding(.horizontal, Theme.Spacing.screenPadding)

                        LazyVGrid(columns: columns, spacing: Theme.Grid.spacing) {
                            ForEach(grid.days.filter(\.isInMonth)) { day in
                                DayCellView(day: day, items: index.items(on: day.date)) {
                                    selectedDay = day.date
                                }
                                .id(day.date)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.screenPadding)
                        .padding(.bottom, 88)
                    }
                    .padding(.top, Theme.Spacing.appTop)
                }
                .scrollIndicators(.hidden)
                .onAppear { showToday(using: proxy) }
                .onChange(of: monthAnchor) { _, newMonth in
                    if Calendar.current.isDate(newMonth, equalTo: .now, toGranularity: .month) {
                        scrollToToday(using: proxy)
                    }
                }
                .onChange(of: isActive) { _, active in
                    if active { showToday(using: proxy) }
                }
            }

            AddRecordButton {
                isAddingRecord = true
            }
            .padding(.trailing, Theme.Spacing.fabTrailing)
            .padding(.bottom, Theme.Spacing.fabBottom)
        }
        .background(Theme.Palette.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedDay) { day in
            DayRecordsView(day: day)
        }
        .sheet(isPresented: $isMonthPickerPresented) {
            MonthPickerView(selection: monthAnchor) { month in
                goToMonth(month)
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

    // MARK: - 月份切换

    /// 左右按钮与月份选择器共用同一入口，保证边界与跨年逻辑一致。
    private func shiftMonth(_ delta: Int) {
        goToMonth(MosaicCalendar.addMonths(delta, to: monthAnchor))
    }

    private func goToMonth(_ month: Date) {
        let target = MosaicCalendar.startOfMonth(month)
        guard target != monthAnchor else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            monthAnchor = target
        }
    }

    private func scrollToToday(using proxy: ScrollViewProxy) {
        let today = MosaicCalendar.startOfDay(.now)
        Task { @MainActor in
            await Task.yield()
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(today, anchor: .center)
            }
        }
    }

    private func showToday(using proxy: ScrollViewProxy) {
        monthAnchor = MosaicCalendar.startOfMonth(.now)
        scrollToToday(using: proxy)
    }
}

#Preview("画廊 · 样例数据") {
    NavigationStack {
        CalendarGalleryView()
    }
    .modelContainer(MosaicContainer.preview)
}

#Preview("画廊 · 空数据") {
    NavigationStack {
        CalendarGalleryView()
    }
    .modelContainer(MosaicContainer.makeInMemory())
}
