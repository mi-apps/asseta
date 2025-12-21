//
//  AssetValue.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import Foundation
import SwiftData

@Model
final class AssetValue {
    var value: Decimal
    var date: Date
    var asset: Asset?
    
    init(value: Decimal, date: Date = Date(), asset: Asset? = nil) {
        self.value = value
        self.date = date
        self.asset = asset
    }
}
