//
//  ScrollableList.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct ScrollableList<Content: View>: View {
    let itemCount: Int
    let rowHeight: CGFloat
    let isScrollable: Bool
    @ViewBuilder let content: () -> Content
    
    init(
        itemCount: Int,
        rowHeight: CGFloat = 62,
        isScrollable: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.itemCount = itemCount
        self.rowHeight = rowHeight
        self.isScrollable = isScrollable
        self.content = content
    }
    
    var body: some View {
        List {
            content()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(!isScrollable)
        .frame(height: isScrollable ? nil : CGFloat(itemCount) * rowHeight)
    }
}

