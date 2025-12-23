//
//  SettingsView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedCurrency: Currency?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Currency Picker
                    Menu {
                        ForEach(Currency.commonCurrencies) { currency in
                            Button {
                                selectedCurrency = currency
                                currencyManager.setCurrencyCode(currency.code)
                            } label: {
                                HStack {
                                    Text(currency.symbol)
                                    if currency.code == currencyManager.selectedCurrencyCode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Currency")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(currencyManager.selectedCurrencySymbol)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Anonymize Values Toggle
                    HStack {
                        Text("Anonymize Values")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { currencyManager.isAnonymized },
                            set: { currencyManager.setAnonymized($0) }
                        ))
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Demo Mode Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Demo Mode")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            Text("View the app with realistic demo data")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { currencyManager.isDemoModeEnabled },
                            set: { newValue in
                                currencyManager.setDemoModeEnabled(newValue)
                                handleDemoModeChange(enabled: newValue)
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Links Section
                    Divider()
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    Text("Links")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Repository Link
                    Link(destination: URL(string: "https://github.com/mi-apps/asseta")!) {
                        HStack {
                            Text("Repository")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .onAppear {
                // Set the initial selection based on current currency
                selectedCurrency = Currency.commonCurrencies.first { $0.code == currencyManager.selectedCurrencyCode }
                
                // Ensure demo data matches the current demo mode setting
                if currencyManager.isDemoModeEnabled {
                    // Check if demo data exists, if not create it
                    let descriptor = FetchDescriptor<Asset>()
                    if let assets = try? modelContext.fetch(descriptor) {
                        let hasDemoData = assets.contains { DemoDataHelper.isDemoAsset($0) }
                        if !hasDemoData {
                            DemoDataHelper.createDemoData(in: modelContext)
                        }
                    }
                } else {
                    // Remove demo data if demo mode is disabled
                    DemoDataHelper.deleteDemoData(in: modelContext)
                }
            }
        }
    }
    
    private func handleDemoModeChange(enabled: Bool) {
        if enabled {
            DemoDataHelper.createDemoData(in: modelContext)
        } else {
            DemoDataHelper.deleteDemoData(in: modelContext)
        }
    }
}

#Preview {
    SettingsView()
}
