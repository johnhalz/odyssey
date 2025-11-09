//
//  UserToken.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent
import Vapor

public final class UserToken: Model, Content, @unchecked Sendable {
    public static let schema = "user_tokens"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "token_prefix")
    public var tokenPrefix: String

    @Field(key: "value")
    public var value: String

    @Parent(key: "user_id")
    public var user: User

    public init() {}

    public init(id: UUID? = nil, tokenPrefix: String, value: String, userID: UUID) {
        self.id = id
        self.tokenPrefix = tokenPrefix
        self.value = value
        self.$user.id = userID
    }
}
