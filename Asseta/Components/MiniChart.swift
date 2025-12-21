//
//  MiniChart.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import Charts

struct MiniChart: View {
    let values: [(Date, Decimal)]
    let isFlat: Bool
    
    var body: some View {
        if isFlat || values.count <= 1 {
            // Draw a straight line for flat or single value
            GeometryReader { geometry in
                Path { path in
                    let y = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.appPrimary, lineWidth: 2)
            }
        } else {
            // Draw a line chart
            Chart {
                ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", Double(truncating: item.1 as NSDecimalNumber))
                    )
                    .foregroundStyle(Color.appPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: minValue...maxValue)
        }
    }
    
    private var minValue: Double {
        let nums = values.map { Double(truncating: $0.1 as NSDecimalNumber) }
        return (nums.min() ?? 0) * 0.95 // Add small padding
    }
    
    private var maxValue: Double {
        let nums = values.map { Double(truncating: $0.1 as NSDecimalNumber) }
        return (nums.max() ?? 0) * 1.05 // Add small padding
    }
}

