import Foundation
import CoreData

public enum BruxaStorageError: Error {
    case modelNotFound
}

public final class BruxaStorage {
    private let container: NSPersistentContainer

    public init(inMemory: Bool = false) throws {
        // SwiftPM copies .xcdatamodeld as-is (uncompiled); use the pre-compiled
        // .momd bundle that is committed alongside the source .xcdatamodeld.
        guard let modelURL = Bundle.module.url(forResource: "BruxaModel", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw BruxaStorageError.modelNotFound
        }
        let container = NSPersistentContainer(name: "BruxaModel", managedObjectModel: model)
        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        self.container = container
    }

    public func save(_ episodes: [Episode]) async throws {
        // FIXME: concurrent calls with overlapping ids can produce duplicate rows because each background context fetches independently. Safe today (Watch produces episodes sequentially); add a unique constraint on `id` and an NSMergeByPropertyObjectTrumpMergePolicy if a second writer is introduced.
        let context = container.newBackgroundContext()
        try await context.perform {
            for ep in episodes {
                let request = NSFetchRequest<NSManagedObject>(entityName: "EpisodeEntity")
                request.predicate = NSPredicate(format: "id == %@", ep.id as CVarArg)
                request.fetchLimit = 1
                let existing = try context.fetch(request).first
                let row = existing ?? NSEntityDescription.insertNewObject(forEntityName: "EpisodeEntity", into: context)
                row.setValue(ep.id, forKey: "id")
                row.setValue(ep.start, forKey: "start")
                row.setValue(ep.end, forKey: "end")
                row.setValue(ep.intensity, forKey: "intensity")
                row.setValue(ep.isCalibration, forKey: "isCalibration")
            }
            try context.save()
        }
    }

    public func fetchAll() async throws -> [Episode] {
        try await fetch(predicate: nil)
    }

    /// Returns episodes whose `start` falls in the half-open interval `[from, to)`.
    public func fetch(from: Date, to: Date) async throws -> [Episode] {
        try await fetch(predicate: NSPredicate(format: "start >= %@ AND start < %@", from as NSDate, to as NSDate))
    }

    private func fetch(predicate: NSPredicate?) async throws -> [Episode] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "EpisodeEntity")
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]
            let rows = try context.fetch(request)
            return rows.compactMap { row -> Episode? in
                guard let id = row.value(forKey: "id") as? UUID,
                      let start = row.value(forKey: "start") as? Date,
                      let end = row.value(forKey: "end") as? Date,
                      let intensity = row.value(forKey: "intensity") as? Double,
                      let isCalibration = row.value(forKey: "isCalibration") as? Bool else { return nil }
                return Episode(id: id, start: start, end: end, intensity: intensity, isCalibration: isCalibration)
            }
        }
    }
}

extension BruxaStorage {
    public func save(arousalEvents events: [ArousalEvent]) async throws {
        let context = container.newBackgroundContext()
        try await context.perform {
            for event in events {
                let request = NSFetchRequest<NSManagedObject>(entityName: "ArousalEventEntity")
                request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
                request.fetchLimit = 1
                let existing = try context.fetch(request).first
                let row = existing ?? NSEntityDescription.insertNewObject(forEntityName: "ArousalEventEntity", into: context)
                row.setValue(event.id, forKey: "id")
                row.setValue(event.start, forKey: "start")
                row.setValue(event.end, forKey: "end")
                row.setValue(event.peakBPM, forKey: "peakBPM")
                row.setValue(event.baselineBPM, forKey: "baselineBPM")
            }
            try context.save()
        }
    }

    public func fetchArousalEvents(from: Date, to: Date) async throws -> [ArousalEvent] {
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "ArousalEventEntity")
            request.predicate = NSPredicate(format: "start >= %@ AND start < %@", from as NSDate, to as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]
            let rows = try context.fetch(request)
            return rows.compactMap { row in
                guard let id = row.value(forKey: "id") as? UUID,
                      let start = row.value(forKey: "start") as? Date,
                      let end = row.value(forKey: "end") as? Date,
                      let peakBPM = row.value(forKey: "peakBPM") as? Double,
                      let baselineBPM = row.value(forKey: "baselineBPM") as? Double else { return nil }
                return ArousalEvent(id: id, start: start, end: end, peakBPM: peakBPM, baselineBPM: baselineBPM)
            }
        }
    }
}
