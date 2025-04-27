//
//  UserDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 21.04.2025.
//

import Fluent
import Vapor

struct GetUser: Content {
    var id: UUID?
    var firstName: String
    var lastName: String
    var email: String
    var groups: [String]
    
    init(id: UUID?, firstName: String, lastName: String, email: String, groups: [String]) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.groups = groups
    }
}
