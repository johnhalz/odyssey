//
//  CreateUserGroup.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Fluent

extension UserGroup {
    struct Migration: AsyncMigration {
        var name: String { "CreateGroup" }

        func prepare(on database: any Database) async throws {
            try await database.schema(UserGroup.schema)
                .id()
                .field("name", .string, .required)
                .unique(on: "name")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema(UserGroup.schema).delete()
        }
    }
}
