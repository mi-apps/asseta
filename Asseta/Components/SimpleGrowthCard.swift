//
//  SimpleGrowthCard.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct SimpleGrowthCard: View {
    let absoluteChange: Decimal
    let percentage: Double
    let period: Period
    let formatCurrency: (Decimal) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Worth Change")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if absoluteChange == 0 {
                Text("No change")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(formatCurrency(abs(absoluteChange)))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(absoluteChange >= 0 ? Color(red: 0, green: 0.6, blue: 0) : Color(red: 0.8, green: 0, blue: 0))
                    
                    Text(absoluteChange >= 0 ? "↑" : "↓")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(absoluteChange >= 0 ? Color(red: 0, green: 0.6, blue: 0) : Color(red: 0.8, green: 0, blue: 0))
                }
            }
            
            Text("this \(period.rawValue.lowercased())")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        SimpleGrowthCard(
            absoluteChange: 5000,
            percentage: 15.5,
            period: .month,
            formatCurrency: { value in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: value as NSDecimalNumber) ?? "$0"
            }
        )
        
        SimpleGrowthCard(
            absoluteChange: -2000,
            percentage: -5.2,
            period: .week,
            formatCurrency: { value in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: value as NSDecimalNumber) ?? "$0"
            }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

