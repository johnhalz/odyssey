//
//  CreateUnit.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Fluent
import Vapor

extension UnitRecord {
    struct Migration: AsyncMigration {
        var name: String { "CreateUnitRecord" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema(UnitRecord.schema)
                .id()
                .field("unit_type", .string, .required)
                .field("unit_symbol", .string, .required)
                .field("archived_unit", .string, .required)
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(UnitRecord.schema).delete()
        }
    }
}
