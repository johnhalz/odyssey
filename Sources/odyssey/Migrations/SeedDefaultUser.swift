//
//  SeedDefaultUser.swift
//  odyssey
//
//  Created by John Halazonetis on 23.05.2025.
//

import Fluent
import Vapor

struct SeedDefaultUser: AsyncMigration {
    var name: String { "SeedDefaultUser" }
    
    func prepare(on database: any Database) async throws {
        
        let existingUserCount = try await User.query(on: database)
            .count()
        
        // Only create this user if no other users have been created
        if existingUserCount == 0 {
            
            let defaultUserPassword = "iwilldeletethisuser"
            let hashedDefaultUserPassword = try Bcrypt.hash(defaultUserPassword)
            
            let defaultUser = User(
                firstName: "admin",
                lastName: "admin",
                email: "admin@odyssey.com",
                passwordHash: hashedDefaultUserPassword
            )
            
            let adminGroup = try await UserGroup.query(on: database)
                .filter(\.$name == "admin")
                .all()
            
            try await defaultUser.create(on: database)
            try await defaultUser.$groups.attach(adminGroup, on: database)
        }
    }
    
    func revert(on database: any Database) async throws {
        try await User.query(on: database)
            .filter(\.$email == "admin@odyssey.com")
            .delete()
    }
}
