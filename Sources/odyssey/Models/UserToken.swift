//
//  UserToken.swift
//  odyssey
//
//  Created by John Halazonetis on 23.04.2025.
//

import Fluent
import Vapor

final class UserToken: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token_prefix")
    var tokenPrefix: String
    
    @Field(key: "value")
    var value: String
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    
    init(id: UUID? = nil, tokenPrefix: String, value: String, userID: User.IDValue) {
        self.id = id
        self.tokenPrefix = tokenPrefix
        self.value = value
        self.$user.id = userID
    }
}
