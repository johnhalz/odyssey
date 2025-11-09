//
//  AuthenticationTests.swift
//  odyssey
//
//  Created by odysseyTests
//

import Fluent
import Vapor
import odysseyLib

struct AuthenticationTests: TestSuite {

    static func runAll(app: Application) async {
        printTestHeader("Authentication Tests")

        await testPingEndpoint(app: app)
        await testLoginSuccess(app: app)
        await testLoginFailureInvalidCredentials(app: app)
        await testTokenAuthentication(app: app)
        await testTokenAuthenticationInvalidToken(app: app)
        await testGetMeEndpoint(app: app)
        await testGetMeUnauthorized(app: app)
    }

    // MARK: - Test: Ping Endpoint

    static func testPingEndpoint(app: Application) async {
        printTestSubheader("Test Ping Endpoint")

        do {
            try await app.test(.GET, "/api/ping") { res async throws in
                TestUtilities.assertEqual(res.status, .ok, message: "Ping should return 200 OK")

                let body = String(buffer: try res.bodyBuffer)
                TestUtilities.assertTrue(
                    body.contains("Odyssey"),
                    message: "Ping response should contain 'Odyssey'"
                )
                TestUtilities.assertTrue(
                    body.contains("running"),
                    message: "Ping response should contain 'running'"
                )
            }
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Login Success

    static func testLoginSuccess(app: Application) async {
        printTestSubheader("Test Login Success")

        do {
            // Clean up and create test user
            try await TestUtilities.cleanupUsers(on: app.db)
            let user = try await TestUtilities.createTestUser(
                on: app.db,
                email: "login@test.com",
                password: "testpassword123"
            )

            // Test login
            try await app.test(
                .POST, "/api/login",
                beforeRequest: { req in
                    let basic = "\("login@test.com"):\("testpassword123")"
                        .data(using: .utf8)!
                        .base64EncodedString()
                    req.headers.add(name: .authorization, value: "Basic \(basic)")
                }
            ) { res async throws in
                TestUtilities.assertEqual(res.status, .ok, message: "Login should return 200 OK")

                let token = try TestUtilities.jsonDecoder.decode(
                    UserToken.self, from: try res.bodyBuffer)
                TestUtilities.assertNotNil(token.id, message: "Token should have an ID")
                TestUtilities.assertNotNil(token.value, message: "Token should have a value")
                TestUtilities.assertEqual(
                    token.$user.id,
                    try user.requireID(),
                    message: "Token should be associated with the correct user"
                )

                // Verify token prefix is extracted correctly
                TestUtilities.assertTrue(
                    token.value.count >= 10,
                    message: "Token value should be at least 10 characters"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Login Failure - Invalid Credentials

    static func testLoginFailureInvalidCredentials(app: Application) async {
        printTestSubheader("Test Login Failure - Invalid Credentials")

        do {
            // Clean up and create test user
            try await TestUtilities.cleanupUsers(on: app.db)
            _ = try await TestUtilities.createTestUser(
                on: app.db,
                email: "login@test.com",
                password: "correctpassword"
            )

            // Test login with wrong password
            try await app.test(
                .POST, "/api/login",
                beforeRequest: { req in
                    let basic = "\("login@test.com"):\("wrongpassword")"
                        .data(using: .utf8)!
                        .base64EncodedString()
                    req.headers.add(name: .authorization, value: "Basic \(basic)")
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .unauthorized,
                    message: "Login with wrong password should return 401 Unauthorized"
                )
            }

            // Test login with non-existent user
            try await app.test(
                .POST, "/api/login",
                beforeRequest: { req in
                    let basic = "\("nonexistent@test.com"):\("anypassword")"
                        .data(using: .utf8)!
                        .base64EncodedString()
                    req.headers.add(name: .authorization, value: "Basic \(basic)")
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .unauthorized,
                    message: "Login with non-existent user should return 401 Unauthorized"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Token Authentication

    static func testTokenAuthentication(app: Application) async {
        printTestSubheader("Test Token Authentication")

        do {
            // Clean up and create authenticated user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (user, token) = try await TestUtilities.createAuthenticatedUser(on: app.db)

            // Test accessing protected endpoint with valid token
            try await app.test(
                .GET, "/api/me",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(token)")
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .ok,
                    message: "Request with valid token should return 200 OK"
                )

                let getUser = try TestUtilities.jsonDecoder.decode(
                    GetUser.self, from: try res.bodyBuffer)
                TestUtilities.assertEqual(
                    getUser.email,
                    user.email,
                    message: "Response should contain correct user email"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Token Authentication - Invalid Token

    static func testTokenAuthenticationInvalidToken(app: Application) async {
        printTestSubheader("Test Token Authentication - Invalid Token")

        do {
            // Test accessing protected endpoint with invalid token
            try await app.test(
                .GET, "/api/me",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer invalid-token")
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .unauthorized,
                    message: "Request with invalid token should return 401 Unauthorized"
                )
            }

            // Test accessing protected endpoint without token
            try await app.test(.GET, "/api/me") { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .unauthorized,
                    message: "Request without token should return 401 Unauthorized"
                )
            }
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Get Me Endpoint

    static func testGetMeEndpoint(app: Application) async {
        printTestSubheader("Test Get Me Endpoint")

        do {
            // Clean up and create authenticated user with multiple groups
            try await TestUtilities.cleanupUsers(on: app.db)
            let (user, token) = try await TestUtilities.createAuthenticatedUser(
                on: app.db,
                firstName: "John",
                lastName: "Doe",
                email: "john.doe@test.com",
                groups: ["user", "technician"]
            )

            // Test /api/me endpoint
            try await app.test(
                .GET, "/api/me",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(token)")
                }
            ) { res async throws in
                TestUtilities.assertEqual(res.status, .ok, message: "Get me should return 200 OK")

                let getUser = try TestUtilities.jsonDecoder.decode(
                    GetUser.self, from: try res.bodyBuffer)

                TestUtilities.assertEqual(
                    getUser.firstName,
                    "John",
                    message: "First name should match"
                )
                TestUtilities.assertEqual(
                    getUser.lastName,
                    "Doe",
                    message: "Last name should match"
                )
                TestUtilities.assertEqual(
                    getUser.email,
                    "john.doe@test.com",
                    message: "Email should match"
                )
                TestUtilities.assertCount(
                    getUser.groups,
                    2,
                    message: "User should have 2 groups"
                )
                TestUtilities.assertContains(
                    getUser.groups,
                    where: { $0 == "user" },
                    message: "Groups should contain 'user'"
                )
                TestUtilities.assertContains(
                    getUser.groups,
                    where: { $0 == "technician" },
                    message: "Groups should contain 'technician'"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Get Me Unauthorized

    static func testGetMeUnauthorized(app: Application) async {
        printTestSubheader("Test Get Me Unauthorized")

        do {
            // Test without authentication
            try await app.test(.GET, "/api/me") { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .unauthorized,
                    message: "Get me without auth should return 401 Unauthorized"
                )
            }
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
}
