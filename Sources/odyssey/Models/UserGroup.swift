//
//  UserGroup.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Vapor
import Fluent

final class UserGroup: Model, Content, @unchecked Sendable {
    static let schema = "user_groups"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Siblings(through: UserGroupPivot.self, from: \.$group, to: \.$user)
    var users: [User]

    init() {}

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
