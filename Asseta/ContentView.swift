//
//  ContentView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.createdDate, order: .reverse) private var assets: [Asset]
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Net Worth", systemImage: "dollarsign.circle.fill")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.appPrimary)
        .onAppear {
            ensureWidgetDataExists()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Refresh widget data when app becomes active
            // This handles cold start scenarios where widget loads before app writes data
            if newPhase == .active {
                ensureWidgetDataExists()
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadTimelines(ofKind: "AssetaWidget")
                #endif
            }
        }
    }
    
    private func ensureWidgetDataExists() {
        // Check if widget data already exists
        if WidgetDataHelper.loadNetWorthData() != nil {
            // Update with real data if we have assets
            if !assets.isEmpty {
                updateWithRealData()
            }
            return
        }
        
        // If no widget data exists, but we have assets, write the data
        if !assets.isEmpty {
            updateWithRealData()
        } else {
            // Write empty data so widget knows the app group is working
            WidgetDataHelper.saveNetWorthData(
                currentValue: 0,
                historicalValues: [],
                currencyCode: currencyManager.selectedCurrencyCode,
                isAnonymized: currencyManager.isAnonymized
            )
        }
    }
    
    private func updateWithRealData() {
        let totalNetWorth = assets.compactMap { $0.currentValue }.reduce(0, +)
        let historicalValues = calculateHistoricalNetWorth(assets: assets)
        
        WidgetDataHelper.saveNetWorthData(
            currentValue: totalNetWorth,
            historicalValues: historicalValues,
            currencyCode: currencyManager.selectedCurrencyCode,
            isAnonymized: currencyManager.isAnonymized
        )
    }
    
    private func calculateHistoricalNetWorth(assets: [Asset]) -> [(Date, Decimal)] {
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
        
        let lastDate = netWorthOverTime.last?.0 ?? todayStart
        if !calendar.isDate(lastDate, inSameDayAs: todayStart) {
            var currentTotal: Decimal = 0
            for asset in assets {
                if let currentValue = asset.currentValue {
                    currentTotal += currentValue
                }
            }
            netWorthOverTime.append((todayStart, currentTotal))
        }
        
        return netWorthOverTime
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Asset.self, AssetValue.self], inMemory: true)
}