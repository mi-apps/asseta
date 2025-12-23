//
//  DemoDataHelper.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import Foundation
import SwiftData

class DemoDataHelper {
    static let demoPrefix = "Demo: "
    
    static func isDemoAsset(_ asset: Asset) -> Bool {
        return asset.name.hasPrefix(demoPrefix)
    }
    
    static func createDemoData(in context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()
        
        // Delete any existing demo assets first
        deleteDemoData(in: context)
        
        // Create demo assets with realistic historical data
        // Stock Portfolio - with realistic volatility
        let stockAsset = Asset(name: "\(demoPrefix)Stock Portfolio", createdDate: calendar.date(byAdding: .year, value: -2, to: today)!)
        stockAsset.values = [
            AssetValue(value: 45000, date: calendar.date(byAdding: .year, value: -2, to: today)!, asset: stockAsset),
            AssetValue(value: 51000, date: calendar.date(byAdding: .month, value: -20, to: today)!, asset: stockAsset),
            AssetValue(value: 52000, date: calendar.date(byAdding: .month, value: -18, to: today)!, asset: stockAsset),
            AssetValue(value: 49000, date: calendar.date(byAdding: .month, value: -16, to: today)!, asset: stockAsset),
            AssetValue(value: 48000, date: calendar.date(byAdding: .month, value: -15, to: today)!, asset: stockAsset),
            AssetValue(value: 53000, date: calendar.date(byAdding: .month, value: -13, to: today)!, asset: stockAsset),
            AssetValue(value: 55000, date: calendar.date(byAdding: .month, value: -12, to: today)!, asset: stockAsset),
            AssetValue(value: 60000, date: calendar.date(byAdding: .month, value: -10, to: today)!, asset: stockAsset),
            AssetValue(value: 62000, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: stockAsset),
            AssetValue(value: 60000, date: calendar.date(byAdding: .month, value: -7, to: today)!, asset: stockAsset),
            AssetValue(value: 58000, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: stockAsset),
            AssetValue(value: 63000, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: stockAsset),
            AssetValue(value: 67000, date: calendar.date(byAdding: .month, value: -3, to: today)!, asset: stockAsset),
            AssetValue(value: 69000, date: calendar.date(byAdding: .month, value: -2, to: today)!, asset: stockAsset),
            AssetValue(value: 71000, date: calendar.date(byAdding: .month, value: -1, to: today)!, asset: stockAsset),
            AssetValue(value: 72500, date: today, asset: stockAsset)
        ]
        context.insert(stockAsset)
        
        // Savings Account - steady growth with minor fluctuations
        let savingsAsset = Asset(name: "\(demoPrefix)Savings Account", createdDate: calendar.date(byAdding: .year, value: -1, to: today)!)
        savingsAsset.values = [
            AssetValue(value: 10000, date: calendar.date(byAdding: .year, value: -1, to: today)!, asset: savingsAsset),
            AssetValue(value: 11200, date: calendar.date(byAdding: .month, value: -10, to: today)!, asset: savingsAsset),
            AssetValue(value: 12000, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: savingsAsset),
            AssetValue(value: 13200, date: calendar.date(byAdding: .month, value: -7, to: today)!, asset: savingsAsset),
            AssetValue(value: 15000, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: savingsAsset),
            AssetValue(value: 16500, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: savingsAsset),
            AssetValue(value: 18500, date: calendar.date(byAdding: .month, value: -3, to: today)!, asset: savingsAsset),
            AssetValue(value: 20500, date: calendar.date(byAdding: .month, value: -1, to: today)!, asset: savingsAsset),
            AssetValue(value: 22000, date: today, asset: savingsAsset)
        ]
        context.insert(savingsAsset)
        
        // Real Estate - gradual appreciation with some volatility
        let realEstateAsset = Asset(name: "\(demoPrefix)Real Estate", createdDate: calendar.date(byAdding: .year, value: -3, to: today)!)
        realEstateAsset.values = [
            AssetValue(value: 450000, date: calendar.date(byAdding: .year, value: -3, to: today)!, asset: realEstateAsset),
            AssetValue(value: 455000, date: calendar.date(byAdding: .month, value: -30, to: today)!, asset: realEstateAsset),
            AssetValue(value: 465000, date: calendar.date(byAdding: .month, value: -24, to: today)!, asset: realEstateAsset),
            AssetValue(value: 470000, date: calendar.date(byAdding: .month, value: -21, to: today)!, asset: realEstateAsset),
            AssetValue(value: 480000, date: calendar.date(byAdding: .month, value: -18, to: today)!, asset: realEstateAsset),
            AssetValue(value: 485000, date: calendar.date(byAdding: .month, value: -15, to: today)!, asset: realEstateAsset),
            AssetValue(value: 495000, date: calendar.date(byAdding: .month, value: -12, to: today)!, asset: realEstateAsset),
            AssetValue(value: 500000, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: realEstateAsset),
            AssetValue(value: 510000, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: realEstateAsset),
            AssetValue(value: 518000, date: calendar.date(byAdding: .month, value: -3, to: today)!, asset: realEstateAsset),
            AssetValue(value: 525000, date: today, asset: realEstateAsset)
        ]
        context.insert(realEstateAsset)
        
        // Retirement Account - growth with market volatility
        let retirementAsset = Asset(name: "\(demoPrefix)Retirement Account", createdDate: calendar.date(byAdding: .year, value: -2, to: today)!)
        retirementAsset.values = [
            AssetValue(value: 85000, date: calendar.date(byAdding: .year, value: -2, to: today)!, asset: retirementAsset),
            AssetValue(value: 88000, date: calendar.date(byAdding: .month, value: -20, to: today)!, asset: retirementAsset),
            AssetValue(value: 92000, date: calendar.date(byAdding: .month, value: -18, to: today)!, asset: retirementAsset),
            AssetValue(value: 95000, date: calendar.date(byAdding: .month, value: -15, to: today)!, asset: retirementAsset),
            AssetValue(value: 98000, date: calendar.date(byAdding: .month, value: -13, to: today)!, asset: retirementAsset),
            AssetValue(value: 105000, date: calendar.date(byAdding: .month, value: -12, to: today)!, asset: retirementAsset),
            AssetValue(value: 112000, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: retirementAsset),
            AssetValue(value: 118000, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: retirementAsset),
            AssetValue(value: 122000, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: retirementAsset),
            AssetValue(value: 128000, date: calendar.date(byAdding: .month, value: -2, to: today)!, asset: retirementAsset),
            AssetValue(value: 132000, date: today, asset: retirementAsset)
        ]
        context.insert(retirementAsset)
        
        // Investment Portfolio - volatile with overall growth
        let investmentAsset = Asset(name: "\(demoPrefix)Investment Portfolio", createdDate: calendar.date(byAdding: .month, value: -15, to: today)!)
        investmentAsset.values = [
            AssetValue(value: 25000, date: calendar.date(byAdding: .month, value: -15, to: today)!, asset: investmentAsset),
            AssetValue(value: 27000, date: calendar.date(byAdding: .month, value: -13, to: today)!, asset: investmentAsset),
            AssetValue(value: 28000, date: calendar.date(byAdding: .month, value: -12, to: today)!, asset: investmentAsset),
            AssetValue(value: 29500, date: calendar.date(byAdding: .month, value: -10, to: today)!, asset: investmentAsset),
            AssetValue(value: 31000, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: investmentAsset),
            AssetValue(value: 28500, date: calendar.date(byAdding: .month, value: -7, to: today)!, asset: investmentAsset),
            AssetValue(value: 29000, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: investmentAsset),
            AssetValue(value: 32000, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: investmentAsset),
            AssetValue(value: 34000, date: calendar.date(byAdding: .month, value: -3, to: today)!, asset: investmentAsset),
            AssetValue(value: 35500, date: calendar.date(byAdding: .month, value: -1, to: today)!, asset: investmentAsset),
            AssetValue(value: 36500, date: today, asset: investmentAsset)
        ]
        context.insert(investmentAsset)
        
        // Dogecoin - highly volatile cryptocurrency
        let dogecoinAsset = Asset(name: "\(demoPrefix)Dogecoin", createdDate: calendar.date(byAdding: .month, value: -12, to: today)!)
        dogecoinAsset.values = [
            AssetValue(value: 850, date: calendar.date(byAdding: .month, value: -12, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1200, date: calendar.date(byAdding: .month, value: -11, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 980, date: calendar.date(byAdding: .month, value: -10, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1450, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1100, date: calendar.date(byAdding: .month, value: -8, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1650, date: calendar.date(byAdding: .month, value: -7, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1350, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1800, date: calendar.date(byAdding: .month, value: -5, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1520, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1950, date: calendar.date(byAdding: .month, value: -3, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1720, date: calendar.date(byAdding: .month, value: -2, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 2100, date: calendar.date(byAdding: .month, value: -1, to: today)!, asset: dogecoinAsset),
            AssetValue(value: 1850, date: today, asset: dogecoinAsset)
        ]
        context.insert(dogecoinAsset)
        
        // Rolex - luxury watch with steady appreciation and occasional dips
        let rolexAsset = Asset(name: "\(demoPrefix)Rolex", createdDate: calendar.date(byAdding: .year, value: -2, to: today)!)
        rolexAsset.values = [
            AssetValue(value: 12500, date: calendar.date(byAdding: .year, value: -2, to: today)!, asset: rolexAsset),
            AssetValue(value: 12800, date: calendar.date(byAdding: .month, value: -20, to: today)!, asset: rolexAsset),
            AssetValue(value: 13200, date: calendar.date(byAdding: .month, value: -18, to: today)!, asset: rolexAsset),
            AssetValue(value: 13000, date: calendar.date(byAdding: .month, value: -15, to: today)!, asset: rolexAsset),
            AssetValue(value: 13800, date: calendar.date(byAdding: .month, value: -12, to: today)!, asset: rolexAsset),
            AssetValue(value: 14200, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: rolexAsset),
            AssetValue(value: 13900, date: calendar.date(byAdding: .month, value: -7, to: today)!, asset: rolexAsset),
            AssetValue(value: 14500, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: rolexAsset),
            AssetValue(value: 14900, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: rolexAsset),
            AssetValue(value: 15200, date: calendar.date(byAdding: .month, value: -2, to: today)!, asset: rolexAsset),
            AssetValue(value: 15500, date: today, asset: rolexAsset)
        ]
        context.insert(rolexAsset)
        
        // Copper - commodity with market volatility
        let copperAsset = Asset(name: "\(demoPrefix)Copper", createdDate: calendar.date(byAdding: .year, value: -1, to: today)!)
        copperAsset.values = [
            AssetValue(value: 8200, date: calendar.date(byAdding: .year, value: -1, to: today)!, asset: copperAsset),
            AssetValue(value: 8500, date: calendar.date(byAdding: .month, value: -10, to: today)!, asset: copperAsset),
            AssetValue(value: 7800, date: calendar.date(byAdding: .month, value: -9, to: today)!, asset: copperAsset),
            AssetValue(value: 9200, date: calendar.date(byAdding: .month, value: -8, to: today)!, asset: copperAsset),
            AssetValue(value: 8800, date: calendar.date(byAdding: .month, value: -7, to: today)!, asset: copperAsset),
            AssetValue(value: 9500, date: calendar.date(byAdding: .month, value: -6, to: today)!, asset: copperAsset),
            AssetValue(value: 8900, date: calendar.date(byAdding: .month, value: -5, to: today)!, asset: copperAsset),
            AssetValue(value: 10200, date: calendar.date(byAdding: .month, value: -4, to: today)!, asset: copperAsset),
            AssetValue(value: 9600, date: calendar.date(byAdding: .month, value: -3, to: today)!, asset: copperAsset),
            AssetValue(value: 10500, date: calendar.date(byAdding: .month, value: -2, to: today)!, asset: copperAsset),
            AssetValue(value: 9800, date: calendar.date(byAdding: .month, value: -1, to: today)!, asset: copperAsset),
            AssetValue(value: 10800, date: today, asset: copperAsset)
        ]
        context.insert(copperAsset)
        
        // Save the context
        try? context.save()
    }
    
    static func deleteDemoData(in context: ModelContext) {
        let descriptor = FetchDescriptor<Asset>()
        guard let allAssets = try? context.fetch(descriptor) else { return }
        
        for asset in allAssets {
            if isDemoAsset(asset) {
                context.delete(asset)
            }
        }
        
        try? context.save()
    }
}

