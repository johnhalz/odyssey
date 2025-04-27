//
//  SetUserGroupsDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Fluent
import Vapor

struct SetUserGroups: Content {
    var userID: UUID
    var groups: [String]
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case groups
    }
}
