//
//  UserGroupPivot.swift
//  odyssey
//
//  Created by John Halazonetis on 27.04.2025.
//

import Fluent
import Vapor

public final class UserGroupPivot: Model, @unchecked Sendable {
    public static let schema = "user_group_pivot"

    @ID(key: .id)
    public var id: UUID?

    @Parent(key: "user_id")
    public var user: User

    @Parent(key: "user_group_id")
    public var group: UserGroup

    public init() {}

    public init(id: UUID? = nil, userID: User.IDValue, groupID: UserGroup.IDValue) {
        self.id = id
        self.$user.id = userID
        self.$group.id = groupID
    }
}
