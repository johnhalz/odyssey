//
//  CreateUser.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent
import Vapor

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema(User.schema)
                .id()
                .field("first_name", .string, .required)
                .field("last_name", .string, .required)
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }
        
        func revert(on database: any Database) async throws {
            try await database.schema(User.schema).delete()
        }
    }
}
