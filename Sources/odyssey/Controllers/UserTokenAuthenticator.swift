//
//  UserTokenAuthenticator.swift
//  odyssey
//
//  Created by John Halazonetis on 26.04.2025.
//

import Vapor
import Fluent

struct UserTokenAuthenticator: AsyncBearerAuthenticator {
    
    func authenticate(bearer: Vapor.BearerAuthorization, for request: Vapor.Request) async throws {
        let prefix = String(bearer.token.prefix(10))
            
        guard let token = try await UserToken.query(on: request.db)
            .filter(\.$tokenPrefix == prefix)
            .first()
        else {
            return
        }

        if try Bcrypt.verify(bearer.token, created: token.value) {
            try await token.$user.load(on: request.db)
            request.auth.login(token.user)
        }
    }
}
