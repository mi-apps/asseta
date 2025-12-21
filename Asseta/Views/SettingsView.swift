//
//  SettingsView.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import SwiftUI

struct SettingsView: View {
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
                }
                .padding(.bottom, 20)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .onAppear {
                // Set the initial selection based on current currency
                selectedCurrency = Currency.commonCurrencies.first { $0.code == currencyManager.selectedCurrencyCode }
            }
        }
    }
}

#Preview {
    SettingsView()
}
