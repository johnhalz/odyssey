//
//  User.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "first_name")
    var firstName: String
    
    @Field(key: "last_name")
    var lastName: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Siblings(through: UserGroupPivot.self, from: \.$user, to: \.$group)
    var groups: [UserGroup]
    
    init() { }
    
    init(id: UUID? = nil, firstName: String, lastName: String, email: String, passwordHash: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User {
    struct Create: Content {
        var firstName: String
        var lastName: String
        var email: String
        var password: String
        var confirmPassword: String
        var groups: [String]
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("groups", as: [String].self, is: .count(1...))
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> {
        \User.$email
    }
    
    static var passwordHashKey: KeyPath<User, Field<String>> {
        \User.$passwordHash
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    func createToken() async throws -> (UserToken, UserToken) {
        let rawToken = [UInt8].random(count: 64).base64
        let prefix = String(rawToken.prefix(10))
        let hashedToken = try Bcrypt.hash(rawToken)

        let hashedUserToken = UserToken(
            tokenPrefix: prefix,
            value: hashedToken,
            userID: try self.requireID()
        )
        
        let rawUserToken = UserToken(
            tokenPrefix: prefix,
            value: rawToken,
            userID: try self.requireID()
        )
        
        return (hashedUserToken, rawUserToken)
    }
    
    func toGetUser(on db: any Database) async throws -> GetUser {
        try await self.$groups.load(on: db) // Load groups if not already loaded

        return GetUser(
            id: self.id,
            firstName: self.firstName,
            lastName: self.lastName,
            email: self.email,
            groups: self.groups.map { $0.name }
        )
    }
}
