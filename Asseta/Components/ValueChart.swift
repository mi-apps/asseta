//
//  ValueChart.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import Charts

struct ValueChart: View {
    let values: [(Date, Decimal)]
    @Binding var selectedValue: Decimal?
    @Binding var selectedPeriod: Period
    
    @State private var selectedDate: Date?
    
    private var chartValues: [(Date, Decimal)] {
        // Aggregation now handles single values and creates flat lines
        return AnalyticsHelper.aggregateByPeriod(values: values, period: selectedPeriod)
    }
    
    private var firstValue: Decimal {
        chartValues.first?.1 ?? 0
    }
    
    private var percentageChange: Double {
        guard let first = chartValues.first?.1,
              let last = chartValues.last?.1,
              first > 0 else { return 0 }
        let change = (last - first) / first * 100
        return Double(truncating: change as NSDecimalNumber)
    }
    
    private var minPercentage: Double {
        let nums = chartValues.map { value in
            guard firstValue > 0 else { return 0.0 }
            let change = (value.1 - firstValue) / firstValue * 100
            return Double(truncating: change as NSDecimalNumber)
        }
        let min = nums.min() ?? 0
        return min * 1.1 // Add padding
    }
    
    private var maxPercentage: Double {
        let nums = chartValues.map { value in
            guard firstValue > 0 else { return 0.0 }
            let change = (value.1 - firstValue) / firstValue * 100
            return Double(truncating: change as NSDecimalNumber)
        }
        let max = nums.max() ?? 0
        return max * 1.1 // Add padding
    }
    
    var body: some View {
        Chart {
            ForEach(Array(chartValues.enumerated()), id: \.offset) { index, item in
                LineMark(
                    x: .value("Date", item.0),
                    y: .value("Value", Double(truncating: item.1 as NSDecimalNumber))
                )
                .foregroundStyle(Color.appPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                if let selectedDate = selectedDate, abs(item.0.timeIntervalSince(selectedDate)) < 86400 {
                    PointMark(
                        x: .value("Date", item.0),
                        y: .value("Value", Double(truncating: item.1 as NSDecimalNumber))
                    )
                    .foregroundStyle(Color.appPrimary)
                    .symbolSize(100)
                }
            }
            
            // Vertical line indicator for selection
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Date", selectedDate))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXSelection(value: $selectedDate)
        .onChange(of: selectedDate) { oldValue, newDate in
            if let newDate = newDate {
                // Find the closest value to the selected date (use original values, not extended)
                let closest = values.min(by: { abs($0.0.timeIntervalSince(newDate)) < abs($1.0.timeIntervalSince(newDate)) })
                selectedValue = closest?.1
            } else {
                selectedValue = nil
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisValueLabel(format: dateFormatForPeriod(selectedPeriod))
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                if let doubleValue = value.as(Double.self) {
                    // Convert absolute value to percentage change
                    let percentage = firstValue > 0 ? ((Decimal(doubleValue) - firstValue) / firstValue * 100) : 0
                    let percentageDouble = Double(truncating: percentage as NSDecimalNumber)
                    
                    AxisValueLabel {
                        Text(formatPercentage(percentageDouble))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: minValue...maxValue)
        .background(Color(.systemGroupedBackground))
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
    
    private var minValue: Double {
        let nums = chartValues.map { Double(truncating: $0.1 as NSDecimalNumber) }
        let min = nums.min() ?? 0
        if min == 0 {
            return -100 // Add padding below zero
        }
        return min * 0.95 // Add small padding
    }
    
    private var maxValue: Double {
        let nums = chartValues.map { Double(truncating: $0.1 as NSDecimalNumber) }
        let max = nums.max() ?? 0
        if max == 0 {
            return 100 // Add padding above zero
        }
        return max * 1.05 // Add small padding
    }
    
    private func dateFormatForPeriod(_ period: Period) -> Date.FormatStyle {
        switch period {
        case .week:
            return .dateTime.month().day()
        case .month:
            return .dateTime.month().day()
        case .year:
            return .dateTime.month().year()
        case .allTime:
            return .dateTime.month().year()
        }
    }
}

