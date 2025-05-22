//
//  CreateValue.swift
//  odyssey
//
//  Created by John Halazonetis on 01.05.2025.
//

import Fluent

extension Value {
    struct Migration: AsyncMigration {
        var name: String { "CreateValue" }
        
        func prepare(on database: any Database) async throws {
            
            try await database.enum("value_type")
                .case("array")
                .case("decimal")
                .case("integer")
                .case("string")
                .create()
            
            try await database.schema(Value.schema)
                .id()
                .field("type", .custom("value_type"), .required)
                .field("string", .string)
                .field("decimal", .double)
                .field("array", .array(of: .double))
                .field("unit_id", .uuid, .references(UnitRecord.schema, "id"))
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(Value.schema).delete()
            try await database.enum("value_type").delete()
        }
    }
}
