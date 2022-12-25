import ArgumentParser
import Foundation
import Logging
import Shell

protocol BuildStep {
    func execute() async throws
}

@main
final class SwiftBuildCommand: AsyncParsableCommand {

    @Option(name: .long,
            help: "Folder which will contain all checkouts, logs and final artefacts",
            transform: { URL(fileURLWithPath: $0, isDirectory: true) })
    var workingFolder: URL

    func validate() throws {
        // I knowthat this function throw error, if failed to create needed folder
        try fileManager.createFolderIfNotExists(at: workingFolder)
    }

    func run() async throws {

        // TODO: Create needed logger

        let checkoutDestinationUrl = workingFolder.appendingPathComponent("spm", isDirectory: true)
        try? fileManager.removeItem(at: checkoutDestinationUrl)
        let gitRepoUrl = URL(string: "https://github.com/apple/servicetalk")!
        let gitClone = GitClone(source: gitRepoUrl, destination: checkoutDestinationUrl)
        try await gitClone.execute()
    }

    // MARK: Private

    private var fileManager: FileManager { FileManager.default }
}
