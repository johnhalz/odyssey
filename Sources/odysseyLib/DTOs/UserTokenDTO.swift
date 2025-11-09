//
//  UserTokenDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent
import Vapor

extension UserToken: ModelTokenAuthenticatable {
    public static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    public static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }

    public var isValid: Bool {
        true
    }
}
