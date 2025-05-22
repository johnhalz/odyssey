//
//  UnitDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 22.05.2025.
//

import Fluent
import Vapor

struct UnitDTO: Content {
    var unitType: String
    var unitSymbol: String
    var archivedUnit: String
    
    init(unitType: String, unitSymbol: String, archivedUnit: String) {
        self.unitType = unitType
        self.unitSymbol = unitSymbol
        self.archivedUnit = archivedUnit
    }
    
    init(unit: UnitRecord) {
        self.unitType = unit.unitType
        self.unitSymbol = unit.unitSymbol
        self.archivedUnit = unit.archivedUnit
    }
}
