//
//  AnalyticsView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Asset.createdDate, order: .reverse) private var assets: [Asset]
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    var totalNetWorth: Decimal {
        assets.compactMap { $0.currentValue }.reduce(0, +)
    }
    
    private var rawHistoricalNetWorth: [(Date, Decimal)] {
        // Get all unique dates from all asset values (no period filtering)
        var allDates: Set<Date> = []
        for asset in assets {
            if let values = asset.values {
                for value in values {
                    allDates.insert(value.date)
                }
            }
        }
        
        let today = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        
        guard !allDates.isEmpty else {
            if let pastDate = calendar.date(byAdding: .day, value: -7, to: todayStart) {
                return [(pastDate, 0), (todayStart, 0)]
            }
            return [(todayStart, 0)]
        }
        
        let sortedDates = allDates.sorted()
        var netWorthOverTime: [(Date, Decimal)] = []
        
        for date in sortedDates {
            var total: Decimal = 0
            for asset in assets {
                if let values = asset.values {
                    let valuesBeforeDate = values.filter { $0.date <= date }
                    if let mostRecentValue = valuesBeforeDate.sorted(by: { $0.date > $1.date }).first {
                        total += mostRecentValue.value
                    }
                }
            }
            netWorthOverTime.append((date, total))
        }
        
        // Always ensure today is included
        let lastDate = netWorthOverTime.last?.0 ?? todayStart
        if !calendar.isDate(lastDate, inSameDayAs: todayStart) {
            netWorthOverTime.append((todayStart, totalNetWorth))
        }
        
        return netWorthOverTime
    }
    
    var historicalNetWorth: [(Date, Decimal)] {
        // Use all data, aggregate for display
        let aggregated = AnalyticsHelper.aggregateForAllTime(values: rawHistoricalNetWorth, calendar: .current)
        return aggregated
    }
    
    var totalChangeSinceStart: Decimal? {
        guard rawHistoricalNetWorth.first != nil else { return nil }
        let firstValue = rawHistoricalNetWorth.first?.1 ?? 0
        return totalNetWorth - firstValue
    }
    
    var percentageChangeSinceStart: Double? {
        guard rawHistoricalNetWorth.first != nil else { return nil }
        let firstValue = rawHistoricalNetWorth.first?.1 ?? 0
        guard firstValue > 0 else { return nil }
        let change = (totalNetWorth - firstValue) / firstValue * 100
        return Double(truncating: change as NSDecimalNumber)
    }
    
    var yearOverYearChange: (absolute: Decimal, percentage: Double)? {
        guard !rawHistoricalNetWorth.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let today = Date()
        let sorted = rawHistoricalNetWorth.sorted { $0.0 < $1.0 }
        
        // Check if we only have one year of data
        let years = Set(sorted.map { calendar.component(.year, from: $0.0) })
        let hasMultipleYears = years.count > 1
        
        let netWorthOneYearAgo: Decimal
        if hasMultipleYears {
            // Use actual data from one year ago
            guard let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) else { return nil }
            let valuesOneYearAgo = sorted.filter { $0.0 <= oneYearAgo }
            netWorthOneYearAgo = valuesOneYearAgo.last?.1 ?? 0
        } else {
            // Only one year of data - assume last year was 0
            netWorthOneYearAgo = 0
        }
        
        let absoluteChange = totalNetWorth - netWorthOneYearAgo
        
        // Calculate percentage change
        // If net worth one year ago was 0, percentage is infinite/undefined, so show absolute change only
        let percentageDouble: Double
        if netWorthOneYearAgo > 0 {
            let percentageChange = (absoluteChange / netWorthOneYearAgo * 100)
            percentageDouble = Double(truncating: percentageChange as NSDecimalNumber)
        } else {
            // If starting from 0, we can't calculate a meaningful percentage
            // Return a very large number to indicate "from zero"
            percentageDouble = totalNetWorth > 0 ? 999999.0 : 0.0
        }
        
        return (absoluteChange, percentageDouble)
    }
    
    var averageYearlyPercentageIncrease: Double? {
        guard !rawHistoricalNetWorth.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let sorted = rawHistoricalNetWorth.sorted { $0.0 < $1.0 }
        
        // Group by year and get the latest value for each year
        var yearEndValues: [(year: Int, value: Decimal)] = []
        let years = Set(sorted.map { calendar.component(.year, from: $0.0) }).sorted()
        
        for year in years {
            // Get all values in this year
            let valuesInYear = sorted.filter { calendar.component(.year, from: $0.0) == year }
            if let latestInYear = valuesInYear.last {
                yearEndValues.append((year: year, value: latestInYear.1))
            }
        }
        
        // Sort by year to ensure chronological order
        yearEndValues.sort { $0.year < $1.year }
        
        // If only one year, return the year-over-year change (assuming previous year was 0)
        if yearEndValues.count == 1 {
            // Use the same calculation as yearOverYearChange
            // Since we assume previous year was 0, we can't calculate a meaningful percentage
            // Return nil so we don't show an invalid percentage
            return nil
        }
        
        // Calculate year-over-year percentage changes for multiple years
        var yearlyChanges: [Double] = []
        for i in 1..<yearEndValues.count {
            let previousValue = yearEndValues[i - 1].value
            let currentValue = yearEndValues[i].value
            
            if previousValue > 0 {
                let change = (currentValue - previousValue) / previousValue * 100
                yearlyChanges.append(Double(truncating: change as NSDecimalNumber))
            }
        }
        
        // Return average if we have at least one year-over-year change
        guard yearlyChanges.count > 0 else { return nil }
        let average = yearlyChanges.reduce(0, +) / Double(yearlyChanges.count)
        return average
    }
    
    @State private var selectedNetWorth: Decimal?
    @State private var showPercentageChange = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Insights Title
                    HStack {
                        Text("Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Insights Metrics
                    VStack(spacing: 12) {
                        // Percentage Change (since start)
                        if let percentageChange = percentageChangeSinceStart {
                            InsightCard(
                                icon: percentageChange >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                                title: "Total Change",
                                message: "\(formatPercentage(percentageChange)) since you started tracking"
                            )
                        }
                        
                        // Total Increase
                        if let totalChange = totalChangeSinceStart, totalChange != 0 {
                            InsightCard(
                                icon: totalChange >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                                title: totalChange >= 0 ? "Total Increase" : "Total Decrease",
                                message: "\(formatCurrencyChange(totalChange)) since you started tracking"
                            )
                        }
                        
                        // Yearly Absolute Change
                        if let yoyChange = yearOverYearChange, yoyChange.absolute != 0 {
                            InsightCard(
                                icon: yoyChange.absolute >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill",
                                title: "Year Over Year",
                                message: "\(formatCurrencyChange(yoyChange.absolute)) change from last year"
                            )
                        }
                        
                        // Average Yearly Percentage Increase
                        if let avgYearlyPercentage = averageYearlyPercentageIncrease {
                            InsightCard(
                                icon: avgYearlyPercentage >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis",
                                title: "Average Yearly Growth",
                                message: "\(formatPercentage(avgYearlyPercentage)) average yearly increase"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Net Worth Over Time Title
                    HStack {
                        Text("Net Worth over time")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Net Worth Over Time Chart
                    if !historicalNetWorth.isEmpty {
                        ValueChart(
                            values: historicalNetWorth,
                            selectedValue: $selectedNetWorth,
                            selectedPeriod: Binding(
                                get: { .allTime },
                                set: { _ in }
                            )
                        )
                        .frame(height: 200)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }
                .padding(.top)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
        }
    }
    
    private struct Change {
        let percentage: Double
        let absolute: Decimal
    }
    
    private func calculateChange(currentValue: Decimal) -> Change? {
        guard let firstValue = rawHistoricalNetWorth.first?.1,
              firstValue > 0 else { return nil }
        let absoluteChange = currentValue - firstValue
        let percentageChange = (absoluteChange / firstValue * 100)
        return Change(
            percentage: Double(truncating: percentageChange as NSDecimalNumber),
            absolute: absoluteChange
        )
    }
    
    private func formatCurrencyChange(_ value: Decimal) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(formatCurrency(abs(value)))"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
    
    private func formatAbsoluteChange(_ value: Decimal) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(formatCurrency(abs(value)))"
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        currencyManager.formatCurrency(value)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Asset.self, AssetValue.self], inMemory: true)
}
