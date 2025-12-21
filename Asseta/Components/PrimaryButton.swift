//
//  PrimaryButton.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color.appPrimary : Color.appDisabled)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Create Asset", action: {})
        PrimaryButton(title: "Save", action: {}, isEnabled: false)
    }
    .padding()
}

