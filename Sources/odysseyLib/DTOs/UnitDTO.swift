//
//  UnitDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 22.05.2025.
//

import Fluent
import Vapor

public struct UnitDTO: Content {
    public var id: UUID?
    public var unitType: String
    public var unitSymbol: String

    public init(id: UUID?, unitType: String, unitSymbol: String, archivedUnit: String) {
        self.id = id
        self.unitType = unitType
        self.unitSymbol = unitSymbol
    }

    public init(unit: UnitRecord) {
        self.id = unit.id
        self.unitType = unit.unitType
        self.unitSymbol = unit.unitSymbol
    }
}

extension UnitDTO {
    public func createRecordIfNeeded(on database: any Database) async throws -> UnitRecord {
        // Check if unit with same symbol and type already exists
        if let existingUnit = try await UnitRecord.query(on: database)
            .filter(\.$unitType == self.unitType)
            .filter(\.$unitSymbol == self.unitSymbol)
            .first()
        {
            return existingUnit
        }

        // Create new if none found
        let newUnit = try UnitRecord(unitDTO: self)
        try await newUnit.create(on: database)
        return newUnit
    }
}
