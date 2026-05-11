#if DEBUG
import Foundation

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
