import XCTest
@testable import BruxaCore

final class SleepAuthorizationCoordinatorTests: XCTestCase {
    func test_requestSleepAndHeartRateForwardsBothScopes() async throws {
        let mock = MockHealthAuthorizer()
        let coord = SleepAuthorizationCoordinator(authorizer: mock)
        try await coord.requestSleepAndHeartRateReadAccess()
        XCTAssertEqual(Set(mock.requestedTypes), [.sleepAnalysis, .heartRate])
    }
}

private final class MockHealthAuthorizer: HealthAuthorizing {
    var requestedTypes: [HealthReadType] = []
    func requestAuthorization(readTypes: [HealthReadType]) async throws {
        requestedTypes = readTypes
    }
}
