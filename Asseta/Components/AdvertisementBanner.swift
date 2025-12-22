//
//  AdvertisementBanner.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct AdvertisementBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.appPrimary)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        AdvertisementBanner(message: "Track your net worth with beautiful charts and insights")
        AdvertisementBanner(message: "All your data stays private and secure on your device")
    }
    .padding()
}

