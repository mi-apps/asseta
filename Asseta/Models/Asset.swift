//
//  Asset.swift
//  Asseta
//
//  Created by Steven on 19.12.25.
//

import Foundation
import SwiftData

@Model
final class Asset: Hashable, Identifiable {
    var name: String
    var createdDate: Date
    @Relationship(deleteRule: .cascade, inverse: \AssetValue.asset)
    var values: [AssetValue]?
    
    init(name: String, createdDate: Date = Date()) {
        self.name = name
        self.createdDate = createdDate
        self.values = []
    }
    
    var currentValue: Decimal? {
        guard let values = values, !values.isEmpty else { return nil }
        let sortedValues = values.sorted { $0.date > $1.date }
        return sortedValues.first?.value
    }
    
    static func == (lhs: Asset, rhs: Asset) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
    
    var id: PersistentIdentifier {
        persistentModelID
    }
}
