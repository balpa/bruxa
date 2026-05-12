import XCTest
@testable import BruxaCore

final class SleepAuthorizationCoordinatorTests: XCTestCase {
    func test_requestForwardsToAuthorizer() async throws {
        let mockAuthorizer = MockHealthAuthorizer()
        let coordinator = SleepAuthorizationCoordinator(authorizer: mockAuthorizer)

        try await coordinator.requestSleepReadAccess()

        XCTAssertEqual(mockAuthorizer.readTypeIdentifiers, ["HKCategoryTypeIdentifierSleepAnalysis"])
    }
}

private final class MockHealthAuthorizer: HealthAuthorizing {
    private(set) var readTypeIdentifiers: [String] = []

    func requestAuthorization(readIdentifiers: [String]) async throws {
        readTypeIdentifiers = readIdentifiers
    }
}
