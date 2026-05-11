# Bruxism Tracker — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a working two-target Apple Watch + iPhone app that, at the end of this plan, records sensor-gated overnight data from the Watch, persists episodes to local CoreData on both sides, and optionally exports raw motion CSV from the Watch for use as ML pilot data — providing the harness needed to either proceed with Path A (EMG-splint pilot dataset) or Path B (heuristic MVP with bootstrap).

**Architecture:** A single Xcode workspace contains an iOS target (`BruxaApp`), a watchOS target (`BruxaWatch`), and a shared Swift Package (`BruxaCore`) that holds the domain models, CoreData stack, and Codable connectivity payloads consumed by both. Watch-side recording is sleep-gated via HealthKit; data flows Watch → iPhone via WatchConnectivity. Detection logic is stubbed (returns no episodes) until a later plan replaces the stub with either heuristic or CoreML output.

**Tech Stack:**
- Swift 5.10, Xcode 16+
- iOS 17+, watchOS 10+ deployment targets
- SwiftUI for all UI
- CoreData for persistence
- HealthKit (sleep analysis read)
- CoreMotion (accelerometer + gyroscope)
- WatchConnectivity (message + file transfer)
- XCTest for unit tests

**Dependencies between tasks:** Tasks 1–4 establish the workspace and models; everything else depends on them. Tasks 5 (Storage) → 11 (Phone connectivity) form the data pipeline. Tasks 6 → 9 (Watch recording) can be developed in parallel with the iOS data pipeline. Tasks 12–14 are thin UI shells. Task 15 is the pilot CSV export — only useful if Path A is later chosen, but it's quick to build and harmless under Path B.

**Decision gate at end of plan:** Resolve dataset Path A vs B (literature review) before starting the next plan.

---

## File Layout (created during this plan)

```
bruxa/
├── docs/superpowers/specs/2026-05-11-bruxism-watch-app-design.md  (already exists)
├── docs/superpowers/plans/2026-05-11-foundation.md                (this file)
├── .gitignore
├── README.md
└── app/                                            ← Xcode workspace lives here
    ├── Bruxa.xcworkspace
    ├── BruxaCore/                                  ← Swift Package
    │   ├── Package.swift
    │   ├── Sources/BruxaCore/
    │   │   ├── Episode.swift
    │   │   ├── SensorSample.swift
    │   │   ├── ConnectivityPayload.swift
    │   │   ├── BruxaStorage.swift
    │   │   └── BruxaModel.xcdatamodeld/
    │   └── Tests/BruxaCoreTests/
    │       ├── EpisodeTests.swift
    │       ├── ConnectivityPayloadTests.swift
    │       └── BruxaStorageTests.swift
    ├── BruxaApp/                                   ← iOS target
    │   ├── BruxaApp.swift
    │   ├── HealthKit/SleepAuthorizationCoordinator.swift
    │   ├── Connectivity/PhoneConnectivityCoordinator.swift
    │   ├── Pilot/PilotFileImporter.swift
    │   └── UI/RootView.swift
    ├── BruxaAppTests/
    │   ├── SleepAuthorizationCoordinatorTests.swift
    │   └── PhoneConnectivityCoordinatorTests.swift
    ├── BruxaWatch/                                 ← watchOS target
    │   ├── BruxaWatchApp.swift
    │   ├── Sensors/MotionProvider.swift
    │   ├── Sensors/SensorRecorder.swift
    │   ├── Sleep/SleepStateProvider.swift
    │   ├── Sleep/SleepSessionManager.swift
    │   ├── Detection/EpisodeDetector.swift           (stub returning no episodes)
    │   ├── Pilot/PilotCSVWriter.swift                (DEBUG only)
    │   ├── Connectivity/WatchConnectivityCoordinator.swift
    │   └── UI/StatusView.swift
    └── BruxaWatchTests/
        ├── SensorRecorderTests.swift
        ├── SleepSessionManagerTests.swift
        ├── EpisodeDetectorTests.swift
        └── PilotCSVWriterTests.swift
```

**Note on commits:** Every task ends with a commit. Use Conventional Commits style (`feat:`, `test:`, `chore:`, `refactor:`).

---

### Task 1: Initialize repository and workspace

**Files:**
- Create: `bruxa/.gitignore`
- Create: `bruxa/README.md`
- Create: `bruxa/app/Bruxa.xcworkspace` (via Xcode)

- [ ] **Step 1: Initialize git repo at `bruxa/`**

```bash
cd /Users/berke.altiparmak/Documents/bruxa
git init
```

- [ ] **Step 2: Add `.gitignore`**

Write `bruxa/.gitignore`:

```gitignore
# Xcode
build/
DerivedData/
*.xcuserstate
xcuserdata/
*.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/

# Swift Package Manager
.build/
Package.resolved
.swiftpm/

# macOS
.DS_Store

# Pilot data (raw recordings should not be in git)
app/PilotData/
*.csv
```

- [ ] **Step 3: Add a minimal README**

Write `bruxa/README.md`:

```markdown
# Bruxa — Sleep Bruxism Tracker

Apple Watch app that records overnight wrist motion and reports jaw clenching episodes.

See `docs/superpowers/specs/2026-05-11-bruxism-watch-app-design.md` for the design.

## Layout

- `app/` — Xcode workspace, iOS + watchOS targets, BruxaCore Swift Package
- `docs/` — design specs and implementation plans
```

- [ ] **Step 4: Create the Xcode workspace**

In Xcode (manual GUI step — no CLI equivalent that produces a clean workspace):

1. File → New → Workspace → name `Bruxa.xcworkspace`, save inside `bruxa/app/`.
2. Close Xcode.

Verify the workspace bundle exists:

```bash
ls bruxa/app/Bruxa.xcworkspace/contents.xcworkspacedata
```

Expected: file exists.

- [ ] **Step 5: Commit**

```bash
git add .gitignore README.md app/Bruxa.xcworkspace
git commit -m "chore: initialize repo, workspace, and gitignore"
```

---

### Task 2: Create iOS app target (`BruxaApp`)

**Files:**
- Create: `app/BruxaApp/` (Xcode-generated)
- Modify: `app/Bruxa.xcworkspace` (add project reference)

- [ ] **Step 1: Create the iOS app project in Xcode**

1. Open `Bruxa.xcworkspace`.
2. File → New → Project → iOS → App.
3. Product Name: `BruxaApp`. Interface: SwiftUI. Language: Swift. Storage: None. Include Tests: yes.
4. Bundle Identifier: `com.bruxa.app` (or your own reverse-DNS).
5. Save inside `bruxa/app/`. When Xcode asks, **add to workspace `Bruxa`**.

- [ ] **Step 2: Set deployment target to iOS 17**

In Xcode → project `BruxaApp` → target `BruxaApp` → Minimum Deployment → `iOS 17.0`.

- [ ] **Step 3: Build and run on iPhone 15 simulator**

In Xcode, select scheme `BruxaApp`, destination `iPhone 15 (iOS 17.x)`, ⌘R. Expected: blank "Hello, world!" view appears.

- [ ] **Step 4: Run the auto-generated test to verify XCTest works**

In Xcode: ⌘U with the `BruxaApp` scheme. Expected: `BruxaAppTests/BruxaAppTests.swift` (the Xcode boilerplate test) passes.

- [ ] **Step 5: Commit**

```bash
cd /Users/berke.altiparmak/Documents/bruxa
git add app/
git commit -m "feat: add iOS app target with SwiftUI scaffolding"
```

---

### Task 3: Create watchOS app target (`BruxaWatch`)

**Files:**
- Create: `app/BruxaWatch/` (Xcode-generated)

- [ ] **Step 1: Create the watchOS app project**

1. In Xcode: File → New → Project → watchOS → App.
2. Product Name: `BruxaWatch`. Interface: SwiftUI. Language: Swift. Include Tests: yes.
3. Bundle Identifier: `com.bruxa.watch`.
4. Save inside `bruxa/app/`. Add to workspace `Bruxa`.

- [ ] **Step 2: Set deployment target to watchOS 10**

In Xcode → target `BruxaWatch` → Minimum Deployment → `watchOS 10.0`.

- [ ] **Step 3: Enable required background modes for the Watch**

Target `BruxaWatch` → Signing & Capabilities → + Capability → **Background Modes**. Check:
- Workout processing (gives us long-running background CoreMotion)
- Background fetch

This is the key entitlement that lets CoreMotion run overnight on the Watch — without it the OS terminates the app within minutes.

- [ ] **Step 4: Build and run on Apple Watch simulator**

Select scheme `BruxaWatch`, destination `Apple Watch Series 9 (45mm)`, ⌘R. Expected: blank Watch screen appears in the simulator.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/ app/Bruxa.xcworkspace/
git commit -m "feat: add watchOS app target with background entitlements"
```

---

### Task 4: Create `BruxaCore` Swift Package

**Files:**
- Create: `app/BruxaCore/Package.swift`
- Create: `app/BruxaCore/Sources/BruxaCore/Placeholder.swift`
- Create: `app/BruxaCore/Tests/BruxaCoreTests/PlaceholderTests.swift`

- [ ] **Step 1: Create the package via CLI**

```bash
cd /Users/berke.altiparmak/Documents/bruxa/app
mkdir BruxaCore && cd BruxaCore
swift package init --type library --name BruxaCore
```

- [ ] **Step 2: Replace `Package.swift` with explicit platform requirements**

Write `app/BruxaCore/Package.swift`:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BruxaCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "BruxaCore", targets: ["BruxaCore"])
    ],
    targets: [
        .target(name: "BruxaCore"),
        .testTarget(name: "BruxaCoreTests", dependencies: ["BruxaCore"])
    ]
)
```

- [ ] **Step 3: Add the package to the workspace and link it to all four targets**

In Xcode: File → Add Package Dependencies → Add Local… → select `bruxa/app/BruxaCore` → Add. The package now appears in the workspace sidebar.

Then for **each of the four targets** (`BruxaApp`, `BruxaAppTests`, `BruxaWatch`, `BruxaWatchTests`) → General → Frameworks, Libraries, and Embedded Content → `+` → select `BruxaCore`.

The test targets must be linked explicitly: later test files use `import BruxaCore` directly, and `@testable import BruxaWatch` does not transitively expose the package.

- [ ] **Step 4: Run the auto-generated package test**

```bash
cd /Users/berke.altiparmak/Documents/bruxa/app/BruxaCore
swift test
```

Expected: `Test Suite 'All tests' passed`.

- [ ] **Step 5: Commit**

```bash
cd /Users/berke.altiparmak/Documents/bruxa
git add app/BruxaCore/
git commit -m "feat: add BruxaCore shared Swift package"
```

---

### Task 5: `Episode` domain model

**Files:**
- Create: `app/BruxaCore/Sources/BruxaCore/Episode.swift`
- Create: `app/BruxaCore/Tests/BruxaCoreTests/EpisodeTests.swift`
- Delete: `app/BruxaCore/Sources/BruxaCore/BruxaCore.swift` (the auto-generated placeholder)
- Delete: `app/BruxaCore/Tests/BruxaCoreTests/BruxaCoreTests.swift` (auto-generated)

- [ ] **Step 1: Write the failing test**

Write `app/BruxaCore/Tests/BruxaCoreTests/EpisodeTests.swift`:

```swift
import XCTest
@testable import BruxaCore

final class EpisodeTests: XCTestCase {
    func test_durationIsEndMinusStart() {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 1_045)
        let episode = Episode(
            id: UUID(),
            start: start,
            end: end,
            intensity: 0.7,
            isCalibration: false
        )
        XCTAssertEqual(episode.duration, 45)
    }

    func test_episodeIsCodable() throws {
        let original = Episode(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 1_030),
            intensity: 0.5,
            isCalibration: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Episode.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func test_intensityIsClampedToZeroOneRange() {
        let tooLow = Episode(id: UUID(), start: .now, end: .now, intensity: -0.5, isCalibration: false)
        let tooHigh = Episode(id: UUID(), start: .now, end: .now, intensity: 1.5, isCalibration: false)
        XCTAssertEqual(tooLow.intensity, 0)
        XCTAssertEqual(tooHigh.intensity, 1)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/berke.altiparmak/Documents/bruxa/app/BruxaCore
swift test --filter EpisodeTests
```

Expected: FAIL with "cannot find 'Episode' in scope".

- [ ] **Step 3: Implement `Episode`**

Delete the auto-generated `BruxaCore.swift` and `BruxaCoreTests.swift`. Write `app/BruxaCore/Sources/BruxaCore/Episode.swift`:

```swift
import Foundation

public struct Episode: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let intensity: Double
    public let isCalibration: Bool

    public init(id: UUID, start: Date, end: Date, intensity: Double, isCalibration: Bool) {
        self.id = id
        self.start = start
        self.end = end
        self.intensity = max(0, min(1, intensity))
        self.isCalibration = isCalibration
    }

    public var duration: TimeInterval { end.timeIntervalSince(start) }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
swift test --filter EpisodeTests
```

Expected: all three tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/berke.altiparmak/Documents/bruxa
git add app/BruxaCore/
git commit -m "feat(core): add Episode domain model"
```

---

### Task 6: `SensorSample` raw motion sample

**Files:**
- Create: `app/BruxaCore/Sources/BruxaCore/SensorSample.swift`
- Create: `app/BruxaCore/Tests/BruxaCoreTests/SensorSampleTests.swift`

- [ ] **Step 1: Write the failing test**

Write `app/BruxaCore/Tests/BruxaCoreTests/SensorSampleTests.swift`:

```swift
import XCTest
@testable import BruxaCore

final class SensorSampleTests: XCTestCase {
    func test_csvRowEncodesAllAxes() {
        let sample = SensorSample(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            accelX: 0.10, accelY: -0.20, accelZ: 0.98,
            gyroX: 0.01, gyroY: 0.02, gyroZ: -0.03
        )
        XCTAssertEqual(
            sample.csvRow,
            "1700000000.000,0.100000,-0.200000,0.980000,0.010000,0.020000,-0.030000"
        )
    }

    func test_csvHeaderListsExpectedColumns() {
        XCTAssertEqual(
            SensorSample.csvHeader,
            "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z"
        )
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
swift test --filter SensorSampleTests
```

Expected: FAIL with "cannot find 'SensorSample'".

- [ ] **Step 3: Implement `SensorSample`**

Write `app/BruxaCore/Sources/BruxaCore/SensorSample.swift`:

```swift
import Foundation

public struct SensorSample: Equatable, Sendable {
    public let timestamp: Date
    public let accelX: Double
    public let accelY: Double
    public let accelZ: Double
    public let gyroX: Double
    public let gyroY: Double
    public let gyroZ: Double

    public init(
        timestamp: Date,
        accelX: Double, accelY: Double, accelZ: Double,
        gyroX: Double, gyroY: Double, gyroZ: Double
    ) {
        self.timestamp = timestamp
        self.accelX = accelX
        self.accelY = accelY
        self.accelZ = accelZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
    }

    public static let csvHeader =
        "timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z"

    public var csvRow: String {
        let ts = String(format: "%.3f", timestamp.timeIntervalSince1970)
        let f: (Double) -> String = { String(format: "%.6f", $0) }
        return [ts, f(accelX), f(accelY), f(accelZ), f(gyroX), f(gyroY), f(gyroZ)].joined(separator: ",")
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
swift test --filter SensorSampleTests
```

Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaCore/
git commit -m "feat(core): add SensorSample raw motion model"
```

---

### Task 7: `ConnectivityPayload` for Watch→Phone transfer

**Files:**
- Create: `app/BruxaCore/Sources/BruxaCore/ConnectivityPayload.swift`
- Create: `app/BruxaCore/Tests/BruxaCoreTests/ConnectivityPayloadTests.swift`

- [ ] **Step 1: Write the failing test**

Write `app/BruxaCore/Tests/BruxaCoreTests/ConnectivityPayloadTests.swift`:

```swift
import XCTest
@testable import BruxaCore

final class ConnectivityPayloadTests: XCTestCase {
    func test_encodesAndDecodesEpisodesBatch() throws {
        let episodes = [
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(15), intensity: 0.4, isCalibration: false),
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(20), intensity: 0.8, isCalibration: true)
        ]
        let payload = EpisodesBatch(deviceID: "watch-1", episodes: episodes)
        let data = try payload.encoded()
        let decoded = try EpisodesBatch.decoded(from: data)
        XCTAssertEqual(decoded, payload)
    }

    func test_emptyBatchRoundTrips() throws {
        let payload = EpisodesBatch(deviceID: "watch-1", episodes: [])
        let data = try payload.encoded()
        let decoded = try EpisodesBatch.decoded(from: data)
        XCTAssertEqual(decoded.episodes, [])
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
swift test --filter ConnectivityPayloadTests
```

Expected: FAIL with "cannot find 'EpisodesBatch'".

- [ ] **Step 3: Implement `EpisodesBatch`**

Write `app/BruxaCore/Sources/BruxaCore/ConnectivityPayload.swift`:

```swift
import Foundation

public struct EpisodesBatch: Codable, Equatable, Sendable {
    public let deviceID: String
    public let episodes: [Episode]

    public init(deviceID: String, episodes: [Episode]) {
        self.deviceID = deviceID
        self.episodes = episodes
    }

    public func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    public static func decoded(from data: Data) throws -> EpisodesBatch {
        try JSONDecoder().decode(EpisodesBatch.self, from: data)
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
swift test --filter ConnectivityPayloadTests
```

Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaCore/
git commit -m "feat(core): add EpisodesBatch connectivity payload"
```

---

### Task 8: CoreData store for episodes (`BruxaStorage`)

**Files:**
- Create: `app/BruxaCore/Sources/BruxaCore/BruxaModel.xcdatamodeld/BruxaModel.xcdatamodel/contents`
- Create: `app/BruxaCore/Sources/BruxaCore/BruxaStorage.swift`
- Create: `app/BruxaCore/Tests/BruxaCoreTests/BruxaStorageTests.swift`

- [ ] **Step 1: Add the `.xcdatamodeld` file**

In Xcode, with the `BruxaCore` package open: File → New → File → iOS → Core Data → Data Model. Name: `BruxaModel`. Save under `app/BruxaCore/Sources/BruxaCore/`.

In the model editor, add an entity:

- Name: `EpisodeEntity`
- Attributes:
  - `id` — UUID, not optional
  - `start` — Date, not optional
  - `end` — Date, not optional
  - `intensity` — Double, not optional, default 0
  - `isCalibration` — Boolean, not optional, default NO
- Codegen: **Manual/None** (we'll bridge via Swift, not let Xcode generate).

Tell SwiftPM to ship the resource by updating `Package.swift`:

```swift
.target(
    name: "BruxaCore",
    resources: [.process("BruxaModel.xcdatamodeld")]
),
```

- [ ] **Step 2: Write the failing test**

Write `app/BruxaCore/Tests/BruxaCoreTests/BruxaStorageTests.swift`:

```swift
import XCTest
@testable import BruxaCore

final class BruxaStorageTests: XCTestCase {
    func test_saveAndFetchReturnsSameEpisode() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let episode = Episode(
            id: UUID(),
            start: Date(timeIntervalSince1970: 1_000),
            end: Date(timeIntervalSince1970: 1_030),
            intensity: 0.4,
            isCalibration: false
        )
        try await storage.save([episode])
        let fetched = try await storage.fetchAll()
        XCTAssertEqual(fetched, [episode])
    }

    func test_saveIsIdempotentOnSameID() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let id = UUID()
        let first = Episode(id: id, start: .now, end: .now.addingTimeInterval(10), intensity: 0.3, isCalibration: false)
        let second = Episode(id: id, start: first.start, end: first.end, intensity: 0.9, isCalibration: false)
        try await storage.save([first])
        try await storage.save([second])
        let fetched = try await storage.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.intensity, 0.9)
    }

    func test_fetchByDateRangeReturnsOnlyMatching() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let inside = Episode(id: UUID(), start: Date(timeIntervalSince1970: 1_500), end: Date(timeIntervalSince1970: 1_530), intensity: 0.5, isCalibration: false)
        let outside = Episode(id: UUID(), start: Date(timeIntervalSince1970: 9_000), end: Date(timeIntervalSince1970: 9_030), intensity: 0.5, isCalibration: false)
        try await storage.save([inside, outside])
        let result = try await storage.fetch(
            from: Date(timeIntervalSince1970: 1_000),
            to: Date(timeIntervalSince1970: 2_000)
        )
        XCTAssertEqual(result, [inside])
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

```bash
swift test --filter BruxaStorageTests
```

Expected: FAIL with "cannot find 'BruxaStorage'".

- [ ] **Step 4: Implement `BruxaStorage`**

Write `app/BruxaCore/Sources/BruxaCore/BruxaStorage.swift`:

```swift
import Foundation
import CoreData

public enum BruxaStorageError: Error {
    case modelNotFound
}

public final class BruxaStorage {
    private let container: NSPersistentContainer

    public init(inMemory: Bool = false) throws {
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
```

- [ ] **Step 5: Run the tests to verify they pass**

```bash
swift test --filter BruxaStorageTests
```

Expected: all three tests pass.

- [ ] **Step 6: Commit**

```bash
git add app/BruxaCore/
git commit -m "feat(core): add CoreData-backed BruxaStorage"
```

---

### Task 9: `MotionProvider` protocol and `CoreMotionProvider` adapter

**Files:**
- Create: `app/BruxaWatch/Sensors/MotionProvider.swift`
- Create: `app/BruxaWatchTests/MotionProviderTests.swift`

A protocol-first wrapper around `CMMotionManager` is essential — `CMMotionManager` cannot be unit-tested directly because it talks to physical hardware. All higher-level recording logic depends on this protocol so we can drive it from tests with scripted samples.

- [ ] **Step 1: Write the failing test for the in-memory test double**

Write `app/BruxaWatchTests/MotionProviderTests.swift`:

```swift
import XCTest
import BruxaCore
@testable import BruxaWatch

final class MotionProviderTests: XCTestCase {
    func test_scriptedProviderEmitsScheduledSamples() async {
        let s1 = SensorSample(timestamp: Date(timeIntervalSince1970: 1), accelX: 0.1, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
        let s2 = SensorSample(timestamp: Date(timeIntervalSince1970: 2), accelX: 0.2, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
        let provider = ScriptedMotionProvider(samples: [s1, s2])

        var received: [SensorSample] = []
        provider.start { sample in received.append(sample) }
        await provider.runUntilEmpty()
        provider.stop()

        XCTAssertEqual(received, [s1, s2])
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

In Xcode, ⌘U with the `BruxaWatch` scheme on a Watch simulator. Expected: FAIL with "cannot find 'ScriptedMotionProvider'".

- [ ] **Step 3: Implement the protocol and both adapters**

Write `app/BruxaWatch/Sensors/MotionProvider.swift`:

```swift
import Foundation
import CoreMotion
import BruxaCore

public protocol MotionProvider {
    func start(handler: @escaping (SensorSample) -> Void)
    func stop()
}

#if os(watchOS)
public final class CoreMotionProvider: MotionProvider {
    private let manager = CMMotionManager()
    private let sampleRateHz: Double

    public init(sampleRateHz: Double = 50) {
        self.sampleRateHz = sampleRateHz
        manager.deviceMotionUpdateInterval = 1.0 / sampleRateHz
    }

    public func start(handler: @escaping (SensorSample) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let sample = SensorSample(
                timestamp: Date(),
                accelX: motion.userAcceleration.x,
                accelY: motion.userAcceleration.y,
                accelZ: motion.userAcceleration.z,
                gyroX: motion.rotationRate.x,
                gyroY: motion.rotationRate.y,
                gyroZ: motion.rotationRate.z
            )
            handler(sample)
        }
    }

    public func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
#endif

public final class ScriptedMotionProvider: MotionProvider {
    private let samples: [SensorSample]
    private var handler: ((SensorSample) -> Void)?
    private var index = 0

    public init(samples: [SensorSample]) {
        self.samples = samples
    }

    public func start(handler: @escaping (SensorSample) -> Void) {
        self.handler = handler
    }

    public func stop() {
        self.handler = nil
    }

    public func runUntilEmpty() async {
        while index < samples.count {
            handler?(samples[index])
            index += 1
            await Task.yield()
        }
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U in Xcode. Expected: `MotionProviderTests` passes.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Sensors/ app/BruxaWatchTests/
git commit -m "feat(watch): add MotionProvider protocol with CoreMotion + scripted adapters"
```

---

### Task 10: `SleepStateProvider` protocol and HealthKit adapter

**Files:**
- Create: `app/BruxaWatch/Sleep/SleepStateProvider.swift`
- Create: `app/BruxaWatchTests/SleepStateProviderTests.swift`

- [ ] **Step 1: Write the failing test for the test double**

Write `app/BruxaWatchTests/SleepStateProviderTests.swift`:

```swift
import XCTest
@testable import BruxaWatch

final class SleepStateProviderTests: XCTestCase {
    func test_scriptedProviderEmitsScheduledStates() async {
        let provider = ScriptedSleepStateProvider()
        var received: [SleepState] = []
        provider.start { state in received.append(state) }

        provider.emit(.asleep)
        provider.emit(.awake)
        provider.stop()

        XCTAssertEqual(received, [.asleep, .awake])
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U in Xcode. Expected: FAIL.

- [ ] **Step 3: Implement protocol and adapters**

Write `app/BruxaWatch/Sleep/SleepStateProvider.swift`:

```swift
import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

public enum SleepState: Equatable, Sendable {
    case asleep
    case awake
}

public protocol SleepStateProvider {
    func start(handler: @escaping (SleepState) -> Void)
    func stop()
}

#if canImport(HealthKit)
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
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Sleep/ app/BruxaWatchTests/
git commit -m "feat(watch): add SleepStateProvider with HealthKit + scripted adapters"
```

---

### Task 11: `SensorRecorder` — 30-second window buffering

**Files:**
- Create: `app/BruxaWatch/Sensors/SensorRecorder.swift`
- Create: `app/BruxaWatchTests/SensorRecorderTests.swift`

- [ ] **Step 1: Write the failing tests**

Write `app/BruxaWatchTests/SensorRecorderTests.swift`:

```swift
import XCTest
import BruxaCore
@testable import BruxaWatch

final class SensorRecorderTests: XCTestCase {
    func test_emitsWindowEvery30SecondsOfSamples() async {
        let baseTime = Date(timeIntervalSince1970: 1_000)
        // 50Hz × 30s = 1500 samples per window; we'll send 1501 to trigger one window and start a second
        var samples: [SensorSample] = []
        for i in 0..<1501 {
            samples.append(makeSample(at: baseTime.addingTimeInterval(Double(i) * 0.02)))
        }
        let provider = ScriptedMotionProvider(samples: samples)
        let recorder = SensorRecorder(motion: provider, windowSeconds: 30)

        var windows: [[SensorSample]] = []
        recorder.start { window in windows.append(window) }
        await provider.runUntilEmpty()
        recorder.stop()

        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows.first?.count, 1500)
    }

    func test_stopFlushesPartialWindow() async {
        let baseTime = Date(timeIntervalSince1970: 1_000)
        let samples = (0..<10).map { makeSample(at: baseTime.addingTimeInterval(Double($0) * 0.02)) }
        let provider = ScriptedMotionProvider(samples: samples)
        let recorder = SensorRecorder(motion: provider, windowSeconds: 30)

        var partials: [[SensorSample]] = []
        recorder.start(onWindow: { _ in }, onStopFlush: { partials.append($0) })
        await provider.runUntilEmpty()
        recorder.stop()

        XCTAssertEqual(partials.first?.count, 10)
    }

    private func makeSample(at date: Date) -> SensorSample {
        SensorSample(timestamp: date, accelX: 0, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U. Expected: FAIL — `SensorRecorder` not defined.

- [ ] **Step 3: Implement `SensorRecorder`**

Write `app/BruxaWatch/Sensors/SensorRecorder.swift`:

```swift
import Foundation
import BruxaCore

public final class SensorRecorder {
    private let motion: MotionProvider
    private let samplesPerWindow: Int
    private var buffer: [SensorSample] = []
    private var onWindow: (([SensorSample]) -> Void)?
    private var onStopFlush: (([SensorSample]) -> Void)?

    public init(motion: MotionProvider, sampleRateHz: Double = 50, windowSeconds: Double = 30) {
        self.motion = motion
        self.samplesPerWindow = Int(sampleRateHz * windowSeconds)
    }

    public func start(onWindow: @escaping ([SensorSample]) -> Void, onStopFlush: (([SensorSample]) -> Void)? = nil) {
        self.onWindow = onWindow
        self.onStopFlush = onStopFlush
        motion.start { [weak self] sample in
            guard let self else { return }
            self.buffer.append(sample)
            if self.buffer.count >= self.samplesPerWindow {
                let window = Array(self.buffer.prefix(self.samplesPerWindow))
                self.buffer.removeFirst(self.samplesPerWindow)
                self.onWindow?(window)
            }
        }
    }

    public func stop() {
        motion.stop()
        if !buffer.isEmpty {
            onStopFlush?(buffer)
            buffer.removeAll()
        }
        onWindow = nil
        onStopFlush = nil
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Sensors/ app/BruxaWatchTests/
git commit -m "feat(watch): add SensorRecorder with 30s window buffering"
```

---

### Task 12: `EpisodeDetector` stub

**Files:**
- Create: `app/BruxaWatch/Detection/EpisodeDetector.swift`
- Create: `app/BruxaWatchTests/EpisodeDetectorTests.swift`

The detector is intentionally a stub for this plan — it always returns `nil` (no episode). It defines the interface that the future ML model (Path A) or heuristic (Path B) will implement.

- [ ] **Step 1: Write the failing test**

Write `app/BruxaWatchTests/EpisodeDetectorTests.swift`:

```swift
import XCTest
import BruxaCore
@testable import BruxaWatch

final class EpisodeDetectorTests: XCTestCase {
    func test_stubDetectorAlwaysReturnsNil() {
        let detector = StubEpisodeDetector()
        let window = [SensorSample](repeating: SensorSample(
            timestamp: .now, accelX: 0.1, accelY: 0.1, accelZ: 1.0,
            gyroX: 0.0, gyroY: 0.0, gyroZ: 0.0
        ), count: 1500)
        XCTAssertNil(detector.detect(window: window, windowStart: .now))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U. Expected: FAIL.

- [ ] **Step 3: Implement the protocol and stub**

Write `app/BruxaWatch/Detection/EpisodeDetector.swift`:

```swift
import Foundation
import BruxaCore

public protocol EpisodeDetector {
    /// Returns an Episode if the window contains a detected bruxism episode, otherwise nil.
    func detect(window: [SensorSample], windowStart: Date) -> Episode?
}

public struct StubEpisodeDetector: EpisodeDetector {
    public init() {}
    public func detect(window: [SensorSample], windowStart: Date) -> Episode? {
        return nil
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Detection/ app/BruxaWatchTests/
git commit -m "feat(watch): add EpisodeDetector protocol with stub implementation"
```

---

### Task 13: `SleepSessionManager` — wire sleep gating + recorder + detector

**Files:**
- Create: `app/BruxaWatch/Sleep/SleepSessionManager.swift`
- Create: `app/BruxaWatchTests/SleepSessionManagerTests.swift`

- [ ] **Step 1: Write the failing test**

Write `app/BruxaWatchTests/SleepSessionManagerTests.swift`:

```swift
import XCTest
import BruxaCore
@testable import BruxaWatch

final class SleepSessionManagerTests: XCTestCase {
    func test_recordingStartsOnAsleepAndStopsOnAwake() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let motion = ScriptedMotionProvider(samples: makeFakeSamples(count: 1500))
        let sleep = ScriptedSleepStateProvider()
        let manager = SleepSessionManager(
            sleep: sleep,
            recorderFactory: { SensorRecorder(motion: motion, windowSeconds: 30) },
            detector: AlwaysHitDetector(),
            storage: storage
        )

        manager.start()
        sleep.emit(.asleep)
        await motion.runUntilEmpty()
        sleep.emit(.awake)

        let episodes = try await storage.fetchAll()
        XCTAssertEqual(episodes.count, 1)
    }

    private func makeFakeSamples(count: Int) -> [SensorSample] {
        let base = Date(timeIntervalSince1970: 1_000)
        return (0..<count).map { i in
            SensorSample(
                timestamp: base.addingTimeInterval(Double(i) * 0.02),
                accelX: 0, accelY: 0, accelZ: 1, gyroX: 0, gyroY: 0, gyroZ: 0
            )
        }
    }
}

private struct AlwaysHitDetector: EpisodeDetector {
    func detect(window: [SensorSample], windowStart: Date) -> Episode? {
        Episode(
            id: UUID(),
            start: windowStart,
            end: windowStart.addingTimeInterval(30),
            intensity: 0.8,
            isCalibration: false
        )
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U. Expected: FAIL — `SleepSessionManager` not defined.

- [ ] **Step 3: Implement `SleepSessionManager`**

Write `app/BruxaWatch/Sleep/SleepSessionManager.swift`:

```swift
import Foundation
import BruxaCore

public final class SleepSessionManager {
    private let sleep: SleepStateProvider
    private let recorderFactory: () -> SensorRecorder
    private let detector: EpisodeDetector
    private let storage: BruxaStorage

    private var recorder: SensorRecorder?

    public init(
        sleep: SleepStateProvider,
        recorderFactory: @escaping () -> SensorRecorder,
        detector: EpisodeDetector,
        storage: BruxaStorage
    ) {
        self.sleep = sleep
        self.recorderFactory = recorderFactory
        self.detector = detector
        self.storage = storage
    }

    public func start() {
        sleep.start { [weak self] state in
            guard let self else { return }
            switch state {
            case .asleep: self.beginRecording()
            case .awake: self.endRecording()
            }
        }
    }

    public func stop() {
        sleep.stop()
        endRecording()
    }

    private func beginRecording() {
        guard recorder == nil else { return }
        let r = recorderFactory()
        r.start { [weak self] window in
            guard let self, let first = window.first else { return }
            if let episode = self.detector.detect(window: window, windowStart: first.timestamp) {
                Task { try? await self.storage.save([episode]) }
            }
        }
        recorder = r
    }

    private func endRecording() {
        recorder?.stop()
        recorder = nil
    }
}
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: pass. Note: the test uses `AlwaysHitDetector` instead of the production stub so that we can verify the persistence path actually fires; the stub-only path is covered indirectly by Task 12's test.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Sleep/ app/BruxaWatchTests/
git commit -m "feat(watch): add SleepSessionManager wiring sleep state, recorder, detector, storage"
```

---

### Task 14: `PilotCSVWriter` — debug-only raw sample export

**Files:**
- Create: `app/BruxaWatch/Pilot/PilotCSVWriter.swift`
- Create: `app/BruxaWatchTests/PilotCSVWriterTests.swift`

Compiled only under DEBUG. Writes raw 50 Hz samples to a CSV file in the app's Documents directory, one file per night, so they can be transferred to the iPhone and exported for use as ML pilot data.

- [ ] **Step 1: Write the failing test**

Write `app/BruxaWatchTests/PilotCSVWriterTests.swift`:

```swift
#if DEBUG
import XCTest
import BruxaCore
@testable import BruxaWatch

final class PilotCSVWriterTests: XCTestCase {
    func test_writesHeaderThenSamples() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("csv")
        let writer = try PilotCSVWriter(url: tmp)

        let sample = SensorSample(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            accelX: 0.1, accelY: -0.2, accelZ: 0.98,
            gyroX: 0.01, gyroY: 0.02, gyroZ: -0.03
        )
        try writer.append(sample)
        try writer.append(sample)
        try writer.close()

        let content = try String(contentsOf: tmp, encoding: .utf8)
        let lines = content.split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(String(lines[0]), SensorSample.csvHeader)
        XCTAssertEqual(String(lines[1]), sample.csvRow)
    }
}
#endif
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U. Expected: FAIL.

- [ ] **Step 3: Implement `PilotCSVWriter`**

Write `app/BruxaWatch/Pilot/PilotCSVWriter.swift`:

```swift
#if DEBUG
import Foundation
import BruxaCore

public final class PilotCSVWriter {
    public let url: URL
    private let handle: FileHandle

    public init(url: URL) throws {
        self.url = url
        FileManager.default.createFile(atPath: url.path, contents: nil)
        self.handle = try FileHandle(forWritingTo: url)
        let header = SensorSample.csvHeader + "\n"
        try handle.write(contentsOf: Data(header.utf8))
    }

    public func append(_ sample: SensorSample) throws {
        try handle.write(contentsOf: Data((sample.csvRow + "\n").utf8))
    }

    public func close() throws {
        try handle.close()
    }
}
#endif
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Pilot/ app/BruxaWatchTests/
git commit -m "feat(watch): add DEBUG-only PilotCSVWriter for raw sample export"
```

---

### Task 15: `WatchConnectivityCoordinator` (Watch side)

**Files:**
- Create: `app/BruxaWatch/Connectivity/WatchConnectivityCoordinator.swift`
- Create: `app/BruxaWatchTests/WatchConnectivityCoordinatorTests.swift`

`WCSession` is a singleton tied to the OS and not directly testable. We hide it behind a protocol so the queueing/serialization logic is covered by tests with a fake.

- [ ] **Step 1: Write the failing test**

Write `app/BruxaWatchTests/WatchConnectivityCoordinatorTests.swift`:

```swift
import XCTest
import BruxaCore
@testable import BruxaWatch

final class WatchConnectivityCoordinatorTests: XCTestCase {
    func test_sendsEpisodesAsEncodedBatch() throws {
        let session = FakeWCSession()
        let coord = WatchConnectivityCoordinator(session: session, deviceID: "watch-1")

        let episodes = [
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(10), intensity: 0.3, isCalibration: false)
        ]
        try coord.send(episodes: episodes)

        XCTAssertEqual(session.transferredData.count, 1)
        let decoded = try EpisodesBatch.decoded(from: session.transferredData.first!)
        XCTAssertEqual(decoded.deviceID, "watch-1")
        XCTAssertEqual(decoded.episodes, episodes)
    }

    func test_emptyBatchIsNotTransferred() throws {
        let session = FakeWCSession()
        let coord = WatchConnectivityCoordinator(session: session, deviceID: "watch-1")
        try coord.send(episodes: [])
        XCTAssertTrue(session.transferredData.isEmpty)
    }
}

private final class FakeWCSession: WCTransport {
    var transferredData: [Data] = []
    func transfer(_ data: Data) { transferredData.append(data) }
    var isReachable: Bool { true }
}
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U. Expected: FAIL.

- [ ] **Step 3: Implement the protocol, coordinator, and real WCSession adapter**

Write `app/BruxaWatch/Connectivity/WatchConnectivityCoordinator.swift`:

```swift
import Foundation
import BruxaCore
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public protocol WCTransport {
    var isReachable: Bool { get }
    func transfer(_ data: Data)
}

public final class WatchConnectivityCoordinator {
    private let session: WCTransport
    private let deviceID: String

    public init(session: WCTransport, deviceID: String) {
        self.session = session
        self.deviceID = deviceID
    }

    public func send(episodes: [Episode]) throws {
        guard !episodes.isEmpty else { return }
        let batch = EpisodesBatch(deviceID: deviceID, episodes: episodes)
        let data = try batch.encoded()
        session.transfer(data)
    }
}

#if canImport(WatchConnectivity)
public final class LiveWCTransport: NSObject, WCTransport, WCSessionDelegate {
    private let session: WCSession

    public override init() {
        self.session = .default
        super.init()
        session.delegate = self
        session.activate()
    }

    public var isReachable: Bool { session.isReachable }

    public func transfer(_ data: Data) {
        session.transferUserInfo(["batch": data])
    }

    // Required no-op delegate methods
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
#endif
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaWatch/Connectivity/ app/BruxaWatchTests/
git commit -m "feat(watch): add WatchConnectivityCoordinator with WCTransport protocol"
```

---

### Task 16: `PhoneConnectivityCoordinator` (iOS side)

**Files:**
- Create: `app/BruxaApp/Connectivity/PhoneConnectivityCoordinator.swift`
- Create: `app/BruxaAppTests/PhoneConnectivityCoordinatorTests.swift`

- [ ] **Step 1: Write the failing test**

Write `app/BruxaAppTests/PhoneConnectivityCoordinatorTests.swift`:

```swift
import XCTest
import BruxaCore
@testable import BruxaApp

final class PhoneConnectivityCoordinatorTests: XCTestCase {
    func test_receivedBatchIsPersistedToStorage() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let coord = PhoneConnectivityCoordinator(storage: storage)

        let episodes = [
            Episode(id: UUID(), start: .now, end: .now.addingTimeInterval(10), intensity: 0.4, isCalibration: false)
        ]
        let batch = EpisodesBatch(deviceID: "watch-1", episodes: episodes)
        let data = try batch.encoded()

        try await coord.handleIncoming(userInfo: ["batch": data])

        let fetched = try await storage.fetchAll()
        XCTAssertEqual(fetched, episodes)
    }

    func test_malformedPayloadIsIgnored() async throws {
        let storage = try BruxaStorage(inMemory: true)
        let coord = PhoneConnectivityCoordinator(storage: storage)
        // missing "batch" key
        try await coord.handleIncoming(userInfo: ["wrong": Data()])
        let fetched = try await storage.fetchAll()
        XCTAssertEqual(fetched, [])
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

⌘U with the `BruxaApp` scheme. Expected: FAIL.

- [ ] **Step 3: Implement the coordinator**

Write `app/BruxaApp/Connectivity/PhoneConnectivityCoordinator.swift`:

```swift
import Foundation
import BruxaCore
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public final class PhoneConnectivityCoordinator {
    private let storage: BruxaStorage

    public init(storage: BruxaStorage) {
        self.storage = storage
    }

    public func handleIncoming(userInfo: [String: Any]) async throws {
        guard let data = userInfo["batch"] as? Data else { return }
        let batch = try EpisodesBatch.decoded(from: data)
        try await storage.save(batch.episodes)
    }
}

#if canImport(WatchConnectivity) && os(iOS)
public final class LiveWCReceiver: NSObject, WCSessionDelegate {
    private let coordinator: PhoneConnectivityCoordinator
    private let session: WCSession

    public init(coordinator: PhoneConnectivityCoordinator) {
        self.coordinator = coordinator
        self.session = .default
        super.init()
        session.delegate = self
        session.activate()
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { try? await coordinator.handleIncoming(userInfo: userInfo) }
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
#endif
```

- [ ] **Step 4: Run the test to verify it passes**

⌘U. Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/BruxaApp/Connectivity/ app/BruxaAppTests/
git commit -m "feat(ios): add PhoneConnectivityCoordinator persisting incoming batches"
```

---

### Task 17: `SleepAuthorizationCoordinator` and HealthKit permission flow (iOS)

**Files:**
- Create: `app/BruxaApp/HealthKit/SleepAuthorizationCoordinator.swift`
- Create: `app/BruxaAppTests/SleepAuthorizationCoordinatorTests.swift`
- Modify: `app/BruxaApp/Info.plist` (add `NSHealthShareUsageDescription`)

- [ ] **Step 1: Add the Info.plist usage description**

In Xcode: target `BruxaApp` → Info tab → add row:

- Key: `NSHealthShareUsageDescription`
- Value: `Bruxa reads your sleep data to time motion recording to the night.`

Also enable HealthKit capability: target → Signing & Capabilities → + Capability → HealthKit.

Same for `BruxaWatch` target.

- [ ] **Step 2: Write the failing test**

Write `app/BruxaAppTests/SleepAuthorizationCoordinatorTests.swift`:

```swift
import XCTest
@testable import BruxaApp

final class SleepAuthorizationCoordinatorTests: XCTestCase {
    func test_requestForwardsToAuthorizer() async throws {
        let authorizer = MockHealthAuthorizer()
        let coord = SleepAuthorizationCoordinator(authorizer: authorizer)
        try await coord.requestSleepReadAccess()
        XCTAssertEqual(authorizer.readTypeIdentifiers, ["HKCategoryTypeIdentifierSleepAnalysis"])
    }
}

private final class MockHealthAuthorizer: HealthAuthorizing {
    var readTypeIdentifiers: [String] = []
    func requestAuthorization(readIdentifiers: [String]) async throws {
        readTypeIdentifiers = readIdentifiers
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

⌘U. Expected: FAIL.

- [ ] **Step 4: Implement coordinator and HealthKit adapter**

Write `app/BruxaApp/HealthKit/SleepAuthorizationCoordinator.swift`:

```swift
import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

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

#if canImport(HealthKit)
public final class LiveHealthAuthorizer: HealthAuthorizing {
    private let store = HKHealthStore()
    public init() {}
    public func requestAuthorization(readIdentifiers: [String]) async throws {
        let types: Set<HKObjectType> = Set(readIdentifiers.compactMap {
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: $0))
        })
        try await store.requestAuthorization(toShare: [], read: types)
    }
}
#endif
```

- [ ] **Step 5: Run the test to verify it passes**

⌘U. Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add app/BruxaApp/HealthKit/ app/BruxaAppTests/ app/BruxaApp/Info.plist
git commit -m "feat(ios): add SleepAuthorizationCoordinator and HealthKit entitlement"
```

---

### Task 18: Wire up iOS app entry point (`RootView`)

**Files:**
- Modify: `app/BruxaApp/BruxaAppApp.swift` (Xcode-generated; rename as needed)
- Create: `app/BruxaApp/UI/RootView.swift`

This is a SwiftUI-only task with no logic tests (it's pure composition). Manual verification in the simulator suffices.

- [ ] **Step 1: Write `RootView`**

Write `app/BruxaApp/UI/RootView.swift`:

```swift
import SwiftUI
import BruxaCore

struct RootView: View {
    @State private var episodeCount: Int = 0
    @State private var lastError: String?
    private let storage: BruxaStorage

    init(storage: BruxaStorage) {
        self.storage = storage
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    LabeledContent("Recorded episodes", value: "\(episodeCount)")
                }
                Section("Onboarding") {
                    Button("Grant sleep access") { Task { await requestAccess() } }
                    Text("Open the Bruxa app on your Apple Watch and wear it overnight.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let lastError {
                    Section { Text(lastError).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Bruxa")
            .task { await refresh() }
            .refreshable { await refresh() }
        }
    }

    private func refresh() async {
        do {
            episodeCount = try await storage.fetchAll().count
        } catch {
            lastError = "Failed to fetch: \(error.localizedDescription)"
        }
    }

    private func requestAccess() async {
        let coord = SleepAuthorizationCoordinator(authorizer: LiveHealthAuthorizer())
        do { try await coord.requestSleepReadAccess() }
        catch { lastError = "Authorization failed: \(error.localizedDescription)" }
    }
}
```

- [ ] **Step 2: Wire `BruxaAppApp.swift` to use `RootView`**

Open the Xcode-generated `app/BruxaApp/BruxaAppApp.swift` and replace its contents with:

```swift
import SwiftUI
import BruxaCore

@main
struct BruxaAppApp: App {
    private let storage: BruxaStorage = {
        do { return try BruxaStorage() }
        catch { fatalError("Storage init failed: \(error)") }
    }()

    private let receiver: LiveWCReceiver

    init() {
        let coord = PhoneConnectivityCoordinator(storage: storage)
        self.receiver = LiveWCReceiver(coordinator: coord)
    }

    var body: some Scene {
        WindowGroup { RootView(storage: storage) }
    }
}
```

- [ ] **Step 3: Build and run on the iPhone simulator**

⌘R with the `BruxaApp` scheme. Expected:
- App launches showing "Recorded episodes: 0"
- Tapping "Grant sleep access" shows the HealthKit permission sheet

- [ ] **Step 4: Commit**

```bash
git add app/BruxaApp/
git commit -m "feat(ios): wire RootView with storage, connectivity receiver, auth flow"
```

---

### Task 19: Wire up watchOS app entry point (`StatusView`)

**Files:**
- Modify: `app/BruxaWatch/BruxaWatchApp.swift` (Xcode-generated)
- Create: `app/BruxaWatch/UI/StatusView.swift`

- [ ] **Step 1: Write `StatusView`**

Write `app/BruxaWatch/UI/StatusView.swift`:

```swift
import SwiftUI
import BruxaCore

struct StatusView: View {
    @State private var todayCount: Int = 0
    @State private var isRecording: Bool = false
    private let storage: BruxaStorage

    init(storage: BruxaStorage) { self.storage = storage }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isRecording ? "Recording" : "Idle")
                .font(.headline)
                .foregroundStyle(isRecording ? .green : .secondary)
            Text("Episodes tonight: \(todayCount)")
                .font(.subheadline)
            Spacer()
            Text("Open the iPhone app for reports.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task { await refresh() }
    }

    private func refresh() async {
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfDay(for: now.addingTimeInterval(-12 * 3600))
        let end = now
        do {
            let eps = try await storage.fetch(from: start, to: end)
            todayCount = eps.count
        } catch {
            todayCount = 0
        }
    }
}
```

- [ ] **Step 2: Wire `BruxaWatchApp.swift`**

Open the Xcode-generated `app/BruxaWatch/BruxaWatchApp.swift` and replace its contents with:

```swift
import SwiftUI
import BruxaCore

@main
struct BruxaWatchApp: App {
    private let storage: BruxaStorage = {
        do { return try BruxaStorage() }
        catch { fatalError("Storage init failed: \(error)") }
    }()

    private let manager: SleepSessionManager
    private let connectivity: WatchConnectivityCoordinator

    init() {
        let transport = LiveWCTransport()
        self.connectivity = WatchConnectivityCoordinator(session: transport, deviceID: "watch-default")
        let storageRef = self.storage
        let connectivityRef = self.connectivity
        let motionFactory = { SensorRecorder(motion: CoreMotionProvider(sampleRateHz: 50), windowSeconds: 30) }
        self.manager = SleepSessionManager(
            sleep: HealthKitSleepStateProvider(),
            recorderFactory: motionFactory,
            detector: StubEpisodeDetector(),
            storage: storageRef
        )
        manager.start()
        // Schedule a daily flush at app launch: send all episodes since yesterday morning.
        Task {
            let from = Date().addingTimeInterval(-36 * 3600)
            let to = Date()
            if let episodes = try? await storageRef.fetch(from: from, to: to) {
                try? connectivityRef.send(episodes: episodes)
            }
        }
    }

    var body: some Scene {
        WindowGroup { StatusView(storage: storage) }
    }
}
```

- [ ] **Step 3: Build and run on the Watch simulator**

⌘R with the `BruxaWatch` scheme. Expected: `StatusView` appears showing "Idle" and "Episodes tonight: 0". HealthKit will request authorization on first launch.

- [ ] **Step 4: Commit**

```bash
git add app/BruxaWatch/
git commit -m "feat(watch): wire StatusView, SleepSessionManager, and connectivity"
```

---

### Task 20: End-to-end manual smoke checklist

This task has no code — it's a runbook for the developer to verify the foundation works on physical hardware before moving on.

**Files:**
- Create: `app/SMOKE_TEST.md`

- [ ] **Step 1: Write the smoke test runbook**

Write `app/SMOKE_TEST.md`:

```markdown
# Foundation smoke test

Run this once on a paired iPhone + Apple Watch before declaring the foundation plan complete.

## Setup
1. Install BruxaApp on the iPhone (Series 6 or newer Watch paired, watchOS 10+).
2. Install BruxaWatch on the Apple Watch.
3. Open BruxaApp → tap "Grant sleep access" → approve in the HealthKit sheet.
4. Open BruxaWatch → confirm the StatusView shows "Idle".

## Overnight dogfood
1. Make sure iOS Sleep is configured (Health → Browse → Sleep → Schedule).
2. Wear the Watch to bed.
3. In the morning:
   - BruxaWatch StatusView still shows "Idle" or "Recording" (it should be Idle after wake).
   - Open BruxaApp on the iPhone, pull to refresh. The "Recorded episodes" count should be 0 (the detector is the stub — this is expected).

## What this verifies
- HealthKit permission flow works on device.
- WatchConnectivity session activates and the daily flush executes without crashing.
- CoreMotion does not crash the app overnight.
- CoreData store is created on both sides without migration errors.

## What this does NOT verify (yet)
- Episode detection accuracy (detector is a stub — covered by future Detection plan).
- Battery usage (must be measured in a closed beta; baseline this run vs. a control night without the app).
- UI quality for reports (covered by future Reporting plan).
```

- [ ] **Step 2: Commit**

```bash
git add app/SMOKE_TEST.md
git commit -m "docs: add foundation smoke test runbook"
```

---

## Decision Gate (before next plan)

Before starting any subsequent plan, the following must be resolved:

1. **Literature review** (Task #9 in the brainstorming task list) — investigate:
   - Public bruxism EMG/PSG datasets (PhysioNet, Mendeley Data, Zenodo).
   - Published correlations between wrist accelerometry and masseter EMG during sleep.
   - Prior wrist-based bruxism detection ML work (BruxNet, ZMaster, etc.).

2. **Path decision** based on findings:
   - **Path A — EMG-splint pilot:** acquire reference hardware, collect 14+ nights of paired data, train CoreML model offline. Next plan: `YYYY-MM-DD-path-a-pilot-and-training.md`.
   - **Path B — Heuristic MVP with bootstrap:** ship a band-pass + threshold heuristic in the next plan, add opt-in user feedback for label collection, train ML model in a later plan once data accumulates. Next plan: `YYYY-MM-DD-path-b-heuristic-detector.md`.

3. **Re-confirm MVP scope** with stakeholders if Path B is chosen, since accuracy claims must be downgraded ("good not perfect") in marketing copy.

After this resolution, the next plan can be written. Subsequent plans likely to follow (regardless of A or B):

- Reporting UI (iPhone charts, timeline, trend graphs)
- Onboarding & 3-night calibration flow
- Monetization (StoreKit subscription + trial)
