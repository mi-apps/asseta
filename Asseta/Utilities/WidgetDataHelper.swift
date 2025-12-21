//
//  WidgetDataHelper.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetDataHelper {
    static let appGroupIdentifier = "group.com.milabs.Asseta.widget"
    static let netWorthKey = "netWorth"
    static let historicalDataKey = "historicalNetWorth"
    static let currencyCodeKey = "currencyCode"
    static let isAnonymizedKey = "isAnonymized"
    
    static var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    struct NetWorthData {
        let currentValue: Decimal
        let historicalValues: [(Date, Decimal)]
        let currencyCode: String
        let isAnonymized: Bool
        let lastUpdated: Date
    }
    
    static func saveNetWorthData(
        currentValue: Decimal,
        historicalValues: [(Date, Decimal)],
        currencyCode: String,
        isAnonymized: Bool
    ) {
        guard let defaults = sharedUserDefaults else { return }
        
        // Convert Decimal to Double for storage
        let currentValueDouble = Double(truncating: currentValue as NSDecimalNumber)
        let historicalValuesDouble = historicalValues.map { (date, value) in
            (date, Double(truncating: value as NSDecimalNumber))
        }
        
        let data: [String: Any] = [
            "currentValue": currentValueDouble,
            "historicalValues": historicalValuesDouble.map { ["date": $0.0.timeIntervalSince1970, "value": $0.1] },
            "currencyCode": currencyCode,
            "isAnonymized": isAnonymized,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        
        defaults.set(data, forKey: netWorthKey)
        defaults.synchronize()
        
        // Reload widget timelines
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    static func loadNetWorthData() -> NetWorthData? {
        guard let defaults = sharedUserDefaults,
              let dict = defaults.dictionary(forKey: netWorthKey) else {
            return nil
        }
        
        guard let currentValueDouble = dict["currentValue"] as? Double,
              let historicalValuesArray = dict["historicalValues"] as? [[String: Any]],
              let currencyCode = dict["currencyCode"] as? String,
              let isAnonymized = dict["isAnonymized"] as? Bool,
              let lastUpdatedInterval = dict["lastUpdated"] as? TimeInterval else {
            return nil
        }
        
        let currentValue = Decimal(currentValueDouble)
        let historicalValues = historicalValuesArray.compactMap { item -> (Date, Decimal)? in
            guard let dateInterval = item["date"] as? TimeInterval,
                  let valueDouble = item["value"] as? Double else {
                return nil
            }
            return (Date(timeIntervalSince1970: dateInterval), Decimal(valueDouble))
        }
        
        return NetWorthData(
            currentValue: currentValue,
            historicalValues: historicalValues,
            currencyCode: currencyCode,
            isAnonymized: isAnonymized,
            lastUpdated: Date(timeIntervalSince1970: lastUpdatedInterval)
        )
    }
}

