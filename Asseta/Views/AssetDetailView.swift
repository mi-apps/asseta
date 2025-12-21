//
//  AssetDetailView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData
import Charts

struct AssetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var currencyManager = CurrencyManager.shared
    let asset: Asset
    
    @State private var showingAddValue = false
    @State private var selectedValue: Decimal?
    @State private var showingDeleteConfirmation = false
    @State private var assetValueToDelete: AssetValue?
    @State private var assetValueToEdit: AssetValue?
    @State private var showPercentageChange = true
    @State private var selectedPeriod: Period = .month
    
    // Query all asset values to ensure SwiftUI observes changes
    @Query(sort: \AssetValue.date, order: .reverse) private var allAssetValues: [AssetValue]
    
    private var sortedValues: [AssetValue] {
        allAssetValues.filter { $0.asset?.persistentModelID == asset.persistentModelID }
    }
    
    private var historicalValues: [(Date, Decimal)] {
        // Periods are bins, not filters - use all values
        return sortedValues.sorted { $0.date < $1.date }.map { ($0.date, $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Asset Value
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formatCurrency(selectedValue ?? asset.currentValue ?? 0))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let change = calculateChange(currentValue: selectedValue ?? asset.currentValue ?? 0) {
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
                    
                    // Asset Value Chart - Always show, even if empty
                    ValueChart(values: historicalValues, selectedValue: $selectedValue, selectedPeriod: $selectedPeriod)
                        .frame(height: 200)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    // Historical Values Title
                    HStack {
                        Text("Historical Values")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Historical Values List
                    if sortedValues.isEmpty {
                        VStack(spacing: 8) {
                            Text("No values recorded yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Add your first value below")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ScrollableList(itemCount: sortedValues.count) {
                            ForEach(sortedValues) { assetValue in
                                AssetCard(
                                    title: formatDateMonthDay(assetValue.date),
                                    subtitle: formatDateYear(assetValue.date),
                                    value: assetValue.value,
                                    formatCurrency: formatCurrency
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color(.systemGroupedBackground))
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    // Delete action (swipe right)
                                    Button(role: .destructive) {
                                        assetValueToDelete = assetValue
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .tint(Color(red: 0.7, green: 0.1, blue: 0.1))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    // Edit action (swipe left)
                                    Button {
                                        assetValueToEdit = assetValue
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .tint(.appPrimary)
                                }
                            }
                        }
                    }
                    
                    // Set Value Button
                    PrimaryButton(title: "Set Value", action: {
                        showingAddValue = true
                    })
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .padding(.top)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(asset.name)
            .sheet(isPresented: $showingAddValue) {
                SetValueView(asset: asset)
            }
            .sheet(item: $assetValueToEdit) { assetValue in
                EditValueView(assetValue: assetValue)
            }
            .overlay {
                if showingDeleteConfirmation {
                    DeleteConfirmationPopup(
                        isPresented: $showingDeleteConfirmation,
                        title: "Delete Value",
                        message: "This action cannot be reverted and the data will be gone",
                        onConfirm: {
                            confirmDeleteValue()
                            showingDeleteConfirmation = false
                        },
                        onCancel: {
                            assetValueToDelete = nil
                            showingDeleteConfirmation = false
                        }
                    )
                }
            }
        }
    }
    
    private func confirmDeleteValue() {
        guard let assetValue = assetValueToDelete else { return }
        modelContext.delete(assetValue)
        // Explicitly save to ensure changes are persisted and observable
        try? modelContext.save()
        assetValueToDelete = nil
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        currencyManager.formatCurrency(value)
    }
    
    private func formatDateMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, d"
        return formatter.string(from: date)
    }
    
    private func formatDateYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private struct Change {
        let percentage: Double
        let absolute: Decimal
    }
    
    private func calculateChange(currentValue: Decimal) -> Change? {
        guard let firstValue = historicalValues.first?.1,
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
}

