//
//  HomeView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Asset.createdDate, order: .reverse) private var assets: [Asset]
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    @State private var showingAddAsset = false
    @State private var selectedAsset: Asset?
    @State private var selectedNetWorth: Decimal?
    @State private var showingAddValue = false
    @State private var showingEditName = false
    @State private var showingDeleteConfirmation = false
    @State private var assetToEdit: Asset?
    @State private var assetToAddValue: Asset?
    @State private var assetToDelete: Asset?
    @State private var editedName: String = ""
    @FocusState private var isEditNameFocused: Bool
    @State private var showPercentageChange = true
    @State private var selectedPeriod: Period = .month
    
    var totalNetWorth: Decimal {
        assets.compactMap { $0.currentValue }.reduce(0, +)
    }
    
    var sortedAssets: [Asset] {
        assets.sorted { asset1, asset2 in
            let value1 = asset1.currentValue ?? 0
            let value2 = asset2.currentValue ?? 0
            return value1 > value2
        }
    }
    
    func percentage(for asset: Asset) -> Double {
        guard let currentValue = asset.currentValue, totalNetWorth > 0 else { return 0 }
        return Double(truncating: (currentValue / totalNetWorth * 100) as NSDecimalNumber)
    }
    
    func historicalValues(for asset: Asset) -> [(Date, Decimal)] {
        guard let values = asset.values else { return [] }
        return values.sorted { $0.date < $1.date }.map { ($0.date, $0.value) }
    }
    
    var historicalNetWorth: [(Date, Decimal)] {
        // Get all unique dates from all asset values
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
        
        // Periods are bins, not filters - use all dates
        // If no dates, return entries from 7 days ago to today with 0 net worth
        guard !allDates.isEmpty else {
            if let pastDate = calendar.date(byAdding: .day, value: -7, to: todayStart) {
                return [(pastDate, 0), (todayStart, 0)]
            }
            return [(todayStart, 0)]
        }
        
        // Sort dates
        let sortedDates = allDates.sorted()
        
        // Calculate net worth for each date
        var netWorthOverTime: [(Date, Decimal)] = []
        for date in sortedDates {
            var total: Decimal = 0
            for asset in assets {
                // Find the most recent value for this asset at or before this date
                if let values = asset.values {
                    let valuesBeforeDate = values.filter { $0.date <= date }
                    if let mostRecentValue = valuesBeforeDate.sorted(by: { $0.date > $1.date }).first {
                        total += mostRecentValue.value
                    }
                }
            }
            netWorthOverTime.append((date, total))
        }
        
        // If only one value, generate data from that date to today
        if netWorthOverTime.count == 1 {
            let singleValue = netWorthOverTime.first!
            let startDate = calendar.startOfDay(for: singleValue.0)
            var extendedData: [(Date, Decimal)] = []
            
            // If the value was added today, go back 7 days to create a range
            if calendar.isDate(startDate, inSameDayAs: todayStart) {
                if let pastDate = calendar.date(byAdding: .day, value: -7, to: todayStart) {
                    extendedData.append((pastDate, singleValue.1))
                }
            } else {
                // Add the original date
                extendedData.append((startDate, singleValue.1))
            }
            
            // Always add today
            extendedData.append((todayStart, singleValue.1))
            
            return extendedData
        }
        
        // Always ensure today is included as the last point
        let lastDate = netWorthOverTime.last?.0 ?? todayStart
        if !calendar.isDate(lastDate, inSameDayAs: todayStart) {
            // Calculate current net worth
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Net Worth Value
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formatCurrency(selectedNetWorth ?? totalNetWorth))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let change = calculateChange(currentValue: selectedNetWorth ?? totalNetWorth) {
                            Button(action: {
                                showPercentageChange.toggle()
                            }) {
                                Text(showPercentageChange ? formatPercentage(change.percentage) : formatAbsoluteChange(change.absolute))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(change.absolute >= 0 ? Color(red: 0, green: 0.6, blue: 0) : Color(red: 0.8, green: 0, blue: 0))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.horizontal)
                    
                    // Period Selector
                    PeriodSelector(selectedPeriod: $selectedPeriod)
                        .padding(.top, 4)
                    
                    // Net Worth Chart
                    if !historicalNetWorth.isEmpty {
                        ValueChart(values: historicalNetWorth, selectedValue: $selectedNetWorth, selectedPeriod: $selectedPeriod)
                            .frame(height: 200)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                    
                    // Assets Title
                    HStack {
                        Text("Assets")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Assets List
                    if sortedAssets.isEmpty {
                        VStack(spacing: 8) {
                            Text("No assets yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Create your first asset below")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    } else {
                        ScrollableList(itemCount: sortedAssets.count, rowHeight: 66) {
                            ForEach(sortedAssets) { asset in
                                Button {
                                    selectedAsset = asset
                                } label: {
                                    AssetCard(
                                        asset: asset,
                                        percentage: percentage(for: asset),
                                        historicalValues: historicalValues(for: asset),
                                        formatCurrency: formatCurrency
                                    )
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color(.systemGroupedBackground))
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    // Delete action (swipe right)
                                    Button(role: .destructive) {
                                        assetToDelete = asset
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .tint(Color(red: 0.7, green: 0.1, blue: 0.1))
                                    
                                    // Edit Name action (swipe right)
                                    Button {
                                        assetToEdit = asset
                                        editedName = asset.name
                                        showingEditName = true
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.appWarning)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    // Set Value action (swipe left)
                                    Button {
                                        assetToAddValue = asset
                                    } label: {
                                        Image(systemName: "plus.circle")
                                    }
                                    .tint(.appPrimary)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Create Asset Button
                    PrimaryButton(title: "Create Asset", action: {
                        showingAddAsset = true
                    })
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .padding(.bottom, 20)
                }
                .padding(.top)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Net Worth")
            .navigationDestination(item: $selectedAsset) { asset in
                AssetDetailView(asset: asset)
            }
            .sheet(isPresented: $showingAddAsset) {
                AddAssetView()
            }
            .sheet(item: $assetToAddValue) { asset in
                SetValueView(asset: asset)
            }
            .sheet(isPresented: $showingEditName) {
                NavigationStack {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 32) {
                                // Scroll indicator
                                HStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 36, height: 5)
                                    Spacer()
                                }
                                .padding(.top, 8)
                                
                                // Big header
                                Text("Editing Asset")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                    .padding(.top, 20)
                                
                                // Asset Name section
                                TextField("Asset Name", text: $editedName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 22, weight: .bold))
                                    .focused($isEditNameFocused)
                                    .padding()
                                    .background(Color(.systemGroupedBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                            .padding(.bottom, 20)
                        }
                        
                        // Save Button - Fixed at bottom
                        VStack(spacing: 0) {
                            Divider()
                            PrimaryButton(title: "Save", action: {
                                updateAssetName()
                            }, isEnabled: !editedName.isEmpty)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .onAppear {
                        // Automatically focus the text field when view appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isEditNameFocused = true
                        }
                    }
                }
            }
            .overlay {
                if showingDeleteConfirmation {
                    DeleteConfirmationPopup(
                        isPresented: $showingDeleteConfirmation,
                        title: "Delete Asset",
                        message: "This action cannot be reverted and the data will be gone",
                        onConfirm: {
                            confirmDeleteAsset()
                            showingDeleteConfirmation = false
                        },
                        onCancel: {
                            assetToDelete = nil
                            showingDeleteConfirmation = false
                        }
                    )
                }
            }
            .onChange(of: assets) { _, _ in
                updateWidgetData()
            }
            .onAppear {
                updateWidgetData()
            }
            .onChange(of: totalNetWorth) { _, _ in
                updateWidgetData()
            }
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        currencyManager.formatCurrency(value)
    }
    
    private struct Change {
        let percentage: Double
        let absolute: Decimal
    }
    
    private func calculateChange(currentValue: Decimal) -> Change? {
        guard let firstValue = historicalNetWorth.first?.1,
              firstValue > 0 else { return nil }
        let absoluteChange = currentValue - firstValue
        let percentageChange = (absoluteChange / firstValue * 100)
        return Change(
            percentage: Double(truncating: percentageChange as NSDecimalNumber),
            absolute: absoluteChange
        )
    }
    
    private func formatPercentage(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
    
    private func formatAbsoluteChange(_ value: Decimal) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(formatCurrency(abs(value)))"
    }
    
    private func confirmDeleteAsset() {
        guard let asset = assetToDelete else { return }
        modelContext.delete(asset)
        assetToDelete = nil
    }
    
    private func updateAssetName() {
        guard let asset = assetToEdit else { return }
        asset.name = editedName
        
        editedName = ""
        showingEditName = false
        assetToEdit = nil
        updateWidgetData()
    }
    
    private func updateWidgetData() {
        WidgetDataHelper.saveNetWorthData(
            currentValue: totalNetWorth,
            historicalValues: historicalNetWorth,
            currencyCode: currencyManager.selectedCurrencyCode,
            isAnonymized: currencyManager.isAnonymized
        )
    }
}




#Preview {
    HomeView()
        .modelContainer(for: [Asset.self, AssetValue.self], inMemory: true)
}
