//
//  CreateUserToken.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema(UserToken.schema)
                .id()
                .field("value", .string, .required)
                .field("token_prefix", .string, .required) // Add this line!
                .field("user_id", .uuid, .required, .references(User.schema, "id"))
                .unique(on: "value")
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(UserToken.schema).delete()
        }        
    }
}
