//
//  CurrencyManager.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import Foundation
import Combine

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var selectedCurrencyCode: String = "USD"
    @Published var isAnonymized: Bool = false
    @Published var isDemoModeEnabled: Bool = false
    
    private init() {
        // Load saved currency code, default to USD
        if let savedCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode") {
            self.selectedCurrencyCode = savedCode
        }
        
        // Load anonymize setting
        self.isAnonymized = UserDefaults.standard.bool(forKey: "isAnonymized")
        
        // Load demo mode setting
        self.isDemoModeEnabled = UserDefaults.standard.bool(forKey: "isDemoModeEnabled")
    }
    
    var selectedCurrencySymbol: String {
        Currency.commonCurrencies.first(where: { $0.code == selectedCurrencyCode })?.symbol ?? selectedCurrencyCode
    }
    
    func setCurrencyCode(_ code: String) {
        selectedCurrencyCode = code
        UserDefaults.standard.set(code, forKey: "selectedCurrencyCode")
    }
    
    func setAnonymized(_ value: Bool) {
        isAnonymized = value
        UserDefaults.standard.set(value, forKey: "isAnonymized")
    }
    
    func setDemoModeEnabled(_ value: Bool) {
        isDemoModeEnabled = value
        UserDefaults.standard.set(value, forKey: "isDemoModeEnabled")
    }
    
    func formatCurrency(_ value: Decimal) -> String {
        // Return anonymized value if setting is enabled
        if isAnonymized {
            return "****.**"
        }
        
        let symbol = selectedCurrencySymbol
        
        // Simple decimal formatter - no locale dependencies
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        
        let formattedNumber = formatter.string(from: value as NSDecimalNumber) ?? String(describing: value)
        return "\(formattedNumber) \(symbol)"
    }

}

// Common currencies for selection
struct Currency: Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let symbol: String
    
    static let commonCurrencies: [Currency] = [
        Currency(id: "USD", code: "USD", name: "US Dollar", symbol: "$"),
        Currency(id: "EUR", code: "EUR", name: "Euro", symbol: "€"),
        Currency(id: "GBP", code: "GBP", name: "British Pound", symbol: "£"),
        Currency(id: "JPY", code: "JPY", name: "Japanese Yen", symbol: "¥"),
        Currency(id: "CNY", code: "CNY", name: "Chinese Yuan", symbol: "¥"),
        Currency(id: "CAD", code: "CAD", name: "Canadian Dollar", symbol: "C$"),
        Currency(id: "AUD", code: "AUD", name: "Australian Dollar", symbol: "A$"),
        Currency(id: "CHF", code: "CHF", name: "Swiss Franc", symbol: "CHF"),
        Currency(id: "INR", code: "INR", name: "Indian Rupee", symbol: "₹"),
        Currency(id: "BRL", code: "BRL", name: "Brazilian Real", symbol: "R$"),
        Currency(id: "KRW", code: "KRW", name: "South Korean Won", symbol: "₩"),
        Currency(id: "MXN", code: "MXN", name: "Mexican Peso", symbol: "$"),
        Currency(id: "SGD", code: "SGD", name: "Singapore Dollar", symbol: "S$"),
        Currency(id: "HKD", code: "HKD", name: "Hong Kong Dollar", symbol: "HK$"),
        Currency(id: "NZD", code: "NZD", name: "New Zealand Dollar", symbol: "NZ$"),
    ]
}
