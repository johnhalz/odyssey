//
//  UserManagementTests.swift
//  odyssey
//
//  Created by odysseyTests
//

import Fluent
import Vapor
import odysseyLib

struct UserManagementTests: TestSuite {

    static func runAll(app: Application) async {
        printTestHeader("User Management Tests")

        await testCreateUserAsAdmin(app: app)
        await testCreateUserAsNonAdmin(app: app)
        await testCreateUserWithInvalidGroups(app: app)
        await testCreateUserPasswordMismatch(app: app)
        await testCreateUserValidationFailure(app: app)
        await testSetUserGroups(app: app)
        await testSetUserGroupsAsNonAdmin(app: app)
        await testSetUserGroupsInvalidGroups(app: app)
        await testSetUserGroupsNonExistentUser(app: app)
        await testUserGroupGuardMiddleware(app: app)
    }

    // MARK: - Test: Create User as Admin

    static func testCreateUserAsAdmin(app: Application) async {
        printTestSubheader("Test Create User as Admin")

        do {
            // Clean up and create admin user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)

            // Create new user
            let createUser = User.Create(
                firstName: "New",
                lastName: "User",
                email: "newuser@test.com",
                password: "password123",
                confirmPassword: "password123",
                groups: ["user", "technician"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(createUser))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .ok,
                    message: "Create user should return 200 OK"
                )

                let getUser = try TestUtilities.jsonDecoder.decode(GetUser.self, from: try res.bodyBuffer)
                TestUtilities.assertEqual(
                    getUser.firstName,
                    "New",
                    message: "First name should match"
                )
                TestUtilities.assertEqual(
                    getUser.lastName,
                    "User",
                    message: "Last name should match"
                )
                TestUtilities.assertEqual(
                    getUser.email,
                    "newuser@test.com",
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

            // Verify user was actually created in database
            let createdUser = try await User.query(on: app.db)
                .filter(\.$email == "newuser@test.com")
                .first()

            TestUtilities.assertNotNil(createdUser, message: "User should exist in database")

            // Verify password was hashed
            if let user = createdUser {
                TestUtilities.assertTrue(
                    try user.verify(password: "password123"),
                    message: "Password should be correctly hashed and verifiable"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Create User as Non-Admin

    static func testCreateUserAsNonAdmin(app: Application) async {
        printTestSubheader("Test Create User as Non-Admin")

        do {
            // Clean up and create regular user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, userToken) = try await TestUtilities.createAuthenticatedUser(
                on: app.db,
                groups: ["user"]
            )

            // Try to create new user
            let createUser = User.Create(
                firstName: "New",
                lastName: "User",
                email: "newuser@test.com",
                password: "password123",
                confirmPassword: "password123",
                groups: ["user"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(userToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(createUser))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .forbidden,
                    message: "Create user as non-admin should return 403 Forbidden"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Create User with Invalid Groups

    static func testCreateUserWithInvalidGroups(app: Application) async {
        printTestSubheader("Test Create User with Invalid Groups")

        do {
            // Clean up and create admin user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)

            // Try to create user with invalid groups
            let createUser = User.Create(
                firstName: "New",
                lastName: "User",
                email: "newuser@test.com",
                password: "password123",
                confirmPassword: "password123",
                groups: ["invalid_group", "another_invalid"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(createUser))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .badRequest,
                    message: "Create user with invalid groups should return 400 Bad Request"
                )

                let body = (try res.bodyBuffer).string
                TestUtilities.assertTrue(
                    body.contains("Invalid group names"),
                    message: "Error message should mention invalid group names"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Create User Password Mismatch

    static func testCreateUserPasswordMismatch(app: Application) async {
        printTestSubheader("Test Create User Password Mismatch")

        do {
            // Clean up and create admin user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)

            // Try to create user with mismatched passwords
            let createUser = User.Create(
                firstName: "New",
                lastName: "User",
                email: "newuser@test.com",
                password: "password123",
                confirmPassword: "different_password",
                groups: ["user"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(createUser))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .badRequest,
                    message: "Create user with password mismatch should return 400 Bad Request"
                )

                let body = (try res.bodyBuffer).string
                TestUtilities.assertTrue(
                    body.contains("Passwords did not match"),
                    message: "Error message should mention password mismatch"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Create User Validation Failure

    static func testCreateUserValidationFailure(app: Application) async {
        printTestSubheader("Test Create User Validation Failure")

        do {
            // Clean up and create admin user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)

            // Try to create user with invalid email
            let createUserInvalidEmail = User.Create(
                firstName: "New",
                lastName: "User",
                email: "not-an-email",
                password: "password123",
                confirmPassword: "password123",
                groups: ["user"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(
                        data: TestUtilities.jsonEncoder.encode(createUserInvalidEmail))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .badRequest,
                    message: "Create user with invalid email should return 400 Bad Request"
                )
            }

            // Try to create user with short password
            let createUserShortPassword = User.Create(
                firstName: "New",
                lastName: "User",
                email: "valid@email.com",
                password: "short",
                confirmPassword: "short",
                groups: ["user"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(
                        data: TestUtilities.jsonEncoder.encode(createUserShortPassword))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .badRequest,
                    message: "Create user with short password should return 400 Bad Request"
                )
            }

            // Try to create user with empty name
            let createUserEmptyName = User.Create(
                firstName: "",
                lastName: "User",
                email: "valid@email.com",
                password: "password123",
                confirmPassword: "password123",
                groups: ["user"]
            )

            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(
                        data: TestUtilities.jsonEncoder.encode(createUserEmptyName))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .badRequest,
                    message: "Create user with empty name should return 400 Bad Request"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Set User Groups

    static func testSetUserGroups(app: Application) async {
        printTestSubheader("Test Set User Groups")

        do {
            // Clean up and create admin user and target user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)
            let targetUser = try await TestUtilities.createTestUser(
                on: app.db,
                email: "target@test.com",
                groups: ["user"]
            )

            // Verify initial groups
            try await targetUser.$groups.load(on: app.db)
            TestUtilities.assertCount(
                targetUser.groups,
                1,
                message: "User should initially have 1 group"
            )

            // Set new groups
            let setGroups = SetUserGroups(
                userID: try targetUser.requireID(),
                groups: ["user", "technician", "engineer"]
            )

            try await app.test(
                .PATCH, "/api/user/groups",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(setGroups))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .ok,
                    message: "Set user groups should return 200 OK"
                )

                let getUser = try TestUtilities.jsonDecoder.decode(GetUser.self, from: try res.bodyBuffer)
                TestUtilities.assertCount(
                    getUser.groups,
                    3,
                    message: "User should have 3 groups after update"
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
                TestUtilities.assertContains(
                    getUser.groups,
                    where: { $0 == "engineer" },
                    message: "Groups should contain 'engineer'"
                )
            }

            // Verify groups were actually updated in database
            let updatedUser = try await User.find(targetUser.id, on: app.db)
            try await updatedUser?.$groups.load(on: app.db)
            TestUtilities.assertCount(
                updatedUser?.groups ?? [],
                3,
                message: "User groups should be updated in database"
            )

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Set User Groups as Non-Admin

    static func testSetUserGroupsAsNonAdmin(app: Application) async {
        printTestSubheader("Test Set User Groups as Non-Admin")

        do {
            // Clean up and create regular user and target user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, userToken) = try await TestUtilities.createAuthenticatedUser(
                on: app.db,
                groups: ["user"]
            )
            let targetUser = try await TestUtilities.createTestUser(
                on: app.db,
                email: "target@test.com",
                groups: ["user"]
            )

            // Try to set groups as non-admin
            let setGroups = SetUserGroups(
                userID: try targetUser.requireID(),
                groups: ["admin"]
            )

            try await app.test(
                .PATCH, "/api/user/groups",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(userToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(setGroups))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .forbidden,
                    message: "Set user groups as non-admin should return 403 Forbidden"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Set User Groups - Invalid Groups

    static func testSetUserGroupsInvalidGroups(app: Application) async {
        printTestSubheader("Test Set User Groups - Invalid Groups")

        do {
            // Clean up and create admin user and target user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)
            let targetUser = try await TestUtilities.createTestUser(
                on: app.db,
                email: "target@test.com",
                groups: ["user"]
            )

            // Try to set invalid groups
            let setGroups = SetUserGroups(
                userID: try targetUser.requireID(),
                groups: ["invalid_group"]
            )

            try await app.test(
                .PATCH, "/api/user/groups",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(setGroups))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .badRequest,
                    message: "Set invalid groups should return 400 Bad Request"
                )

                let body = (try res.bodyBuffer).string
                TestUtilities.assertTrue(
                    body.contains("Invalid group names"),
                    message: "Error message should mention invalid group names"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: Set User Groups - Non-Existent User

    static func testSetUserGroupsNonExistentUser(app: Application) async {
        printTestSubheader("Test Set User Groups - Non-Existent User")

        do {
            // Clean up and create admin user
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)

            // Try to set groups for non-existent user
            let setGroups = SetUserGroups(
                userID: UUID(),
                groups: ["user"]
            )

            try await app.test(
                .PATCH, "/api/user/groups",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(setGroups))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .notFound,
                    message: "Set groups for non-existent user should return 404 Not Found"
                )

                let body = (try res.bodyBuffer).string
                TestUtilities.assertTrue(
                    body.contains("User not found"),
                    message: "Error message should mention user not found"
                )
            }

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }

    // MARK: - Test: User Group Guard Middleware

    static func testUserGroupGuardMiddleware(app: Application) async {
        printTestSubheader("Test User Group Guard Middleware")

        do {
            // Clean up and create users with different groups
            try await TestUtilities.cleanupUsers(on: app.db)
            let (_, adminToken) = try await TestUtilities.createAdminUser(on: app.db)
            let (_, techToken) = try await TestUtilities.createTechnicianUser(on: app.db)
            let (_, userToken) = try await TestUtilities.createAuthenticatedUser(
                on: app.db,
                email: "regular@test.com",
                groups: ["user"]
            )

            // Admin should have access to admin routes
            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(adminToken)")
                    req.body = try ByteBuffer(
                        data: TestUtilities.jsonEncoder.encode(
                            User.Create(
                                firstName: "Test",
                                lastName: "User",
                                email: "test@test.com",
                                password: "password123",
                                confirmPassword: "password123",
                                groups: ["user"]
                            )))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .ok,
                    message: "Admin should have access to admin routes"
                )
            }

            // Regular user should NOT have access to admin routes
            try await app.test(
                .POST, "/api/users",
                beforeRequest: { req in
                    req.headers.add(name: .authorization, value: "Bearer \(userToken)")
                    req.body = try ByteBuffer(
                        data: TestUtilities.jsonEncoder.encode(
                            User.Create(
                                firstName: "Test",
                                lastName: "User",
                                email: "test2@test.com",
                                password: "password123",
                                confirmPassword: "password123",
                                groups: ["user"]
                            )))
                    req.headers.contentType = .json
                }
            ) { res async throws in
                TestUtilities.assertEqual(
                    res.status,
                    .forbidden,
                    message: "Regular user should NOT have access to admin routes"
                )
            }

            // Technician should have access to tech routes (if we test value creation)
            // This will be tested in ValueTests

            // Clean up
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
}
