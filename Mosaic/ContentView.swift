//
//  ContentView.swift
//  Mosaic
//
//  Created by RayTse.
//
//  两页的结构：底部导航在 Gallery / Timeline 之间切换。
//  每页各自持有一个 NavigationStack，导航条只挂在页面的根视图上，
//  因此进入当天记录 / 作品详情后会自动隐藏；TabView 负责保留各页的浏览状态。
//

import SwiftUI

struct ContentView: View {
    @State private var tab: MosaicTab = .gallery

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                CalendarGalleryView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        MosaicTabBar(selection: $tab)
                    }
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(MosaicTab.gallery)

            NavigationStack {
                TimelineView()
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        MosaicTabBar(selection: $tab)
                    }
            }
            .toolbar(.hidden, for: .tabBar)
            .tag(MosaicTab.timeline)
        }
        .tint(Theme.Palette.accent)
    }
}

#Preview("Mosaic") {
    ContentView()
        .modelContainer(MosaicContainer.preview)
}
