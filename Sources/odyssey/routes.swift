import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    let api = app.grouped("api")
    
    api.get("ping") { req async -> String in
        "Odyssey 0.1.0 is running."
    }
    
    // MARK: - Logging in with token
    let passwordProtected = api.grouped(User.authenticator())
    passwordProtected.post("login") { req async throws -> UserToken in
        let user = try req.auth.require(User.self)
        let (hashedToken, rawToken) = try await user.createToken()
        try await hashedToken.save(on: req.db)
        return rawToken
    }
    
    // MARK: - Token Protected Group
    let tokenProtected = api.grouped(UserTokenAuthenticator())
    
    // Get user details
    tokenProtected.get("me") { req async throws -> GetUser in
        let user = try req.auth.require(User.self)
        return try await user.toGetUser(on: req.db)
    }
    
    // MARK: - Admin Routes
    let adminRoutes = tokenProtected.grouped(UserGroupGuardMiddleware(["admin"]))
    
    // Set the user groups for a user
    adminRoutes.patch("user", "groups") { req async throws -> GetUser in
        let setGroups = try req.content.decode(SetUserGroups.self)

        // Find the user to modify
        guard let user = try await User.find(setGroups.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        // Find all valid groups by name
        let validGroups = try await UserGroup.query(on: req.db)
            .filter(\.$name ~~ setGroups.groups)  // filter by the names from the input
            .all()

        // Check if there are any invalid groups and throw an error if all are invalid
        let validGroupNames = validGroups.map { $0.name }
        if validGroupNames.isEmpty {
            throw Abort(.badRequest, reason: "Invalid group names: \(setGroups.groups.joined(separator: ", "))")
        }

        // Set new groups
        try await user.$groups.detachAll(on: req.db)
        try await user.$groups.attach(validGroups, on: req.db)

        return try await user.toGetUser(on: req.db)
    }
    
    // Create user with user group(s)
    adminRoutes.post("users") { req async throws -> GetUser in
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        
        // Check password match
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        
        let user = try User(
            firstName: create.firstName,
            lastName: create.lastName,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        
        // Query for the groups based on the provided names
        let validGroups = try await UserGroup.query(on: req.db)
            .filter(\.$name ~~ create.groups)  // Filter by names that match the provided groups
            .all()

        // Check for any invalid groups
        let validGroupNames = validGroups.map { $0.name }
        let invalidGroupNames = create.groups.filter { !validGroupNames.contains($0) }

        // If any invalid group names are found, throw an error
        if !invalidGroupNames.isEmpty {
            throw Abort(.badRequest, reason: "Invalid group names: \(invalidGroupNames.joined(separator: ", "))")
        }
        
        try await user.save(on: req.db)
        try await user.$groups.attach(validGroups, on: req.db)
        return try await user.toGetUser(on: req.db)
    }
    
//    let techRoutes = tokenProtected.grouped(UserGroupGuardMiddleware(["technician", "engineer"]))
//    let customerRoutes = tokenProtected.grouped(UserGroupGuardMiddleware(["customer"]))
//    let externalRoutes = tokenProtected.grouped(UserGroupGuardMiddleware(["external"]))
}
