import Foundation
import Vision

@main
struct Main {
    static func main() async throws {
        try await performWork()
    }
}

func performWork() async throws {
    let imageURL = Bundle.module.bundleURL
        .appending(
            components: "Contents", "Resources", "Resources",
                "church-of-the-king-j9jZSqfH5YI-unsplash.jpg",
            directoryHint: .notDirectory
        )
    try await withThrowingTaskGroup(of: (id: Int, faceCount: Int).self) { group in
        for i in 1...50 {
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
