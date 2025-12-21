//
//  AddAssetView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData

struct AddAssetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    @State private var name: String = ""
    @State private var initialValue: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, value
    }
    
    var body: some View {
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
                        Text("Create a new asset")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // Asset Name section
                        TextField("Asset Name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 22, weight: .bold))
                            .focused($focusedField, equals: .name)
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        // Initial Value section
                        TextField("Initial Value", text: $initialValue)
                            .textFieldStyle(.plain)
                            .font(.system(size: 22, weight: .bold))
                            .focused($focusedField, equals: .value)
                            .keyboardType(.decimalPad)
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
                        saveAsset()
                    }, isEnabled: !name.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // Automatically focus the first text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .name
                }
            }
        }
    }
    
    private func saveAsset() {
        let asset = Asset(name: name)
        modelContext.insert(asset)
        
        // Add initial value if provided
        if let valueString = Double(initialValue), valueString > 0 {
            let value = Decimal(valueString)
            let assetValue = AssetValue(value: value, asset: asset)
            modelContext.insert(assetValue)
        }
        
        // Explicitly save to ensure changes are persisted and observable
        try? modelContext.save()
        updateWidgetData()
        dismiss()
    }
    
    private func updateWidgetData() {
        // Query assets to calculate net worth
        let descriptor = FetchDescriptor<Asset>()
        if let assets = try? modelContext.fetch(descriptor) {
            let totalNetWorth = assets.compactMap { $0.currentValue }.reduce(0, +)
            let historicalValues = calculateHistoricalNetWorth(assets: assets)
            
            WidgetDataHelper.saveNetWorthData(
                currentValue: totalNetWorth,
                historicalValues: historicalValues,
                currencyCode: currencyManager.selectedCurrencyCode,
                isAnonymized: currencyManager.isAnonymized
            )
        }
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
