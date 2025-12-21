//
//  PeriodSelector.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

enum Period: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case allTime = "All Time"
    
    static var defaultCases: [Period] {
        [.week, .month, .year, .allTime]
    }
}

struct PeriodSelector: View {
    @Binding var selectedPeriod: Period
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Period.defaultCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: selectedPeriod == period ? .semibold : .regular))
                        .foregroundColor(selectedPeriod == period ? .appPrimary : .secondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(6)
        .padding(.horizontal)
    }
}

#Preview {
    @Previewable @State var period: Period = .month
    return PeriodSelector(selectedPeriod: $period)
}

