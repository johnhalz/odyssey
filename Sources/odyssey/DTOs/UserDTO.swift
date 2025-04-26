//
//  UserDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 21.04.2025.
//

import Fluent
import Vapor

extension User {
    struct Create: Content {
        var firstName: String
        var lastName: String
        var email: String
        var password: String
        var confirmPassword: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
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
}
