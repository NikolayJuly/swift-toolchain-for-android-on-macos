import Foundation
import Logging
import Shell

struct ICUHostBuild: BuildRepoItem {

    var repo: Checkoutable { Repos.icu }

    var name: String { "icu-host" }

    func buildSteps() -> [BuildStep] {
        [BuildHostIcuStep(icu: self), MakeStep(buildableItem: self)]
    }
}

private final class BuildHostIcuStep: BuildStep {
    init(icu: ICUHostBuild) {
        self.icu = icu
    }

    // MARK: BuildStep

    var stepName: String { "configure-\(icu.name)" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {
        let progressReporter = StepProgressReporter(step: "Configure ICU Host", initialState: .configure)

        let buildFolderUrl = config.buildLocation(for: icu)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let icu: ICUHostBuild
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {
        let buildFolderUrl = config.buildLocation(for: icu)

        let exports: [String] = [
            "CFLAGS='-Os'",
            "CXXFLAGS='--std=c++11'",
        ]

        let configureUrl = config.location(for: icu.repo).appendingPathComponent("icu4c", isDirectory: true)
                                                         .appendingPathComponent("source", isDirectory: true)
                                                         .appendingPathComponent("runConfigureICU", isDirectory: true)

        let arguments: [String] = [
            "MacOSX",
            "--prefix=/",
            "--enable-static",
            "--enable-shared=no",
            "--enable-extras=no",
            "--enable-strict=no",
            "--enable-icuio=no",
            "--enable-layout=no",
            "--enable-layoutex=no",
            "--enable-tests=no",
            "--enable-samples=no",
            "--enable-dyload=no",
        ]

        let commandComponents = exports + [configureUrl.path] + arguments

        let command = ShellCommand(commandComponents,
                                   currentDirectoryURL: buildFolderUrl,
                                   logger: logger)
        try await command.execute()
    }
}
