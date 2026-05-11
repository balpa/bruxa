import Foundation

public enum SleepState: Equatable, Sendable {
    case asleep
    case awake
}

public protocol SleepStateProvider {
    func start(handler: @escaping (SleepState) -> Void)
    func stop()
}

public final class ScriptedSleepStateProvider: SleepStateProvider {
    private var handler: ((SleepState) -> Void)?

    public init() {}

    public func start(handler: @escaping (SleepState) -> Void) {
        self.handler = handler
    }

    public func stop() {
        handler = nil
    }

    public func emit(_ state: SleepState) {
        handler?(state)
    }
}

#if (os(iOS) || os(watchOS)) && canImport(HealthKit)
import HealthKit

public final class HealthKitSleepStateProvider: SleepStateProvider {
    private let store = HKHealthStore()
    private var query: HKObserverQuery?
    private var handler: ((SleepState) -> Void)?

    public init() {}

    public func start(handler: @escaping (SleepState) -> Void) {
        self.handler = handler
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, _, _ in
            self?.fetchLatestSample()
        }
        store.execute(query)
        self.query = query
    }

    public func stop() {
        if let query { store.stop(query) }
        query = nil
        handler = nil
    }

    private func fetchLatestSample() {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            guard let sample = samples?.first as? HKCategorySample else { return }
            let now = Date()
            let isAsleep = sample.startDate <= now && now <= sample.endDate && sample.value != HKCategoryValueSleepAnalysis.awake.rawValue
            self?.handler?(isAsleep ? .asleep : .awake)
        }
        store.execute(q)
    }
}
#endif
