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
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            // Footer spacer to prevent cutoff
            if !isScrollable {
                Color.clear
                    .frame(height: 0)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(!isScrollable)
        .frame(height: isScrollable ? nil : CGFloat(itemCount) * rowHeight + 8)
    }
}

