import ConsoleKit
import Foundation
import Logging
import Shell

struct ICUBuild: BuildableItem {

    init(arch: AndroidArch,
         repo: ICURepo,
         hostBuild: ICUHostBuild) {
        self.arch = arch
        self.repo = repo
        self.hostBuild = hostBuild
    }

    var name: String { "icu-\(arch.name)" } 

    var underlyingRepo: BuildableItemRepo?

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    func buildSteps() -> [BuildStep] {
        [BuildIcuStep(icu: self)]
    }

    // MARK: Private

    fileprivate let arch: AndroidArch
    fileprivate let repo: ICURepo
    fileprivate let hostBuild: ICUHostBuild
}

private final class BuildIcuStep: BuildStep {

    init(icu: ICUBuild) {
        self.icu = icu
    }

    // MARK: BuildStep

    var stepName: String { "build-icu-\(icu.arch.name)" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        // FIXME: This code with status and mesurement used a lot, I think I need create struct for it
        let timeMesurement = TimeMesurement()
        terminal.pushEphemeral()
        let stepNameText = "Build ICU \(icu.arch.name): ".consoleText(.plain)

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

    private let icu: ICUBuild
    private let terminal = Terminal()
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {
        let buildFolderUrl = config.buildLocation(for: icu)
        let hostBuildFolderUrl = config.buildLocation(for: icu.hostBuild)

        let exports: [String] = [
            "CFLAGS='-Os \(icu.arch.cFlag)'",
            "CXXFLAGS='--std=c++11 \(icu.arch.cFlag)'",
            "CC='\(config.clangPath(for: icu.arch))'",
            "CXX='\(config.clangPpPath(for: icu.arch))'",
        ]

        let configureUrl = config.location(for: icu.repo).appendingPathComponent("icu4c", isDirectory: true)
            .appendingPathComponent("source", isDirectory: true)
            .appendingPathComponent("configure", isDirectory: true)

        let arguments: [String] = [
            "--prefix=/",
            "--host=\(icu.arch.ndkLibArchName)",
            "--with-library-suffix=swift",
            "--enable-static=no",
            "--enable-shared",
            "--enable-extras=no",
            "--enable-strict=no",
            "--enable-icuio=no",
            "--enable-layout=no",
            "--enable-layoutex=no",
            "--enable-tests=no",
            "--enable-samples=no",
            "--enable-dyload=no",
            "--with-cross-build=\(hostBuildFolderUrl.path)",
            "--with-data-packaging=library",
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

private extension AndroidArch {
    var cFlag: String {
        switch self {
        case AndroidArchs.arm64:
            return ""
        case AndroidArchs.arm7:
            return "-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
        case AndroidArchs.x86:
            return "-march=i686 -mssse3 -mfpmath=sse -m32"
        case AndroidArchs.x86_64:
            return "-march=x86-64"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }

    var clangFilenamePrefix: String {
        switch self {
        case AndroidArchs.arm64:
            return "aarch64-linux-android"
        case AndroidArchs.arm7:
            return "armv7a-linux-androideabi"
        case AndroidArchs.x86:
            return "i686-linux-android"
        case AndroidArchs.x86_64:
            return "x86_64-linux-android"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }
}

private extension BuildConfig {
    func clangPath(for arch: AndroidArch) -> String {
        ndkToolchain + "/bin/\(arch.clangFilenamePrefix)\(androidApiLevel)-clang"
    }

    func clangPpPath(for arch: AndroidArch) -> String {
        ndkToolchain + "/bin/\(arch.clangFilenamePrefix)\(androidApiLevel)-clang++"
    }
}
