//
//  OverviewCard.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    var isPositive: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isPositive ? Color(red: 0, green: 0.6, blue: 0) : (isPositive == false ? Color(red: 0.8, green: 0, blue: 0) : .appPrimary))
                .frame(width: 40, height: 40)
                .background((isPositive ? Color(red: 0, green: 0.6, blue: 0) : (isPositive == false ? Color(red: 0.8, green: 0, blue: 0) : .appPrimary)).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(isPositive ? Color(red: 0, green: 0.6, blue: 0) : (isPositive == false ? Color(red: 0.8, green: 0, blue: 0) : .primary))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 12) {
        OverviewCard(
            title: "Net Worth",
            value: "$100,000.00",
            icon: "dollarsign.circle.fill"
        )
        
        OverviewCard(
            title: "Total Change",
            value: "+$5,000.00",
            icon: "arrow.up.circle.fill",
            isPositive: true
        )
        
        OverviewCard(
            title: "YoY Increase",
            value: "+15.5%",
            icon: "chart.line.uptrend.xyaxis",
            isPositive: true
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

