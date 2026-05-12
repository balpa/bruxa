import Foundation

public protocol HealthAuthorizing {
    func requestAuthorization(readIdentifiers: [String]) async throws
}

public final class SleepAuthorizationCoordinator {
    private let authorizer: HealthAuthorizing

    public init(authorizer: HealthAuthorizing) {
        self.authorizer = authorizer
    }

    public func requestSleepReadAccess() async throws {
        try await authorizer.requestAuthorization(readIdentifiers: ["HKCategoryTypeIdentifierSleepAnalysis"])
    }
}

#if (os(iOS) || os(watchOS)) && canImport(HealthKit)
import HealthKit

public final class LiveHealthAuthorizer: HealthAuthorizing {
    private let store = HKHealthStore()

    public init() {}

    public func requestAuthorization(readIdentifiers: [String]) async throws {
        let types = readIdentifiers.compactMap { HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: $0)) }
        try await store.requestAuthorization(toShare: [], read: Set(types))
    }
}
#endif
