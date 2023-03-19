import Foundation
import Logging
import Shell

struct LibOpenSSLBuild: BuildItemForAndroidArch {

    var repo: Checkoutable { Repos.openSSL }

    let arch: AndroidArch

    init(arch: AndroidArch) {
        self.arch = arch
    }

    // MARK: BuildableItem

    func buildSteps() -> [BuildStep] {
        [
            BuildLibOpenSSLStep(openSSL: self),
            MakeStep(buildableItem: self, makeArgs: ["SHLIB_VERSION_NUMBER=", "SHLIB_EXT=.so"]),
            MakeInstallStep(buildableItem: self, makeArgs: ["SHLIB_VERSION_NUMBER=", "SHLIB_EXT=.so", "install_sw", "install_ssldirs"]),
        ]
    }
}
private final class BuildLibOpenSSLStep: BuildStep {

    init(openSSL: LibOpenSSLBuild) {
        self.openSSL = openSSL
    }

    // MARK: BuildStep

    var stepName: String { "configure-\(openSSL.name)" }

    func shouldBeExecuted(_ completedSteps: [String]) -> Bool {
        let makeStepName = "make-\(openSSL.name)"
        return completedSteps.contains(makeStepName) == false
    }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Configure OpenSSL \(openSSL.arch.name)", initialState: .configure)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let openSSL: LibOpenSSLBuild
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let sourceLocation = openSSL.sourceLocation(using: config)
        let buildFolderUrl = config.buildLocation(for: openSSL)
        let installFolderUrl = config.installLocation(for: openSSL)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)
        try fileManager.createFolderIfNotExists(at: installFolderUrl)

        let exports: [String] = [
            "ANDROID_NDK=\(config.ndkPath)",
            "PATH=\(config.ndkToolchain)/bin:$PATH"
        ]

        let configureArguments: [String] = [
            "-D__ANDROID_API__=\(config.androidApiLevel)",
            "--prefix=\(installFolderUrl.path)",
            openSSL.arch.androidRch,
        ]

        let configureUrl = sourceLocation.appendingPathComponent("Configure", isDirectory: false)

        let configureScript = ShellCommand(exports + [configureUrl.path] + configureArguments,
                                           currentDirectoryURL: buildFolderUrl,
                                           logger: logger)
        try await configureScript.execute()
    }
}

private extension AndroidArch {
    var androidRch: String {
        switch self {
        case AndroidArchs.arm64:
            return "android-arm64"
        case AndroidArchs.arm7:
            return "android-arm"
        case AndroidArchs.x86:
            return "android-x86"
        case AndroidArchs.x86_64:
            return "android-x86_64"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }
}
