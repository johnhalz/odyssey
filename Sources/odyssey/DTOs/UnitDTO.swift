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

    init(unitType: String, unitSymbol: String, archivedUnit: String) {
        self.unitType = unitType
        self.unitSymbol = unitSymbol
    }

    init(unit: UnitRecord) {
        self.unitType = unit.unitType
        self.unitSymbol = unit.unitSymbol
    }
}

extension UnitDTO {
    func createRecordIfNeeded(on database: any Database) async throws -> UnitRecord {
        // Check if unit with same symbol already exists
        if let existingBySymbol = try await UnitRecord.query(on: database)
            .filter(\.$unitSymbol == self.unitSymbol)
            .first() {
            return existingBySymbol
        }
        
        // Check if unit with same type already exists
        if let existingByType = try await UnitRecord.query(on: database)
            .filter(\.$unitType == self.unitType)
            .first() {
            return existingByType
        }
        
        // Create new if none found
        let newUnit = try UnitRecord(unitDTO: self)
        try await newUnit.create(on: database)
        return newUnit
    }
}
