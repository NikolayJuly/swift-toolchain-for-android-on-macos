import Foundation
import Logging
import Shell

struct LibXml2Build: BuildItemForAndroidArch {

    var repo: Checkoutable { Repos.libXML2 }

    let arch: AndroidArch

    init(arch: AndroidArch) {
        self.arch = arch
    }

    // MARK: BuildableItem

    func buildSteps() -> [BuildStep] {
        [
            BuildLibXml2Step(libXml2: self),
            MakeStep(buildableItem: self),
            InstallLibXmlStep(libXml2: self)
        ]
    }
}

private final class BuildLibXml2Step: BuildStep {

    init(libXml2: LibXml2Build) {
        self.libXml2 = libXml2
    }

    // MARK: BuildStep

    var stepName: String { "configure-\(libXml2.name)" }

    func shouldBeExecuted(_ completedSteps: [String]) -> Bool {
        let makeStepName = "make-\(libXml2.name)"
        return completedSteps.contains(makeStepName) == false
    }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Configure LibXml2 \(libXml2.arch.name)", initialState: .configure)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let libXml2: LibXml2Build
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let sourceLocation = libXml2.sourceLocation(using: config)

        let buildFolderUrl = config.buildLocation(for: libXml2)
        let installFolderUrl = config.installLocation(for: libXml2)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)
        try fileManager.createFolderIfNotExists(at: installFolderUrl)

        let exports1: [String] = AutoconfSettings.compilerAndHostExports(config: config, arch: libXml2.arch)

        let autogenArguments: [String] = [
            "--host=\(libXml2.arch.cHost)",
        ]


        let autogenUrl = sourceLocation.appendingPathComponent("autogen.sh", isDirectory: false)

        // TODO: Add requirement for autoconf
        //       `$ brew install autoconf automake libtool`
        let autogenCommand = ShellCommand(exports1 + [autogenUrl.path] + autogenArguments,
                                          currentDirectoryURL: buildFolderUrl,
                                          logger: logger)
        try await autogenCommand.execute()

        let exports2: [String] = AutoconfSettings.clangFlags(arch: libXml2.arch)

        // Actual list of arguments can be found in `swift-corelibs-foundation/build-android`
        let configureArguments: [String] = [
            "--with-sysroot=\(config.ndkToolchain)/sysroot",
            "--with-zlib=\(config.ndkToolchain)/sysroot/usr",
            "--prefix=\(installFolderUrl.path)",
            "--without-lzma",
            "--disable-static",
            "--enable-shared",
            "--without-http",
            " --without-html",
            "--without-ftp",
            "--without-python",
            "--host=\(libXml2.arch.cHost)",
        ]

        let configureUrl = sourceLocation.appendingPathComponent("configure", isDirectory: false)

        let configureScript = ShellCommand(exports1 + exports2 + [configureUrl.path] + configureArguments,
                                           currentDirectoryURL: buildFolderUrl,
                                           logger: logger)
        try await configureScript.execute()
    }
}

private final class InstallLibXmlStep: BuildStep {
    var stepName: String { "install-\(libXml2.name)" }

    init(libXml2: LibXml2Build) {
        self.libXml2 = libXml2
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Install \(libXml2.name)", initialState: .install)

        let buildFolderUrl = config.buildLocation(for: libXml2)

        // This `install-libLTLIBRARIES` config was taken from `swift-corelibs-foundation/build-android`, or
        let installLib = ShellCommand(["make install-libLTLIBRARIES"],
                                   currentDirectoryURL: buildFolderUrl,
                                   logger: logger)
        try await installLib.execute()

        let includeFolderUrl = buildFolderUrl.appendingPathComponent("include", isDirectory: true)
        let installinclude = ShellCommand(["make install"],
                                          currentDirectoryURL: includeFolderUrl,
                                          logger: logger)
        try await installinclude.execute()

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let libXml2: LibXml2Build
}
