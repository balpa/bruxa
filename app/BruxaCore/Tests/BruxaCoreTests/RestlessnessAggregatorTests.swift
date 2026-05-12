import XCTest
@testable import BruxaCore

final class RestlessnessAggregatorTests: XCTestCase {
    func test_emptyInputProducesEmptyOutput() {
        let buckets = RestlessnessAggregator().aggregate(samples: [], bucketSeconds: 300)
        XCTAssertTrue(buckets.isEmpty)
    }

    func test_singleBucketComputesEnergyFromMagnitude() {
        // 10 samples within the same 5-min bucket; constant 1g downward acceleration → energy near 0 after gravity removal.
        let base = Date(timeIntervalSince1970: 0)
        let samples = (0..<10).map { i in
            SensorSample(timestamp: base.addingTimeInterval(Double(i) * 0.1),
                         accelX: 0, accelY: 0, accelZ: 9.81,
                         gyroX: 0, gyroY: 0, gyroZ: 0)
        }
        let buckets = RestlessnessAggregator().aggregate(samples: samples, bucketSeconds: 300)
        XCTAssertEqual(buckets.count, 1)
        XCTAssertEqual(buckets[0].start, base)
        XCTAssertEqual(buckets[0].energy, 0, accuracy: 0.001)
    }

    func test_higherMotionProducesHigherEnergy() {
        let base = Date(timeIntervalSince1970: 0)
        let calm = (0..<10).map { i in
            SensorSample(timestamp: base.addingTimeInterval(Double(i) * 0.1),
                         accelX: 0, accelY: 0, accelZ: 9.81,
                         gyroX: 0, gyroY: 0, gyroZ: 0)
        }
        let restless = (0..<10).map { i in
            SensorSample(timestamp: base.addingTimeInterval(Double(i) * 0.1),
                         accelX: Double(i % 2 == 0 ? 1 : -1) * 2,
                         accelY: 0, accelZ: 9.81,
                         gyroX: 0, gyroY: 0, gyroZ: 0)
        }
        let calmEnergy = RestlessnessAggregator().aggregate(samples: calm, bucketSeconds: 300)[0].energy
        let restlessEnergy = RestlessnessAggregator().aggregate(samples: restless, bucketSeconds: 300)[0].energy
        XCTAssertGreaterThan(restlessEnergy, calmEnergy)
    }

    func test_samplesAreGroupedByBucketGrid() {
        let base = Date(timeIntervalSince1970: 0)
        let earlySample = SensorSample(timestamp: base.addingTimeInterval(100), accelX: 0, accelY: 0, accelZ: 9.81, gyroX: 0, gyroY: 0, gyroZ: 0)
        let lateSample = SensorSample(timestamp: base.addingTimeInterval(400), accelX: 0, accelY: 0, accelZ: 9.81, gyroX: 0, gyroY: 0, gyroZ: 0)
        let buckets = RestlessnessAggregator().aggregate(samples: [earlySample, lateSample], bucketSeconds: 300)
        XCTAssertEqual(buckets.count, 2)
        XCTAssertEqual(buckets[0].start, base)
        XCTAssertEqual(buckets[1].start, base.addingTimeInterval(300))
    }
}
