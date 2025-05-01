//
//  CreateUnit.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Fluent
import Vapor

struct CreateUnitRecord: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(UnitRecord.schema)
            .id()
            .field("unit_type", .string, .required)
            .field("unit_symbol", .string, .required)
            .field("archived_unit", .string, .required)
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema(UnitRecord.schema).delete()
    }
}
