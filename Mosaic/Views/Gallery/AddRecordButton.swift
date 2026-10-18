//
//  AddRecordButton.swift
//  Mosaic
//
//  右下角添加按钮。深色圆形，轻阴影，尺寸 48pt。
//

import SwiftUI

struct AddRecordButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(Theme.Typography.fab)
                .foregroundStyle(Theme.Palette.onAccent)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.Palette.accent))
                .shadow(color: .black.opacity(0.13), radius: 7.5, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("addRecordButton")
        .accessibilityLabel("添加记录")
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Theme.Palette.paper.ignoresSafeArea()
        AddRecordButton(action: {})
            .padding(24)
    }
}
