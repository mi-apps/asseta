//
//  EditValueView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData

struct EditValueView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    let assetValue: AssetValue
    @State private var value: String = "0"
    @State private var selectedDate: Date = Date()
    
    init(assetValue: AssetValue) {
        self.assetValue = assetValue
    }
    
    private var displayValue: String {
        if value == "0" {
            return formatCurrency(0)
        }
        if let doubleValue = Double(value) {
            return formatCurrency(Decimal(doubleValue))
        }
        return formatCurrency(0)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        currencyManager.formatCurrency(value)
    }
    
    private func canAddDecimal() -> Bool {
        guard value.contains(".") else { return true }
        let parts = value.split(separator: ".")
        return parts.count == 2 && parts[1].count < 2
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - Fixed at top
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
                    Text("Edit Value")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .padding(.top, 20)
                }
                .padding(.bottom, 20)
                
                // Centered content area
                Spacer()
                VStack(spacing: 24) {
                    // Date Picker
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    
                    // Value Display
                    Text(displayValue)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.appPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                Spacer()
                
                // Number Pad - Full width above save button
                VStack(spacing: 0) {
                    NumberPad(
                        onNumberTap: { number in
                            if number == "." {
                                // Only allow one decimal point and max 2 decimals
                                if canAddDecimal() && !value.contains(".") {
                                    if value == "0" {
                                        value = "0."
                                    } else {
                                        value += number
                                    }
                                }
                            } else {
                                // Check if we can add more digits (max 2 after decimal)
                                if value.contains(".") {
                                    let parts = value.split(separator: ".")
                                    if parts.count == 2 && parts[1].count >= 2 {
                                        return // Don't add more than 2 decimal places
                                    }
                                }
                                
                                if value == "0" {
                                    value = number
                                } else {
                                    value += number
                                }
                            }
                        },
                        onDelete: {
                            if value.count > 1 {
                                value.removeLast()
                            } else {
                                value = "0"
                            }
                        }
                    )
                    .padding(.vertical, 20)
                    .padding(.horizontal)
                }
                
                // Save Button - Fixed at bottom
                VStack(spacing: 0) {
                    Divider()
                    PrimaryButton(title: "Save", action: {
                        saveValue()
                    }, isEnabled: value != "0" && Double(value) != nil && (Double(value) ?? 0) > 0)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // Initialize with existing values
                let nsDecimal = assetValue.value as NSDecimalNumber
                value = nsDecimal.stringValue
                selectedDate = assetValue.date
            }
        }
    }
    
    private func saveValue() {
        if let valueDouble = Double(value), valueDouble > 0 {
            assetValue.value = Decimal(valueDouble)
            assetValue.date = selectedDate
            // Explicitly save to ensure changes are persisted and observable
            try? modelContext.save()
            dismiss()
        }
    }
}

