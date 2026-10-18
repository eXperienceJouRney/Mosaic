//
//  WeekdayHeaderView.swift
//  Mosaic
//

import SwiftUI

struct WeekdayHeaderView: View {
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: Theme.Grid.spacing),
        count: Theme.Grid.columnCount
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(MosaicCalendar.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(Theme.Typography.weekday)
                    .foregroundStyle(Theme.Palette.weekdayLabel)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    WeekdayHeaderView()
        .padding()
        .background(Theme.Palette.paper)
}
