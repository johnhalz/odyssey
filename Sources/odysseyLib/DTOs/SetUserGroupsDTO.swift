//
//  SetUserGroupsDTO.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Fluent
import Vapor

public struct SetUserGroups: Content {
    public var userId: UUID
    public var groups: [String]

    public init(userID: UUID, groups: [String]) {
        self.userId = userID
        self.groups = groups
    }
}
