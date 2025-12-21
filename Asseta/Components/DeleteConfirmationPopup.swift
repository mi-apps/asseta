//
//  DeleteConfirmationPopup.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct DeleteConfirmationPopup: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    init(
        isPresented: Binding<Bool>,
        title: String = "Delete",
        message: String = "This action cannot be reverted and the data will be gone",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Popup card
            VStack(spacing: 20) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        onConfirm()
                    } label: {
                        Text("Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.7, green: 0.1, blue: 0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: isPresented)
    }
}

