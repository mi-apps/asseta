//
//  AddAssetView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData

struct AddAssetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var initialValue: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, value
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
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
                        Text("Create a new asset")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                            .padding(.top, 20)
                        
                        // Asset Name section
                        TextField("Asset Name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: 22, weight: .bold))
                            .focused($focusedField, equals: .name)
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        // Initial Value section
                        TextField("Initial Value", text: $initialValue)
                            .textFieldStyle(.plain)
                            .font(.system(size: 22, weight: .bold))
                            .focused($focusedField, equals: .value)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.systemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                
                // Save Button - Fixed at bottom
                VStack(spacing: 0) {
                    Divider()
                    PrimaryButton(title: "Save", action: {
                        saveAsset()
                    }, isEnabled: !name.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // Automatically focus the first text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = .name
                }
            }
        }
    }
    
    private func saveAsset() {
        let asset = Asset(name: name)
        modelContext.insert(asset)
        
        // Add initial value if provided
        if let valueString = Double(initialValue), valueString > 0 {
            let value = Decimal(valueString)
            let assetValue = AssetValue(value: value, asset: asset)
            modelContext.insert(assetValue)
        }
        
        dismiss()
    }
}
