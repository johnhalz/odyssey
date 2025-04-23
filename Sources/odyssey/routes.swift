import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: TodoController())
    
    // User
    app.post("users") { req async throws -> User in
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            throw Abort(.badRequest, reason: "Passwords did not match")
        }
        
        let user = try User(
            firstName: create.firstName,
            lastName: create.lastName,
            email: create.email,
            passwordHash: Bcrypt.hash(create.password)
        )
        
        try await user.save(on: req.db)
        return user
    }
    
    let passwordProtected = app.grouped(User.authenticator())
    passwordProtected.post("login") { req async throws -> User in
        try req.auth.require(User.self)
    }
    
    // Logging in with token
    passwordProtected.post("login") { req async throws -> UserToken in
        let user = try req.auth.require(User.self)
        let token = try user.generateToken()
        try await token.save(on: req.db)
        return token
    }
    
    // Token Protected Group
    let tokenProtected = app.grouped(UserToken.authenticator())
    tokenProtected.get("me") { req async throws -> User in
        try req.auth.require(User.self)
    }
}


