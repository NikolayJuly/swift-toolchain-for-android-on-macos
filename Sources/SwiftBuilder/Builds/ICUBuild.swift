import Foundation
import Logging
import Shell

struct ICUBuild: BuildableItem {

    let arch: AndroidArch

    init(arch: AndroidArch,
         repo: ICURepo,
         hostBuild: ICUHostBuild) {
        self.arch = arch
        self.repo = repo
        self.hostBuild = hostBuild
    }

    var name: String { "icu-\(arch.name)" } 

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    func buildSteps() -> [BuildStep] {
        [
            BuildIcuStep(icu: self),
            MakeStep(buildableItem: self),
            MakeInstallStep(buildableItem: self)
        ]
    }

    // MARK: Private

    fileprivate let repo: ICURepo
    fileprivate let hostBuild: ICUHostBuild
}

private final class BuildIcuStep: BuildStep {

    init(icu: ICUBuild) {
        self.icu = icu
    }

    // MARK: BuildStep

    var stepName: String { "configure-\(icu.name)" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Configure ICU \(icu.arch.name)", initialState: .configure)

        let buildFolderUrl = config.buildLocation(for: icu)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let icu: ICUBuild
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
}
