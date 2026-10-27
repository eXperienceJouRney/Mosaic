//
//  ContentView.swift
//  Mosaic
//
//  Created by RayTse.
//
//  四页的结构：底部导航在 Gallery / Timeline / Collections / Profile 之间切换。
//  每页各自持有一个 NavigationStack，导航条只挂在页面的根视图上，
//  因此进入当天记录 / 作品详情后会自动隐藏；TabView 负责保留各页的浏览状态。
//

import SwiftUI

struct ContentView: View {
    @State private var tab: MosaicTab = .gallery

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                CalendarGalleryView(isActive: tab == .gallery)
            }
            .tag(MosaicTab.gallery)

            NavigationStack {
                CollectionsHomeView()
            }
            .tag(MosaicTab.collections)

            NavigationStack {
                TimelineView()
            }
            .tag(MosaicTab.timeline)

            NavigationStack {
                ProfileView()
            }
            .tag(MosaicTab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MosaicTabBar(selection: $tab)
        }
        .tint(Theme.Palette.accent)
    }
}

#Preview("Mosaic") {
    ContentView()
        .modelContainer(MosaicContainer.preview)
}
