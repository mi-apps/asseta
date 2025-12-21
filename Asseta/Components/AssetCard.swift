//
//  AssetCard.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct AssetCard: View {
    let title: String
    let subtitle: String?
    let value: Decimal?
    let formatCurrency: (Decimal) -> String
    let historicalValues: [(Date, Decimal)]?
    let percentage: Double?
    
    // Convenience initializer for asset cards
    init(
        asset: Asset,
        percentage: Double,
        historicalValues: [(Date, Decimal)],
        formatCurrency: @escaping (Decimal) -> String
    ) {
        self.title = asset.name
        self.subtitle = nil
        self.value = asset.currentValue
        self.formatCurrency = formatCurrency
        self.historicalValues = historicalValues
        self.percentage = percentage
    }
    
    // Flexible initializer for custom cards
    init(
        title: String,
        subtitle: String? = nil,
        value: Decimal? = nil,
        formatCurrency: @escaping (Decimal) -> String,
        historicalValues: [(Date, Decimal)]? = nil,
        percentage: Double? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.formatCurrency = formatCurrency
        self.historicalValues = historicalValues
        self.percentage = percentage
    }
    
    var isFlat: Bool {
        guard let historicalValues = historicalValues, historicalValues.count > 1 else { return true }
        let firstValue = historicalValues.first?.1 ?? 0
        return historicalValues.allSatisfy { abs($0.1 - firstValue) < 0.01 }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Column 1: Title + Subtitle/Value
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if let value = value {
                    Text(formatCurrency(value))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appPrimary)
                        .lineLimit(1)
                } else {
                    Text("No value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Column 2: Historical Graph - only if provided
            if let historicalValues = historicalValues, !historicalValues.isEmpty {
                MiniChart(values: historicalValues, isFlat: isFlat)
                    .frame(width: 80, height: 30)
            }
            
            // Column 3: Percentage or Value
            if let percentage = percentage {
                Text("\(String(format: "%.1f", percentage))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else if let value = value, historicalValues == nil {
                // Show value on the right if no graph
                Text(formatCurrency(value))
                    .font(.headline)
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(10)
    }
}

