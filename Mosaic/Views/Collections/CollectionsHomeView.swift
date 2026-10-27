import SwiftData
import SwiftUI
import UIKit

struct CollectionsHomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MediaCollection.createdAt, order: .forward) private var collections: [MediaCollection]
    @Query(sort: \MediaItem.recordDate, order: .reverse) private var records: [MediaItem]
    @State private var isCreating = false
    @State private var name = ""
    @State private var pendingDeletion: MediaCollection?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("作品集").font(.system(size: 30, weight: .regular, design: .serif)).tracking(-1.2)
                    Text("\(collections.count) 本作品集").font(.system(size: 11)).foregroundStyle(Theme.Palette.muted)
                }
                Spacer()
                Button { isCreating = true } label: {
                    Label("新建", systemImage: "plus").font(.system(size: 12))
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(Theme.Palette.surface, in: Capsule())
                        .overlay(Capsule().stroke(Theme.Palette.hairline))
                }
                .tint(Theme.Palette.ink)
            }
            .padding(.horizontal, 22).padding(.top, 20).padding(.bottom, 22)

            ScrollView {
                if collections.isEmpty {
                    ContentUnavailableView {
                        Label("创建你的第一本作品集", systemImage: "books.vertical")
                    } description: {
                        Text("按主题整理喜欢的作品")
                    } actions: {
                        Button("创建作品集") { isCreating = true }
                            .buttonStyle(.borderedProminent).tint(Theme.Palette.accent)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: Theme.Collection.spacing) {
                        ForEach(collections) { collection in
                            NavigationLink(value: collection.id) {
                                CollectionBookCard(
                                    collection: collection,
                                    records: records.filter { $0.collectionID == collection.id }
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("删除作品集", role: .destructive) { pendingDeletion = collection }
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 36)
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(Theme.Palette.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { id in
            if let collection = collections.first(where: { $0.id == id }) {
                CollectionDetailView(collection: collection)
            }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack {
                Form {
                    TextField("例如：秋日阅读、周末电影", text: $name)
                        .accessibilityIdentifier("collectionNameField")
                }
                .scrollContentBackground(.hidden)
                .background(Theme.Palette.paper)
                .navigationTitle("创建作品集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { isCreating = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("创建") { create() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("删除这个作品集？", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            Button("删除作品集", role: .destructive) {
                if let pendingDeletion { delete(pendingDeletion) }
                pendingDeletion = nil
            }
            Button("取消", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("作品会保留，只会解除作品集归属。")
        }
    }

    private func create() {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !collections.contains(where: { $0.name.localizedCaseInsensitiveCompare(title) == .orderedSame }) else { return }
        context.insert(MediaCollection(name: title))
        try? context.save()
        name = ""
        isCreating = false
    }

    private func delete(_ collection: MediaCollection) {
        for record in records where record.collectionID == collection.id { record.collectionID = nil }
        context.delete(collection)
        try? context.save()
    }
}

private struct CollectionBookCard: View {
    let collection: MediaCollection
    let records: [MediaItem]

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Color(hex: 0x82989A), Color(hex: 0x344B4E)], startPoint: .topLeading, endPoint: .bottomTrailing))
                if let record = records.first {
                    RecordThumbnail(fileName: record.imageFileName, symbolName: record.kind.symbolName, maxPixel: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom))
                }
                Text(collection.name)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(14)
            }
            .frame(height: Theme.Collection.coverHeight)
            Text("\(records.count) 件作品")
                .font(.system(size: 10)).foregroundStyle(Theme.Palette.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CollectionDetailView: View {
    let collection: MediaCollection
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MediaItem.recordDate, order: .reverse) private var allRecords: [MediaItem]
    @State private var page = 0
    @State private var isTurning = false
    @State private var pageImages: [UUID: UIImage] = [:]
    @State private var isPagePreparationComplete = false
    @State private var selectedItem: MediaItem?

    private var records: [MediaItem] { allRecords.filter { $0.collectionID == collection.id } }
    private var spreadCount: Int { max(1, (records.count + 1) / 2) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.72), in: Circle())
                }
                .accessibilityLabel("返回作品集")
                VStack(alignment: .leading, spacing: 2) {
                    Text("ZINE").font(.system(size: 9, weight: .semibold, design: .rounded)).tracking(1.8)
                        .foregroundStyle(Theme.Palette.muted)
                    Text(collection.name).font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(Theme.Palette.ink).lineLimit(1)
                }
                Spacer()
                Text(spreadLabel)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.Palette.muted)
            }
            .padding(.horizontal, 20).padding(.top, 6).padding(.bottom, 8)

            GeometryReader { proxy in
                let spreadSize = fittedSpreadSize(in: proxy.size)
                PageCurlPager(count: spreadCount, index: $page, isTurning: $isTurning) { pageIndex in
                    if let item = item(at: pageIndex) {
                        Button { selectedItem = item } label: {
                            ZineBookLeaf(image: image(at: pageIndex), isLeft: pageIndex.isMultiple(of: 2))
                        }
                        .buttonStyle(.plain)
                    } else {
                        ZineBookLeaf(image: nil, isLeft: pageIndex.isMultiple(of: 2))
                    }
                }
                .frame(width: spreadSize.width, height: spreadSize.height)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .allowsHitTesting(isPagePreparationComplete)
            }

            HStack(spacing: 26) {
                Button { turnPage(-1) } label: {
                    Image(systemName: "arrow.left").font(.system(size: 15, weight: .medium))
                        .frame(width: 44, height: 44).background(.white.opacity(0.72), in: Circle())
                }
                .disabled(page == 0 || isTurning || !isPagePreparationComplete).accessibilityLabel("上一页")
                Text(records.isEmpty ? "空白页" : "轻扫翻阅")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.Palette.muted).frame(minWidth: 72)
                Button { turnPage(1) } label: {
                    Image(systemName: "arrow.right").font(.system(size: 15, weight: .medium))
                        .frame(width: 44, height: 44).background(.white.opacity(0.72), in: Circle())
                }
                .disabled(page >= spreadCount - 1 || isTurning || !isPagePreparationComplete).accessibilityLabel("下一页")
            }
            .buttonStyle(.plain).tint(Theme.Palette.ink).padding(.top, 12).padding(.bottom, 10)
        }
        .background(Color(hex: 0xECE9E1).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task(id: page) { await loadVisiblePage() }
        .sheet(item: $selectedItem) { item in
            NavigationStack { RecordDetailView(item: item) }
        }
    }

    private var spreadLabel: String {
        guard !records.isEmpty else { return "00 / 00" }
        let first = page * 2 + 1
        let last = min(first + 1, records.count)
        return String(format: "%02d–%02d / %02d", first, last, records.count)
    }

    private func item(at index: Int) -> MediaItem? { records.indices.contains(index) ? records[index] : nil }
    private func image(at index: Int) -> UIImage? { item(at: index).flatMap { pageImages[$0.id] } }

    private func fittedSpreadSize(in size: CGSize) -> CGSize {
        let availableWidth = max(0, size.width - 36)
        let height = max(0, min(min(size.height * 0.68, availableWidth / 1.42), 440))
        return CGSize(width: height * 1.42, height: height)
    }

    @MainActor
    private func loadVisiblePage() async {
        guard !records.isEmpty else {
            isPagePreparationComplete = true
            return
        }
        let firstRecord = page * 2
        let nearbyIndices = (firstRecord - 2...firstRecord + 3).filter { records.indices.contains($0) }
        let nearbyPages = nearbyIndices.compactMap { item(at: $0) }
        let nearbyIDs = Set(nearbyPages.map(\.id))
        pageImages = pageImages.filter { nearbyIDs.contains($0.key) }
        for item in nearbyPages where pageImages[item.id] == nil {
            if let image = await loadPageImage(item) { pageImages[item.id] = image }
            if Task.isCancelled { return }
        }
        isPagePreparationComplete = true
    }

    private func loadPageImage(_ item: MediaItem?) async -> UIImage? {
        guard let item, !item.imageFileName.isEmpty else { return nil }
        return await ImageStore.shared.thumbnailAsync(named: item.imageFileName, maxPixel: 900)
    }

    private func turnPage(_ direction: Int) {
        let target = page + direction
        guard !isTurning, isPagePreparationComplete, (0..<spreadCount).contains(target) else { return }
        page = target
    }
}

private struct ZineBookLeaf: View {
    let image: UIImage?
    let isLeft: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(hex: 0xFBFAF6)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: isLeft ? .trailing : .leading) {
                LinearGradient(
                    colors: isLeft ? [.clear, Color.black.opacity(0.055)] : [Color.black.opacity(0.055), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 9)
                .allowsHitTesting(false)
            }
            .overlay(Rectangle().stroke(Color.black.opacity(0.035), lineWidth: 0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
