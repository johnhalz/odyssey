//
//  UserDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 21.04.2025.
//

import Fluent
import Vapor

public struct GetUser: Content {
    public var id: UUID?
    public var firstName: String
    public var lastName: String
    public var email: String
    public var groups: [String]

    public init(id: UUID?, firstName: String, lastName: String, email: String, groups: [String]) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.groups = groups
    }
}
