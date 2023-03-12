import ConsoleKit
import Foundation
import Logging
import Shell

struct ICUHostBuild: BuildableItem {

    init(repo: ICURepo) {
        self.repo = repo
    }

    var name: String { "icu-host" }

    var underlyingRepo: BuildableItemRepo?

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    func buildSteps() -> [BuildStep] {
        [BuildHostIcuStep(icu: self)]
    }

    // MARK: Private

    fileprivate let repo: ICURepo
}

private final class BuildHostIcuStep: BuildStep {
    init(icu: ICUHostBuild) {
        self.icu = icu
    }

    // MARK: BuildStep

    var stepName: String { "build-icu-host" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {
        // FIXME: This code with status and mesurement used a lot, I think I need create struct for it
        let timeMesurement = TimeMesurement()
        terminal.pushEphemeral()
        let stepNameText = "Build ICU Host: ".consoleText(.plain)

        var status = "Configure...".consoleText(ConsoleStyle(color: .blue))
        terminal.output(stepNameText + status)

        let buildFolderUrl = config.buildLocation(for: icu)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)

        try await configure(config, logger: logger)

        terminal.popEphemeral()
        terminal.pushEphemeral()

        status = "Making...".consoleText(ConsoleStyle(color: .blue))
        terminal.output(stepNameText + status)

        try await make(config, logger: logger)

        terminal.popEphemeral()
        terminal.pushEphemeral()

        status = "Done".consoleText(ConsoleStyle(color: .green)) +  " in \(timeMesurement.durationString).".consoleText(.plain)
        terminal.output(stepNameText + status)
    }

    // MARK: Private

    private let icu: ICUHostBuild
    private let terminal = Terminal()
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

    private func make(_ config: BuildConfig, logger: Logging.Logger) async throws {
        let buildFolderUrl = config.buildLocation(for: icu)
        let command = ShellCommand(["make"],
                                   currentDirectoryURL: buildFolderUrl,
                                   logger: logger)
        try await command.execute()
    }
}
