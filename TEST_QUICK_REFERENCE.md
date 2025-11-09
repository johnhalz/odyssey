# Odyssey Tests - Quick Reference

## 🚀 Run Tests

```bash
# Start database
docker run --name odyssey-test-db -e POSTGRES_PASSWORD=odysseypassword -d -p 5432:5432 postgres

# Run all tests
swift run odysseyTests
```

## 📊 Test Coverage

**28 Tests Total:**
- ✅ 7 Authentication Tests
- ✅ 10 User Management Tests  
- ✅ 11 Value Tests

## 🔧 Common Commands

```bash
# Build tests
swift build --target odysseyTests

# Check if database is running
docker ps | grep postgres

# View database logs
docker logs odyssey-test-db

# Stop database
docker stop odyssey-test-db

# Start existing database
docker start odyssey-test-db

# Remove database
docker rm -f odyssey-test-db
```

## 📝 Writing New Tests

```swift
// 1. Create new test file: Sources/odysseyTests/MyFeatureTests.swift
struct MyFeatureTests: TestSuite {
    static func runAll(app: Application) async {
        printTestHeader("My Feature Tests")
        await testMyFeature(app: app)
    }
    
    static func testMyFeature(app: Application) async {
        printTestSubheader("Test My Feature")
        do {
            // Setup
            try await TestUtilities.cleanupUsers(on: app.db)
            let (user, token) = try await TestUtilities.createAuthenticatedUser(on: app.db)
            
            // Execute
            try await app.test(.GET, "/api/endpoint") { res async throws in
                // Assert
                TestUtilities.assertEqual(res.status, .ok, message: "Should succeed")
                let data = try TestUtilities.jsonDecoder.decode(MyType.self, from: try res.bodyBuffer)
                TestUtilities.assertEqual(data.value, "expected", message: "Value should match")
            }
            
            // Cleanup
            try await TestUtilities.cleanupUsers(on: app.db)
        } catch {
            print("❌ Test failed: \(error)")
        }
    }
}

// 2. Register in main.swift
await MyFeatureTests.runAll(app: app)
```

## 🛠 Test Utilities

```swift
// Create users
let (admin, token) = try await TestUtilities.createAdminUser(on: db)
let (tech, token) = try await TestUtilities.createTechnicianUser(on: db)
let (user, token) = try await TestUtilities.createAuthenticatedUser(on: db, email: "test@example.com")

// Cleanup
try await TestUtilities.cleanupUsers(on: db)
try await TestUtilities.cleanupValues(on: db)
try await TestUtilities.cleanupUnitRecords(on: db)

// Assertions
TestUtilities.assertEqual(actual, expected, message: "Should match")
TestUtilities.assertTrue(condition, message: "Should be true")
TestUtilities.assertFalse(condition, message: "Should be false")
TestUtilities.assertNotNil(value, message: "Should exist")
TestUtilities.assertNil(value, message: "Should be nil")
TestUtilities.assertCount(array, 3, message: "Should have 3 items")
TestUtilities.assertContains(array, where: { $0.id == id }, message: "Should contain item")
```

## 🔐 Making HTTP Requests

```swift
// GET request
try await app.test(.GET, "/api/endpoint") { res async throws in
    TestUtilities.assertEqual(res.status, .ok, message: "Should succeed")
    let data = try TestUtilities.jsonDecoder.decode(MyType.self, from: try res.bodyBuffer)
}

// POST with authentication
try await app.test(
    .POST, "/api/endpoint",
    beforeRequest: { req in
        req.headers.add(name: .authorization, value: "Bearer \(token)")
        req.body = try ByteBuffer(data: TestUtilities.jsonEncoder.encode(myData))
        req.headers.contentType = .json
    }
) { res async throws in
    TestUtilities.assertEqual(res.status, .ok, message: "Should succeed")
}

// Basic Auth (login)
try await app.test(
    .POST, "/api/login",
    beforeRequest: { req in
        let basic = "email@example.com:password".data(using: .utf8)!.base64EncodedString()
        req.headers.add(name: .authorization, value: "Basic \(basic)")
    }
) { res async throws in
    let token = try TestUtilities.jsonDecoder.decode(UserToken.self, from: try res.bodyBuffer)
}
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Database connection failed | `docker ps` - check if postgres is running |
| Port 5432 in use | `lsof -i :5432` - kill process or use different port |
| Migration failed | `swift run odyssey migrate --revert` then retry |
| Tests hang | Check for infinite loops or missing cleanup |
| Compilation errors | Ensure all models are marked `public` |

## 📁 Test File Structure

```
Sources/odysseyTests/
├── main.swift                      # Test runner
├── TestUtilities.swift             # Helper functions
├── AuthenticationTests.swift       # Auth tests (7 tests)
├── UserManagementTests.swift       # User tests (10 tests)
├── ValueTests.swift                # Value tests (11 tests)
└── README.md                       # Detailed documentation
```

## 📚 Documentation

- **README.md** - Comprehensive test documentation
- **TESTS_SETUP.md** - Setup and troubleshooting guide
- **TESTING_SUMMARY.md** - Complete implementation summary
- **TEST_QUICK_REFERENCE.md** - This file

## ✅ Test Output

```
Running Odyssey Tests...

============================================================
Running: Authentication Tests
============================================================

--- Test Ping Endpoint ---
✅ Ping should return 200 OK
✅ Ping response should contain 'Odyssey'
✅ Ping response should contain 'running'

...

✅ All tests completed!
```

## 🎯 Best Practices

1. **Clean up after each test** - Use cleanup utilities
2. **Isolate tests** - Each test should be independent
3. **Use descriptive messages** - Make failures easy to debug
4. **Test both success and failure** - Cover edge cases
5. **Verify database state** - Don't just check API responses
6. **Handle errors gracefully** - Wrap in do-catch blocks

## 🚦 CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Start PostgreSQL
        run: |
          docker run -d -p 5432:5432 \
            -e POSTGRES_PASSWORD=odysseypassword \
            postgres
      - name: Wait for database
        run: sleep 5
      - name: Run tests
        run: swift run odysseyTests
```

---

**Quick Start:** `swift run odysseyTests`  
**Need Help?** See `Sources/odysseyTests/README.md`
