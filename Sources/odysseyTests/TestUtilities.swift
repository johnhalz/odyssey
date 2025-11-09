//
//  TestUtilities.swift
//  odyssey
//
//  Created by odysseyTests
//

import Fluent
import Vapor
import odysseyLib

/// Extension to add test method to Application
extension Application {
    /// Test helper method that mimics XCTVapor's test method
    func test(
        _ method: HTTPMethod,
        _ path: String,
        beforeRequest: ((inout ClientRequest) throws -> Void)? = nil,
        afterResponse: @escaping (ClientResponse) async throws -> Void
    ) async throws {
        // Create temporary client request to collect headers and body
        var tempRequest = ClientRequest(method: method, url: URI(string: path))
        try beforeRequest?(&tempRequest)

        // Create a Vapor Request object for internal routing
        let request = Request(
            application: self,
            method: method,
            url: URI(string: path),
            headers: tempRequest.headers,
            collectedBody: tempRequest.body,
            on: self.eventLoopGroup.next()
        )

        // Execute the request through the application's responder
        let response = try await self.responder.respond(to: request).get()

        // Convert Vapor Response to ClientResponse
        let clientResponse = ClientResponse(
            status: response.status,
            headers: response.headers,
            body: response.body.buffer
        )

        try await afterResponse(clientResponse)
    }
}

/// Extension to safely get body from ClientResponse
extension ClientResponse {
    var bodyBuffer: ByteBuffer {
        get throws {
            guard let buffer = body else {
                throw Abort(.internalServerError, reason: "Response body is empty")
            }
            return buffer
        }
    }
}

/// Extension to add string property to ByteBuffer
extension ByteBuffer {
    var string: String {
        String(buffer: self)
    }
}

/// Extension to add string property to Response body
extension Response.Body {
    var string: String {
        guard let buffer = buffer else { return "" }
        return String(buffer: buffer)
    }
}

/// Test utilities and helper functions
struct TestUtilities {

    /// JSON encoder configured for Odyssey API
    static var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    /// JSON decoder configured for Odyssey API
    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Creates a test user and returns the user object
    static func createTestUser(
        on db: any Database,
        firstName: String = "Test",
        lastName: String = "User",
        email: String = "test@example.com",
        password: String = "password123",
        groups: [String] = ["user"]
    ) async throws -> User {
        let user = try User(
            firstName: firstName,
            lastName: lastName,
            email: email,
            passwordHash: Bcrypt.hash(password)
        )
        try await user.save(on: db)

        // Attach groups
        if !groups.isEmpty {
            let userGroups = try await UserGroup.query(on: db)
                .filter(\.$name ~~ groups)
                .all()

            try await user.$groups.attach(userGroups, on: db)
        }

        return user
    }

    /// Creates a test user and returns an authentication token
    static func createAuthenticatedUser(
        on db: any Database,
        firstName: String = "Test",
        lastName: String = "User",
        email: String = "test@example.com",
        password: String = "password123",
        groups: [String] = ["user"]
    ) async throws -> (User, String) {
        let user = try await createTestUser(
            on: db,
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            groups: groups
        )

        let (hashedToken, rawToken) = try await user.createToken()
        try await hashedToken.save(on: db)

        return (user, rawToken.value)
    }

    /// Creates an admin user with authentication token
    static func createAdminUser(on db: any Database) async throws -> (User, String) {
        return try await createAuthenticatedUser(
            on: db,
            firstName: "Admin",
            lastName: "User",
            email: "admin@example.com",
            password: "adminpassword",
            groups: ["admin"]
        )
    }

    /// Creates a technician user with authentication token
    static func createTechnicianUser(on db: any Database) async throws -> (User, String) {
        return try await createAuthenticatedUser(
            on: db,
            firstName: "Tech",
            lastName: "User",
            email: "tech@example.com",
            password: "techpassword",
            groups: ["technician"]
        )
    }

    /// Clean up all users from the database
    static func cleanupUsers(on db: any Database) async throws {
        // Delete all user tokens
        try await UserToken.query(on: db).delete()

        // Delete all user-group pivots
        try await UserGroupPivot.query(on: db).delete()

        // Delete all users except the default seeded user
        try await User.query(on: db)
            .filter(\.$email != "default@odyssey.local")
            .delete()
    }

    /// Clean up all values from the database
    static func cleanupValues(on db: any Database) async throws {
        try await Value.query(on: db).delete()
    }

    /// Clean up all unit records from the database
    static func cleanupUnitRecords(on db: any Database) async throws {
        try await UnitRecord.query(on: db).delete()
    }

    /// Assert that two UUIDs are equal
    static func assertEqual(_ lhs: UUID?, _ rhs: UUID?, message: String = "UUIDs should be equal") {
        guard lhs == rhs else {
            print("❌ \(message)")
            print("   Expected: \(String(describing: rhs))")
            print("   Got: \(String(describing: lhs))")
            return
        }
        print("✅ \(message)")
    }

    /// Assert that a condition is true
    static func assertTrue(_ condition: Bool, message: String = "Condition should be true") {
        if condition {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
        }
    }

    /// Assert that a condition is false
    static func assertFalse(_ condition: Bool, message: String = "Condition should be false") {
        if !condition {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
        }
    }

    /// Assert that two strings are equal
    static func assertEqual(
        _ lhs: String, _ rhs: String, message: String = "Strings should be equal"
    ) {
        if lhs == rhs {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected: \(rhs)")
            print("   Got: \(lhs)")
        }
    }

    /// Assert that two integers are equal
    static func assertEqual(_ lhs: Int, _ rhs: Int, message: String = "Integers should be equal") {
        if lhs == rhs {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected: \(rhs)")
            print("   Got: \(lhs)")
        }
    }

    /// Assert that two ValueTypes are equal
    static func assertEqual(
        _ lhs: ValueType, _ rhs: ValueType, message: String = "ValueTypes should be equal"
    ) {
        if lhs == rhs {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected: \(rhs)")
            print("   Got: \(lhs)")
        }
    }

    /// Assert that two HTTP statuses are equal
    static func assertEqual(
        _ lhs: HTTPStatus, _ rhs: HTTPStatus, message: String = "HTTP statuses should be equal"
    ) {
        if lhs == rhs {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected: \(rhs)")
            print("   Got: \(lhs)")
        }
    }

    /// Assert that two decimals are equal
    static func assertEqual(
        _ lhs: Decimal, _ rhs: Decimal, message: String = "Decimals should be equal"
    ) {
        if lhs == rhs {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected: \(rhs)")
            print("   Got: \(lhs)")
        }
    }

    /// Assert that an optional value is not nil
    static func assertNotNil<T>(_ value: T?, message: String = "Value should not be nil") {
        if value != nil {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
        }
    }

    /// Assert that an optional value is nil
    static func assertNil<T>(_ value: T?, message: String = "Value should be nil") {
        if value == nil {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected: nil")
            print("   Got: \(String(describing: value))")
        }
    }

    /// Assert that an array contains a specific number of elements
    static func assertCount<T>(
        _ array: [T], _ expectedCount: Int, message: String = "Array count should match"
    ) {
        if array.count == expectedCount {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
            print("   Expected count: \(expectedCount)")
            print("   Got count: \(array.count)")
        }
    }

    /// Assert that an array contains an element matching a predicate
    static func assertContains<T>(
        _ array: [T], where predicate: (T) -> Bool, message: String = "Array should contain element"
    ) {
        if array.contains(where: predicate) {
            print("✅ \(message)")
        } else {
            print("❌ \(message)")
        }
    }
}

/// Protocol for test suites
protocol TestSuite {
    static func runAll(app: Application) async
}

/// Helper extension for printing test results
extension TestSuite {
    static func printTestHeader(_ name: String) {
        print("\n" + String(repeating: "=", count: 60))
        print("Running: \(name)")
        print(String(repeating: "=", count: 60))
    }

    static func printTestSubheader(_ name: String) {
        print("\n--- \(name) ---")
    }
}
