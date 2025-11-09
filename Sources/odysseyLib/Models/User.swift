//
//  User.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent
import Vapor

public final class User: Model, Content, @unchecked Sendable {
    public static let schema = "users"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "first_name")
    public var firstName: String

    @Field(key: "last_name")
    public var lastName: String

    @Field(key: "email")
    public var email: String

    @Field(key: "password_hash")
    public var passwordHash: String

    @Siblings(through: UserGroupPivot.self, from: \.$user, to: \.$group)
    public var groups: [UserGroup]

    public init() {}

    public init(
        id: UUID? = nil, firstName: String, lastName: String, email: String, passwordHash: String
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User {
    public struct Create: Content {
        public var firstName: String
        public var lastName: String
        public var email: String
        public var password: String
        public var confirmPassword: String
        public var groups: [String]

        public init(
            firstName: String,
            lastName: String,
            email: String,
            password: String,
            confirmPassword: String,
            groups: [String]
        ) {
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.password = password
            self.confirmPassword = confirmPassword
            self.groups = groups
        }
    }
}

extension User.Create: Validatable {
    public static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("groups", as: [String].self, is: .count(1...))
    }
}

extension User: ModelAuthenticatable {
    public static var usernameKey: KeyPath<User, Field<String>> {
        \User.$email
    }

    public static var passwordHashKey: KeyPath<User, Field<String>> {
        \User.$passwordHash
    }

    public func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    public func createToken() async throws -> (UserToken, UserToken) {
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

    public func toGetUser(on db: any Database) async throws -> GetUser {
        try await self.$groups.load(on: db)  // Load groups if not already loaded

        return GetUser(
            id: self.id,
            firstName: self.firstName,
            lastName: self.lastName,
            email: self.email,
            groups: self.groups.map { $0.name }
        )
    }
}
