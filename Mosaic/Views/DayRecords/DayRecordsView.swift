//
//  DayRecordsView.swift
//  Mosaic
//
//  日历日期格子的下一页：当天所有记录的封面列表。
//  查询按 [当天 00:00, 次日 00:00) 过滤，日期修改后列表会自动刷新。
//

import SwiftData
import SwiftUI

struct DayRecordsView: View {
    let day: Date

    @Environment(\.dismiss) private var dismiss
    @Query private var items: [MediaItem]
    @State private var selectedItem: MediaItem?

    init(day: Date) {
        let start = MosaicCalendar.startOfDay(day)
        let end = MosaicCalendar.addDays(1, to: start)
        self.day = start

        _items = Query(
            filter: #Predicate<MediaItem> { item in
                item.recordDate >= start && item.recordDate < end
            },
            sort: [SortDescriptor(\MediaItem.createdAt, order: .forward)]
        )
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.DayList.spacing),
        count: Theme.DayList.columns
    )

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: MosaicCalendar.fullDateTitle(day),
                subtitle: "\(items.count) 条记录",
                backIdentifier: "dayRecordsBackButton",
                onBack: { dismiss() }
            )

            ScrollView {
                if items.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: Theme.DayList.spacing) {
                        ForEach(items) { item in
                            DayRecordCard(item: item) {
                                selectedItem = item
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.screenPadding)
                    .padding(.top, Theme.DayList.topPadding)
                    .padding(.bottom, Theme.DayList.bottomPadding)
                }
            }
        }
        .background(Theme.Palette.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedItem) { item in
            RecordDetailView(item: item)
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.stack")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Theme.Palette.muted.opacity(0.6))

            Text("这一天还没有记录")
                .font(Theme.Typography.cardMeta)
                .foregroundStyle(Theme.Palette.muted)

            Text("回到日历，用右下角的「＋」添加一条。")
                .font(Theme.Typography.cardMeta)
                .foregroundStyle(Theme.Palette.fieldPlaceholder)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
        .padding(.horizontal, Theme.Spacing.screenPadding)
    }
}

// MARK: - 当天记录卡片

private struct DayRecordCard: View {
    let item: MediaItem
    var action: () -> Void

    @State private var categoryStore = MediaCategoryStore.shared

    private var category: MediaCategory {
        categoryStore.category(for: item.categoryID)
    }

    private var metaText: String {
        let creator = item.creator.trimmingCharacters(in: .whitespacesAndNewlines)
        return creator.isEmpty ? category.title : "\(category.title) · \(creator)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                RecordThumbnail(
                    fileName: item.imageFileName,
                    symbolName: category.symbolName,
                    maxPixel: 480
                )
                .frame(maxWidth: .infinity)
                .frame(height: Theme.DayList.artHeight)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)

                    Text(metaText)
                        .font(Theme.Typography.cardMeta)
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.DayList.copyPadding)
                .background(Theme.Palette.soft)
            }
            .background(Theme.Palette.soft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.DayList.cardCorner, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("dayRecordCard")
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(item.title)，\(metaText)")
    }
}

#Preview("当天记录 · 有数据") {
    let container = MosaicContainer.makeInMemory()
    let context = ModelContext(container)
    context.insert(MediaItem(title: "海边的卡夫卡", creator: "村上春树", kind: .book, recordDate: .now))
    context.insert(MediaItem(title: "花样年华", creator: "王家卫", kind: .movie, recordDate: .now))
    context.insert(MediaItem(title: "冀西南林路行", creator: "万能青年旅店", kind: .music, recordDate: .now))

    return NavigationStack {
        DayRecordsView(day: .now)
    }
    .modelContainer(container)
}

#Preview("当天记录 · 空") {
    NavigationStack {
        DayRecordsView(day: .now)
    }
    .modelContainer(MosaicContainer.makeInMemory())
}
