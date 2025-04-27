//
//  CreateUserGroupPivot.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Fluent
import Vapor

extension UserGroupPivot {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserGroupPivot" }

        func prepare(on database: any Database) async throws {
            try await database.schema(UserGroupPivot.schema)
                .id()
                .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field("user_group_id", .uuid, .required, .references(UserGroup.schema, "id", onDelete: .cascade))
                .unique(on: "user_id", "user_group_id")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema(UserGroupPivot.schema).delete()
        }
    }
}
