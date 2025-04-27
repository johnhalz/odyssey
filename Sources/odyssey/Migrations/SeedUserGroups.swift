//
//  SeedUserGroups.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Fluent

struct SeedUserGroups: AsyncMigration {
    var name: String { "SeedUserGroups" }

    func prepare(on database: any Database) async throws {
            let groupNames = ["admin", "engineer", "technician", "external", "customer"]

            for name in groupNames {
                let exists = try await UserGroup.query(on: database)
                    .filter(\.$name == name)
                    .first()

                if exists == nil {
                    let group = UserGroup(name: name)
                    try await group.create(on: database)
                }
            }
        }

    func revert(on database: any Database) async throws {
        let groupNames = ["admin", "engineer", "technician", "external", "customer"]

        try await UserGroup.query(on: database)
            .filter(\.$name ~~ groupNames)
            .delete()
    }
}
