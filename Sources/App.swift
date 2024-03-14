import Foundation
import Vision

@main
struct Main {
    static func main() async throws {
        try await performWork()
    }
}

func performWork() async throws {
    let imageURL = findResourceInBundle("church-of-the-king-j9jZSqfH5YI-unsplash.jpg")!
    try await withThrowingTaskGroup(of: (id: Int, faceCount: Int).self) { group in
        // This deadlocks when the number of child tasks is larger than the
        // number of CPU cores on your machine. Try using a smaller range.
        for i in 1...25 {
            group.addTask {
                print("Task \(i) starting")
                let request = VNDetectFaceRectanglesRequest()
                let requestHandler = VNImageRequestHandler(url: imageURL)
                try requestHandler.perform([request])
                let faces = request.results ?? []
                return (id: i, faceCount: faces.count)
            }
        }
        for try await (id, faceCount) in group {
            print("Task \(id) detected \(faceCount) faces")
        }
    }
}

/// Alternative implementation that "fixes" the deadlock
/// until you create so many child tasks that you exhaust the GCD limit.
func performWorkUsingGCD() async throws {
    let imageURL = findResourceInBundle("church-of-the-king-j9jZSqfH5YI-unsplash.jpg")!
    try await withThrowingTaskGroup(of: (id: Int, faceCount: Int).self) { group in
        // This "fixes" the deadlock at the cost of thread explosion.
        // Also, GCD's max thread pool size is 64, so if you increase to 64 or
        // more child tasks it will deadlock again.
        for i in 1...64 {
            group.addTask {
                print("Task \(i) starting")
                return try await withUnsafeThrowingContinuation { c in
                    DispatchQueue.global().async {
                        do {
                            let request = VNDetectFaceRectanglesRequest()
                            let requestHandler = VNImageRequestHandler(url: imageURL)
                            try requestHandler.perform([request])
                            let faces = request.results ?? []
                            c.resume(returning: (id: i, faceCount: faces.count))
                        } catch {
                            c.resume(throwing: error)
                        }
                    }
                }
            }
        }
        for try await (id, faceCount) in group {
            print("Task \(id) detected \(faceCount) faces")
        }
    }
}

func findResourceInBundle(_ filename: String) -> URL? {
    // The Bundle.module bundle has a different structure, depending on whether
    // you build the program with SwiftPM (`swift build`) or with Xcode.
    // Try to account for both structures.
    if let fileURL = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Resources") {
        return fileURL
    } else {
        let fileURL = Bundle.module.bundleURL
            .appending(
                components: "Contents", "Resources", "Resources", filename,
                directoryHint: .notDirectory
            )
        if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
            return fileURL
        } else {
            return nil
        }
    }
}
