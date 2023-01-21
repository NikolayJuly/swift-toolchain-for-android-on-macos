import Foundation

struct BuildProgress: Codable {
    let completedSteps: [String]

    /// Create `BuildProgress` with prev saved info. If no such file, create empty progress
    /// - Parameter folderUrl: URL of working folder
    init(withProgressIn folderUrl: URL) throws {
        let content = try FileManager.default.contentsOfDirectory(atPath: folderUrl.path)
        guard content.contains(.filename) else {
            self.init(completedSteps: [])
            return
        }

        let fileUrl = folderUrl.appendingPathComponent(.filename, isDirectory: false)

        let jsonFileData = try Data(contentsOf: fileUrl)
        let progress = try JSONDecoder().decode(BuildProgress.self, from: jsonFileData)
        self.init(completedSteps: progress.completedSteps)
    }

    /// Save json with name "current-preogress.json" in provided folder
    /// - Parameter folderUrl: working folder, where progress will be saved
    func save(to folderUrl: URL) throws {
        let fileUrl = folderUrl.appendingPathComponent(.filename, isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: fileUrl)
    }

    func updated(byAdding step: String) -> BuildProgress {
        BuildProgress(completedSteps: completedSteps + [step])
    }

    // MARK: Private

    private init(completedSteps: [String]) {
        self.completedSteps = completedSteps
    }
}

private extension String {
    static let filename = "current-progress.json"
}
