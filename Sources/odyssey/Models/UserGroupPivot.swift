//
//  UserGroupPivot.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Vapor
import Fluent

final class UserGroupPivot: Model, @unchecked Sendable {
    static let schema = "user_group_pivot"

    @ID()
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "user_group_id")
    var group: UserGroup

    init() {}

    init(id: UUID? = nil, userID: UUID, groupID: UUID) {
        self.id = id
        self.$user.id = userID
        self.$group.id = groupID
    }
}
