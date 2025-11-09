import Fluent
import Vapor
import odysseyLib

// Top-level async entry point
let env = try Environment.detect()
let app = try await Application.make(env)

do {
    try await configure(app)

    // Revert all migrations first to ensure clean state
    _ = try await app.autoRevert()

    // Run migrations
    _ = try await app.autoMigrate()

    // Run all tests
    print("Running Odyssey Tests...")

    await AuthenticationTests.runAll(app: app)
    await UserManagementTests.runAll(app: app)
    await ValueTests.runAll(app: app)

    print("\n✅ All tests completed!")

    // Revert migrations after tests
    _ = try await app.autoRevert()

    try await app.asyncShutdown()
} catch {
    app.logger.report(error: error)
    try? await app.asyncShutdown()
    throw error
}
