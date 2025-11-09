# Odyssey Tests

This directory contains comprehensive integration tests for the Odyssey API. The tests are organized into logical test suites that validate different aspects of the application.

## Test Structure

The test suite is built using Vapor's native HTTP client for integration testing and consists of:

- **main.swift** - Entry point for running all tests
- **TestUtilities.swift** - Helper functions and utilities for test setup and assertions
- **AuthenticationTests.swift** - Tests for login, token authentication, and user authentication
- **UserManagementTests.swift** - Tests for user creation, group management, and permissions
- **ValueTests.swift** - Tests for creating and managing different value types

## Running Tests

### Run All Tests

To execute the full test suite:

```bash
swift run odysseyTests
```

This will:
1. Set up the test application
2. Run migrations to create database tables
3. Execute all test suites in order
4. Clean up by reverting migrations

### Prerequisites

Before running tests, ensure:
1. PostgreSQL is running (see main README for Docker setup)
2. Database connection settings are configured in environment variables or using defaults
3. All migrations are available

## Test Suites

### Authentication Tests

Tests authentication and authorization functionality:

- ✅ Ping endpoint availability
- ✅ Successful login with valid credentials
- ✅ Failed login with invalid credentials
- ✅ Token authentication with valid token
- ✅ Rejection of invalid tokens
- ✅ User profile retrieval via `/api/me`
- ✅ Unauthorized access handling

### User Management Tests

Tests user creation and group management (admin-only operations):

- ✅ Creating users as admin with multiple groups
- ✅ Preventing non-admin users from creating users
- ✅ Validation of user input (email, password, names)
- ✅ Handling invalid group assignments
- ✅ Password mismatch detection
- ✅ Setting user groups
- ✅ User group guard middleware enforcement
- ✅ Proper error handling for non-existent users

### Value Tests

Tests creation and management of different value types:

- ✅ Creating string values
- ✅ Creating integer values (with and without units)
- ✅ Creating decimal values (with and without units)
- ✅ Creating array values (with and without units)
- ✅ Permission checking (technician, engineer, admin only)
- ✅ Unit record deduplication
- ✅ Proper value type encoding/decoding

## Test Utilities

The `TestUtilities` struct provides helper functions for:

### Test Data Creation

- `createTestUser()` - Create a user with specified attributes
- `createAuthenticatedUser()` - Create a user and return authentication token
- `createAdminUser()` - Create an admin user with token
- `createTechnicianUser()` - Create a technician user with token

### Cleanup Functions

- `cleanupUsers()` - Remove test users from database
- `cleanupValues()` - Remove test values from database
- `cleanupUnitRecords()` - Remove test unit records from database

### Assertions

- `assertEqual()` - Assert equality for various types
- `assertTrue()` / `assertFalse()` - Boolean assertions
- `assertNotNil()` / `assertNil()` - Nil checks
- `assertCount()` - Array count validation
- `assertContains()` - Array content validation

All assertions print ✅ or ❌ with descriptive messages for easy debugging.

## Writing New Tests

### Adding a New Test Suite

1. Create a new file in `odysseyTests` directory (e.g., `NewFeatureTests.swift`)
2. Define a struct conforming to `TestSuite` protocol:

```swift
struct NewFeatureTests: TestSuite {
    static func runAll(app: Application) async {
        printTestHeader("New Feature Tests")
        
        await testFeatureOne(app: app)
        await testFeatureTwo(app: app)
    }
    
    static func testFeatureOne(app: Application) async {
        printTestSubheader("Test Feature One")
        
        do {
            // Your test code here
            try await app.test(.GET, "/api/endpoint") { res async in
                TestUtilities.assertEqual(res.status, .ok, message: "Should return OK")
                
                // Decode response if needed
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let data = try decoder.decode(YourType.self, from: res.body)
            }
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
}
```

3. Add the test suite to `main.swift`:

```swift
await NewFeatureTests.runAll(app: app)
```

### Best Practices

1. **Clean up after each test** - Always cleanup test data to avoid interference
2. **Use descriptive messages** - Make assertion messages clear and specific
3. **Test both success and failure cases** - Don't just test happy paths
4. **Test permissions** - Verify role-based access control works correctly
5. **Verify database state** - Don't just check API responses, verify data was saved
6. **Handle errors gracefully** - Wrap test code in do-catch blocks

### Example Test Pattern

```swift
static func testSomeFeature(app: Application) async {
    printTestSubheader("Test Some Feature")
    
    do {
        // 1. Setup - Clean up and create test data
        try await TestUtilities.cleanupUsers(on: app.db)
        let (user, token) = try await TestUtilities.createAuthenticatedUser(on: app.db)
        
        // 2. Execute - Make API request
        try await app.test(
            .POST, "/api/endpoint",
            beforeRequest: { req in
                // Add bearer token
                req.headers.add(name: .authorization, value: "Bearer \(token)")
                
                // Encode request body
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                req.body = try ByteBuffer(data: encoder.encode(yourData))
                req.headers.contentType = .json
            }
        ) { res async in
            // 3. Assert - Verify response
            TestUtilities.assertEqual(res.status, .ok, message: "Should succeed")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(YourType.self, from: res.body)
            TestUtilities.assertEqual(response.value, expectedValue, message: "Value should match")
        }
        
        // 4. Verify - Check database state
        let dbRecord = try await YourModel.query(on: app.db).first()
        TestUtilities.assertNotNil(dbRecord, message: "Record should exist")
        
        // 5. Cleanup
        try await TestUtilities.cleanupUsers(on: app.db)
    } catch {
        print("❌ Test failed with error: \(error)")
    }
}
```

## Test Implementation Notes

These tests use a custom `Application.test()` extension method that wraps Vapor's HTTP client:
- Request setup via `beforeRequest` closure that modifies `ClientRequest`
- Response validation via `afterResponse` closure that receives `ClientResponse`
- JSON encoding/decoding uses Foundation's JSONEncoder/JSONDecoder with snake_case strategies
- Authentication tokens are added as HTTP headers manually

This approach provides integration testing without requiring XCTest or XCTVapor dependencies.

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    docker-compose up -d postgres
    sleep 5  # Wait for database
    swift run odysseyTests
    docker-compose down
```

## Troubleshooting

### Tests Fail to Connect to Database

- Verify PostgreSQL is running: `docker ps`
- Check connection settings match your environment
- Ensure database user has proper permissions

### Tests Leave Orphaned Data

- Check that cleanup functions are called in finally blocks
- Verify migrations can be reverted properly
- Consider using test-specific database

### Assertion Failures

- Read the error message carefully - includes expected vs actual values
- Add debug logging if needed
- Verify test data setup is correct

## Future Improvements

Potential enhancements to the test suite:

- [ ] Add performance/load testing
- [ ] Test concurrent operations
- [ ] Add test coverage reporting
- [ ] Mock external dependencies
- [ ] Add database transaction rollback for faster cleanup
- [ ] Implement test database isolation
- [ ] Add API versioning tests
- [ ] Test migration reversibility