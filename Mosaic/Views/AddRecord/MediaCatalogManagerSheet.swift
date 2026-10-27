import SwiftUI
import SwiftData

struct MediaCatalogManagerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var records: [MediaItem]
    @State private var store: MediaCatalogStore
    @State private var selectedTab = 0
    @State private var newName = ""

    init(store: MediaCatalogStore = .shared) { _store = State(initialValue: store) }

    private var values: [String] { selectedTab == 0 ? store.tags : store.moods }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("管理选项").font(.system(size: 20, weight: .regular, design: .serif))
                Spacer()
                Button("完成") { dismiss() }.font(.system(size: 12)).foregroundStyle(Theme.Palette.muted)
            }
            Picker("管理类型", selection: $selectedTab) {
                Text("标签").tag(0)
                Text("心情").tag(1)
            }
            .pickerStyle(.segmented)

            if values.isEmpty {
                ContentUnavailableView(selectedTab == 0 ? "还没有标签" : "还没有心情选项", systemImage: "tag")
            } else {
                List {
                    ForEach(values, id: \.self) { value in
                        HStack {
                            Text(value)
                            Spacer()
                            Button(role: .destructive) {
                                if selectedTab == 0 {
                                    store.removeTag(value)
                                    for record in records {
                                        record.tags.removeAll { $0.localizedCaseInsensitiveCompare(value) == .orderedSame }
                                    }
                                } else {
                                    store.removeMood(value)
                                    for record in records where record.mood.localizedCaseInsensitiveCompare(value) == .orderedSame {
                                        record.mood = ""
                                    }
                                }
                                try? context.save()
                            } label: { Image(systemName: "minus.circle.fill") }
                                .buttonStyle(.plain)
                                .accessibilityLabel("删除\(value)")
                        }
                        .listRowBackground(Theme.Palette.surface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            HStack(spacing: 8) {
                TextField("新建名称", text: $newName)
                    .padding(11).background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: 10))
                Button("创建") {
                    if selectedTab == 0 { store.addTag(newName) } else { store.addMood(newName) }
                    newName = ""
                }
                .font(.system(size: 11, weight: .medium)).foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Theme.Palette.accent, in: Capsule())
            }
        }
        .padding(20)
        .background(Theme.Palette.paper)
    }
}
