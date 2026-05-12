import Foundation

public enum HealthReadType: String, Codable, Hashable, Sendable, CaseIterable {
    case sleepAnalysis
    case heartRate
}

public protocol HealthAuthorizing: Sendable {
    func requestAuthorization(readTypes: [HealthReadType]) async throws
}

public final class SleepAuthorizationCoordinator: Sendable {
    private let authorizer: HealthAuthorizing

    public init(authorizer: HealthAuthorizing) {
        self.authorizer = authorizer
    }

    public func requestSleepAndHeartRateReadAccess() async throws {
        try await authorizer.requestAuthorization(readTypes: [.sleepAnalysis, .heartRate])
    }
}

#if (os(iOS) || os(watchOS)) && canImport(HealthKit)
import HealthKit

public final class LiveHealthAuthorizer: HealthAuthorizing, @unchecked Sendable {
    private let store = HKHealthStore()

    public init() {}

    public func requestAuthorization(readTypes: [HealthReadType]) async throws {
        var types: Set<HKObjectType> = []
        for readType in readTypes {
            switch readType {
            case .sleepAnalysis:
                if let t = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(t) }
            case .heartRate:
                if let t = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(t) }
            }
        }
        try await store.requestAuthorization(toShare: [], read: types)
    }
}
#endif
