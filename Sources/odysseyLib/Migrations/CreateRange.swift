//
//  CreateRange.swift
//  odyssey
//
//  Created by John Halazonetis on 13.05.2025.
//

import Fluent

extension Range {
    struct Migration: AsyncMigration {
        func prepare(on database: any FluentKit.Database) async throws {
            try await database.schema(Range.schema)
                .id()
                .field("lower_id", .uuid, .required, .references(Value.schema, "id"))
                .field("upper_id", .uuid, .required, .references(Value.schema, "id"))
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(Range.schema).delete()
        }
    }
}
