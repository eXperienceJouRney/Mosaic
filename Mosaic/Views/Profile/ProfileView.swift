import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query private var records: [MediaItem]
    @Query private var collections: [MediaCollection]
    @AppStorage("mosaic.profile.name") private var name = "Mosaic Friend"
    @AppStorage("mosaic.profile.bio") private var bio = "记录让我停下来的瞬间。"
    @AppStorage("mosaic.profile.avatar") private var avatarFile = ""
    @AppStorage("mosaic.profile.cover") private var coverFile = ""
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editBio = ""
    @State private var isShowingRecap = false
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingImport: BackupPayload?
    @State private var isConfirmingImport = false
    @State private var avatarPicker: PhotosPickerItem?
    @State private var coverPicker: PhotosPickerItem?
    @State private var errorMessage = ""
    @State private var isShowingError = false

    private var avatar: UIImage? { avatarFile.isEmpty ? nil : ImageStore.shared.original(named: avatarFile) }
    private var cover: UIImage? { coverFile.isEmpty ? nil : ImageStore.shared.original(named: coverFile) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(spacing: 16) {
                    PhotosPicker(selection: $avatarPicker, matching: .images) {
                        Group {
                            if let avatar {
                                Image(uiImage: avatar).resizable().scaledToFill()
                            } else {
                                Text(String(name.prefix(1)).uppercased())
                                    .font(.system(size: 44, design: .serif)).foregroundStyle(Theme.Palette.yearText)
                                    .background(Theme.Palette.surface)
                            }
                        }
                        .frame(width: 118, height: 118).clipShape(Circle())
                        .overlay(Circle().stroke(Theme.Palette.surface, lineWidth: 6))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                        .offset(y: -59).padding(.bottom, -59)
                    }
                    VStack(spacing: 7) {
                        Text(name).font(.system(size: 28, weight: .medium, design: .serif)).foregroundStyle(Theme.Palette.ink)
                        Text("@mosaic").font(.system(size: 12)).foregroundStyle(Theme.Palette.muted)
                        Text(bio).font(.system(size: 12)).foregroundStyle(Theme.Palette.filterText)
                            .multilineTextAlignment(.center).lineLimit(3).padding(.horizontal, 24)
                    }
                    .padding(.top, 2)

                    HStack(spacing: 8) {
                        stat(records.count, "收藏")
                        stat(Set(records.map(\.categoryID)).count, "分类")
                        stat(Set(records.map { Calendar.current.component(.year, from: $0.recordDate) }).count, "年份")
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        menu("编辑个人资料", symbol: "pencil") {
                            editName = name
                            editBio = bio
                            isEditing = true
                        }
                        menu("年度回顾", symbol: "chart.bar") { isShowingRecap = true }
                        menu("导出本地备份", symbol: "square.and.arrow.up") { isExporting = true }
                        menu("导入本地备份", symbol: "square.and.arrow.down") { isImporting = true }
                    }
                    .padding(.horizontal, 22)
                    Text("本地优先 · 无需账号")
                        .font(.system(size: 10)).foregroundStyle(Theme.Palette.muted).padding(.top, 2).padding(.bottom, 22)
                }
                .frame(maxWidth: .infinity)
                .background(Theme.Palette.paper, in: UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
                .padding(.top, -24)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .background(Theme.Palette.paper)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isEditing) { editSheet }
        .sheet(isPresented: $isShowingRecap) { RecapSheet(records: records) }
        .fileExporter(isPresented: $isExporting, document: BackupDocument(payload: makeBackup()), contentType: .json, defaultFilename: "mosaic-backup") { result in
            if case .failure(let error) = result { present(error.localizedDescription) }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                pendingImport = try JSONDecoder().decode(BackupPayload.self, from: Data(contentsOf: url))
                isConfirmingImport = true
            } catch { present("无法读取备份文件。") }
        }
        .confirmationDialog("替换本机内容？", isPresented: $isConfirmingImport, titleVisibility: .visible) {
            Button("导入并替换", role: .destructive) { importBackup() }
            Button("取消", role: .cancel) { pendingImport = nil }
        } message: {
            Text("将替换当前的记录和作品集。")
        }
        .alert("无法完成", isPresented: $isShowingError) { Button("好", role: .cancel) {} } message: { Text(errorMessage) }
        .onChange(of: avatarPicker) { _, value in loadProfilePhoto(value, isAvatar: true) }
        .onChange(of: coverPicker) { _, value in loadProfilePhoto(value, isAvatar: false) }
    }

    private var hero: some View {
        PhotosPicker(selection: $coverPicker, matching: .images) {
            ZStack {
                Group {
                    if let cover { Image(uiImage: cover).resizable().scaledToFill() }
                    else { LinearGradient(colors: [Color(hex: 0x0877A4), Color(hex: 0x0E2941)], startPoint: .topLeading, endPoint: .bottomTrailing) }
                }
                .frame(height: 270).clipped()
                LinearGradient(colors: [.black.opacity(0.08), .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 270)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 270)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .accessibilityLabel("更换个人主页封面")
        .accessibilityElement(children: .contain)
    }

    private func stat(_ value: Int, _ title: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 17, weight: .medium))
            Text(title).font(.system(size: 9)).foregroundStyle(Theme.Palette.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Theme.Palette.hairline))
    }

    private func menu(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol).frame(width: 18).foregroundStyle(Theme.Palette.muted)
                Text(title).foregroundStyle(Theme.Palette.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(Theme.Palette.muted)
            }
            .font(.system(size: 12)).padding(.vertical, 14)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.Palette.hairline).frame(height: 1) }
        }
        .buttonStyle(.plain)
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                TextField("昵称", text: $editName)
                TextField("个人简介", text: $editBio, axis: .vertical).lineLimit(2...4)
                PhotosPicker(selection: $avatarPicker, matching: .images) { Label("更换头像", systemImage: "person.crop.circle") }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { isEditing = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { name = editName.trimmingCharacters(in: .whitespacesAndNewlines); bio = editBio.trimmingCharacters(in: .whitespacesAndNewlines); isEditing = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadProfilePhoto(_ selection: PhotosPickerItem?, isAvatar: Bool) {
        guard let selection else { return }
        Task {
            do {
                guard let data = try await selection.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
                let stored = try ImageStore.shared.save(image)
                await MainActor.run { if isAvatar { avatarFile = stored.fileName } else { coverFile = stored.fileName } }
            } catch { await MainActor.run { present("图片保存失败。") } }
        }
    }

    private func makeBackup() -> BackupPayload {
        BackupPayload(
            records: records.map { item in
                BackupRecord(id: item.id, title: item.title, creator: item.creator, categoryID: item.categoryID, rating: item.rating, note: item.note, mood: item.mood, collectionID: item.collectionID, tags: item.tags, recordDate: item.recordDate, image: item.imageFileName.isEmpty ? nil : ImageStore.shared.original(named: item.imageFileName)?.jpegData(compressionQuality: 0.85))
            },
            collections: collections.map { BackupCollection(id: $0.id, name: $0.name) },
            profileName: name, profileBio: bio,
            profileAvatar: avatar?.jpegData(compressionQuality: 0.85),
            profileCover: cover?.jpegData(compressionQuality: 0.85)
        )
    }

    private func importBackup() {
        guard let payload = pendingImport else { return }
        let oldImages = records.map(\.imageFileName).filter { !$0.isEmpty }
        let oldProfileImages = [avatarFile, coverFile].filter { !$0.isEmpty }
        var newImages: [String] = []
        var importedAvatarFile = ""
        var importedCoverFile = ""
        do {
            for record in records { context.delete(record) }
            for collection in collections { context.delete(collection) }
            for collection in payload.collections { context.insert(MediaCollection(name: collection.name, id: collection.id)) }
            for item in payload.records {
                var fileName = ""
                if let data = item.image, let image = UIImage(data: data) {
                    let stored = try ImageStore.shared.save(image)
                    fileName = stored.fileName
                    newImages.append(fileName)
                }
                let record = MediaItem(title: item.title, creator: item.creator, kind: MediaKind(rawValue: item.categoryID) ?? .other, categoryID: item.categoryID, rating: item.rating, note: item.note, mood: item.mood, collectionID: item.collectionID, recordDate: item.recordDate, imageFileName: fileName, tags: item.tags, id: item.id)
                context.insert(record)
            }
            if let data = payload.profileAvatar, let image = UIImage(data: data) {
                let stored = try ImageStore.shared.save(image)
                newImages.append(stored.fileName)
                importedAvatarFile = stored.fileName
            }
            if let data = payload.profileCover, let image = UIImage(data: data) {
                let stored = try ImageStore.shared.save(image)
                newImages.append(stored.fileName)
                importedCoverFile = stored.fileName
            }
            try context.save()
            name = payload.profileName
            bio = payload.profileBio
            avatarFile = importedAvatarFile
            coverFile = importedCoverFile
            oldImages.forEach(ImageStore.shared.delete(named:))
            oldProfileImages.forEach(ImageStore.shared.delete(named:))
            pendingImport = nil
        } catch {
            context.rollback()
            newImages.forEach(ImageStore.shared.delete(named:))
            present("备份导入失败，原有内容已保留。")
        }
    }

    private func present(_ message: String) { errorMessage = message; isShowingError = true }
}

private struct RecapSheet: View {
    let records: [MediaItem]
    @State private var categoryStore = MediaCategoryStore.shared
    private let year = Calendar.current.component(.year, from: .now)
    private var thisYear: [MediaItem] { records.filter { Calendar.current.component(.year, from: $0.recordDate) == year } }

    private var categoryStats: [RecapStatistic] {
        topCounts(thisYear.map { categoryStore.category(for: $0.categoryID).title }, limit: 20)
    }
    private var tagStats: [RecapStatistic] { topCounts(thisYear.flatMap(\.tags)) }
    private var moodStats: [RecapStatistic] { topCounts(thisYear.map(\.mood).filter { !$0.isEmpty }) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(year) 年度回顾").font(.system(size: 24, weight: .regular, design: .serif))
                Text("\(thisYear.count) 条今年留下的记忆").font(.system(size: 13)).foregroundStyle(Theme.Palette.muted)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        let count = thisYear.filter { Calendar.current.component(.month, from: $0.recordDate) == month }.count
                        VStack(spacing: 5) {
                            Text("\(count)").font(.system(size: 9)).foregroundStyle(Theme.Palette.muted)
                            RoundedRectangle(cornerRadius: 3).fill(Theme.Palette.accent.opacity(count == 0 ? 0.12 : 0.8))
                                .frame(height: CGFloat(max(count == 0 ? 4 : 9, min(78, count * 14))))
                            Text("\(month)").font(.system(size: 8)).foregroundStyle(Theme.Palette.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                statisticGroup("分类", stats: categoryStats)
                statisticGroup("标签", stats: tagStats)
                statisticGroup("心情", stats: moodStats)
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.Palette.paper).presentationDetents([.medium, .large])
    }

    private func statisticGroup(_ title: String, stats: [RecapStatistic]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.Palette.ink)
            if stats.isEmpty {
                Text("暂无数据").font(.system(size: 11)).foregroundStyle(Theme.Palette.muted)
            } else {
                ForEach(stats) { stat in
                    HStack(spacing: 9) {
                        Text(stat.name).font(.system(size: 11)).foregroundStyle(Theme.Palette.filterText)
                            .lineLimit(1).frame(width: 82, alignment: .leading)
                        GeometryReader { proxy in
                            Capsule().fill(Theme.Palette.soft)
                                .overlay(alignment: .leading) {
                                    Capsule().fill(Theme.Palette.accent.opacity(0.75))
                                        .frame(width: max(5, proxy.size.width * CGFloat(stat.count) / CGFloat(stats[0].count)))
                                }
                        }
                        .frame(height: 6)
                        Text("\(stat.count)").font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Theme.Palette.muted).frame(width: 22, alignment: .trailing)
                    }
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.Palette.hairline))
    }

    private func topCounts(_ values: [String], limit: Int = 6) -> [RecapStatistic] {
        var counts: [String: Int] = [:]
        values.forEach { counts[$0, default: 0] += 1 }
        return counts.map { RecapStatistic(name: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.name.localizedCompare($1.name) == .orderedAscending : $0.count > $1.count }
            .prefix(limit).map { $0 }
    }
}

private struct RecapStatistic: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

private struct BackupPayload: Codable {
    var records: [BackupRecord]
    var collections: [BackupCollection]
    var profileName: String
    var profileBio: String
    var profileAvatar: Data?
    var profileCover: Data?
}
private struct BackupRecord: Codable {
    var id: UUID; var title: String; var creator: String; var categoryID: String; var rating: Int
    var note: String; var mood: String; var collectionID: UUID?; var tags: [String]; var recordDate: Date; var image: Data?
}
private struct BackupCollection: Codable { var id: UUID; var name: String }

private struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let payload: BackupPayload
    init(payload: BackupPayload) { self.payload = payload }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        payload = try JSONDecoder().decode(BackupPayload.self, from: data)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try JSONEncoder().encode(payload))
    }
}
