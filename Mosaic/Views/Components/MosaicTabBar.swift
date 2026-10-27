//
//  MosaicTabBar.swift
//  Mosaic
//
//  底部导航：Gallery / Timeline / Collections / Profile。
//  不做系统 TabView 的外观定制，而是自绘一条纸感导航条，
//  图标也用最少的线条画出来，和参考稿的 grid / line 图标一致。
//

import SwiftUI

enum MosaicTab: Hashable {
    case gallery
    case timeline
    case collections
    case profile

    var title: String {
        switch self {
        case .gallery: return "Gallery"
        case .timeline: return "Timeline"
        case .collections: return "作品集"
        case .profile: return "Profile"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .gallery: return "galleryTabButton"
        case .timeline: return "timelineTabButton"
        case .collections: return "collectionsTabButton"
        case .profile: return "profileTabButton"
        }
    }
}

struct MosaicTabBar: View {
    @Binding var selection: MosaicTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.gallery) { GalleryTabIcon() }
            tabButton(.timeline) { TimelineTabIcon() }
            tabButton(.collections) { Image(systemName: "books.vertical") }
            tabButton(.profile) { Image(systemName: "person.crop.circle") }
        }
        .padding(.top, Theme.TabBar.top)
        .padding(.bottom, Theme.TabBar.bottom)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.Palette.hairline)
                .frame(height: Theme.TabBar.hairlineHeight)
        }
        .background(Theme.Palette.paper.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton<Icon: View>(
        _ tab: MosaicTab,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        let isSelected = selection == tab

        return Button {
            selection = tab
        } label: {
            icon()
                .font(.system(size: Theme.TabBar.iconSize, weight: .regular))
                .frame(width: Theme.TabBar.iconSize, height: Theme.TabBar.iconSize)
                .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.tabInactive)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.TabBar.hitHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.accessibilityIdentifier)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - 图标

/// 十五格的日历示意：外框 + 十字。
private struct GalleryTabIcon: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let center = side / 2

            Path { path in
                path.addRect(CGRect(x: 0.5, y: 0.5, width: side - 1, height: side - 1))
                path.move(to: CGPoint(x: center, y: 0.5))
                path.addLine(to: CGPoint(x: center, y: side - 0.5))
                path.move(to: CGPoint(x: 0.5, y: center))
                path.addLine(to: CGPoint(x: side - 0.5, y: center))
            }
            .stroke(lineWidth: 1)
        }
    }
}

/// 一条竖线加两个节点，示意时间轴。
private struct TimelineTabIcon: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let x = side * 0.3

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .frame(width: 1, height: side)
                    .position(x: x, y: side / 2)

                Circle()
                    .strokeBorder(lineWidth: 1)
                    .frame(width: side * 0.34, height: side * 0.34)
                    .position(x: x, y: side * 0.32)

                Circle()
                    .frame(width: side * 0.18, height: side * 0.18)
                    .position(x: x, y: side * 0.78)
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        Spacer()
        MosaicTabBarPreviewHost()
    }
    .background(Theme.Palette.paper)
}

private struct MosaicTabBarPreviewHost: View {
    @State private var selection: MosaicTab = .gallery

    var body: some View {
        MosaicTabBar(selection: $selection)
    }
}
