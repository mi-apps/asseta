//
//  AssetBreakdownChart.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import Charts

struct AssetBreakdownChart: View {
    let assets: [Asset]
    let totalNetWorth: Decimal
    let formatCurrency: (Decimal) -> String
    let onAssetTap: ((Asset) -> Void)?
    
    init(assets: [Asset], totalNetWorth: Decimal, formatCurrency: @escaping (Decimal) -> String, onAssetTap: ((Asset) -> Void)? = nil) {
        self.assets = assets
        self.totalNetWorth = totalNetWorth
        self.formatCurrency = formatCurrency
        self.onAssetTap = onAssetTap
    }
    
    private var allocationData: [(Asset, Double)] {
        AnalyticsHelper.calculateAssetAllocation(assets: assets, totalNetWorth: totalNetWorth)
    }
    
    private var colors: [Color] {
        [
            Color.appPrimary,
            Color(red: 0.2, green: 0.5, blue: 0.8),
            Color(red: 0.4, green: 0.7, blue: 0.3),
            Color(red: 0.9, green: 0.6, blue: 0.2),
            Color(red: 0.8, green: 0.3, blue: 0.5),
            Color(red: 0.5, green: 0.4, blue: 0.9),
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What You Own")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if allocationData.isEmpty {
                VStack(spacing: 8) {
                    Text("No assets yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add assets to see breakdown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if allocationData.count == 1 {
                // Single asset - show simple message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your only asset:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(allocationData[0].0.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(formatCurrency(allocationData[0].0.currentValue ?? 0))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                // Pie chart for multiple assets
                Chart {
                    ForEach(Array(allocationData.enumerated()), id: \.offset) { index, item in
                        SectorMark(
                            angle: .value("Percentage", item.1),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(colors[index % colors.count])
                        .annotation(position: .overlay) {
                            if item.1 > 5 {
                                Text("\(String(format: "%.0f", item.1))%")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                .frame(height: 200)
                
                // Asset list
                VStack(spacing: 12) {
                    ForEach(Array(allocationData.enumerated()), id: \.offset) { index, item in
                        Button(action: {
                            onAssetTap?(item.0)
                        }) {
                            HStack {
                                Circle()
                                    .fill(colors[index % colors.count])
                                    .frame(width: 12, height: 12)
                                
                                Text(item.0.name)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", item.1))%")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let asset1 = Asset(name: "House", createdDate: Date())
    let asset2 = Asset(name: "Stocks", createdDate: Date())
    let asset3 = Asset(name: "Savings", createdDate: Date())
    
    return AssetBreakdownChart(
        assets: [asset1, asset2, asset3],
        totalNetWorth: 100000,
        formatCurrency: { value in
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter.string(from: value as NSDecimalNumber) ?? "$0"
        }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

