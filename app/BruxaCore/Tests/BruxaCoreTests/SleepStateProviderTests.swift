import XCTest
@testable import BruxaCore

final class SleepStateProviderTests: XCTestCase {
    func test_scriptedProviderEmitsScheduledStates() {
        let provider = ScriptedSleepStateProvider()
        var received: [SleepState] = []
        provider.start { state in received.append(state) }

        provider.emit(.asleep)
        provider.emit(.awake)
        provider.stop()

        XCTAssertEqual(received, [.asleep, .awake])
    }

    func test_stopPreventsFurtherEmissions() {
        let provider = ScriptedSleepStateProvider()
        var received: [SleepState] = []
        provider.start { state in received.append(state) }

        provider.stop()
        provider.emit(.asleep)

        XCTAssertEqual(received, [])
    }
}
