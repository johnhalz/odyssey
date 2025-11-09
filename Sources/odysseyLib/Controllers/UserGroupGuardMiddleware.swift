//
//  UserGroupGuardMiddleware.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Vapor
import Fluent

struct UserGroupGuardMiddleware: AsyncMiddleware {
    let allowedGroups: [String]

    init(_ allowedGroups: [String]) {
        self.allowedGroups = allowedGroups
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let user = try request.auth.require(User.self)

        // Load groups if not already loaded
        try await user.$groups.load(on: request.db)

        // Check if user belongs to any of the allowed groups
        let isAllowed = user.groups.contains { group in
            allowedGroups.contains(where: { $0.lowercased() == group.name.lowercased() })
        }

        guard isAllowed else {
            throw Abort(.forbidden, reason: "You don't have access to this resource.")
        }

        return try await next.respond(to: request)
    }
}
