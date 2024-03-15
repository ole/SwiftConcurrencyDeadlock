import Foundation
import Vision

@main
struct Main {
    static func main() async throws {
        // Pick one of these variants:
        try await performWork()
//        try await performWorkWithUnboundedThreadExplosion()
//        try await performWorkUsingGCD(maxConcurrency: 5)
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
func performWorkWithUnboundedThreadExplosion() async throws {
    let imageURL = findResourceInBundle("church-of-the-king-j9jZSqfH5YI-unsplash.jpg")!
    try await withThrowingTaskGroup(of: (id: Int, faceCount: Int).self) { group in
        // This "fixes" the deadlock at the cost of thread explosion.
        // Also, GCD's max thread pool size is 64, so if you increase to 64 or
        // more child tasks it will deadlock again.
        for i in 1...64 {
            group.addTask {
                print("Task \(i) starting")
                return try await withCheckedThrowingContinuation { c in
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

/// Alternative implementation that fixes the deadlock.
///
/// Based on:
///
/// - Gwendal Roué’s reply on the Swift forums: https://forums.swift.org/t/cooperative-pool-deadlock-when-calling-into-an-opaque-subsystem/70685/3
/// - Souroush Khanlou, The GCD handbook: https://khanlou.com/2016/04/the-GCD-handbook/
/// - Mike Rhodes, Limiting concurrent execution using GCD: https://web.archive.org/web/20160613023817/https://dx13.co.uk/articles/2016/6/4/limiting-concurrent-execution-using-gcd.html
func performWorkUsingGCD(maxConcurrency: Int) async throws {
    let imageURL = findResourceInBundle("church-of-the-king-j9jZSqfH5YI-unsplash.jpg")!
    try await withThrowingTaskGroup(of: (id: Int, faceCount: Int).self) { group in
        let semaphore = DispatchSemaphore(value: maxConcurrency)
        let semaphoreWaitQueue = DispatchQueue(label: "maxConcurrency control")
        for i in 1...100 {
            group.addTask {
                print("Task \(i) starting")
                return try await withCheckedThrowingContinuation { c in
                    semaphoreWaitQueue.async {
                        semaphore.wait()
                        DispatchQueue.global().async {
                            defer {
                                semaphore.signal()
                            }
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
