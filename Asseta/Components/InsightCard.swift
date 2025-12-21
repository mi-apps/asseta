//
//  InsightCard.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct InsightCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
                .frame(width: 40, height: 40)
                .background(Color.appPrimary.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        InsightCard(
            icon: "chart.line.uptrend.xyaxis",
            title: "Great progress!",
            message: "You've added $5,000 since starting"
        )
        
        InsightCard(
            icon: "list.bullet",
            title: "Tracking assets",
            message: "You're tracking 5 assets"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

