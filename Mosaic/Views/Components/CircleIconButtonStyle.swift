//
//  CircleIconButtonStyle.swift
//  Mosaic
//
//  30×30 圆形图标按钮，按下时出现柔面底色。
//  月份切换与年份切换共用这一套外观，保证两页顶栏完全一致。
//

import SwiftUI

struct CircleIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 30, height: 30)
            .background(configuration.isPressed ? Theme.Palette.soft : Color.clear, in: Circle())
            .contentShape(Circle())
    }
}
