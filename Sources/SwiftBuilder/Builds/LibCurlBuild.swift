import AndroidConfig
import Foundation
import Logging
import Shell

struct LibCurlBuild: BuildItemForAndroidArch {

    let arch: AndroidArch
    var repo: Checkoutable { Repos.curl }

    init(arch: AndroidArch,
         openSSL: BuildableItem) {
        self.arch = arch
        self.openSSL = openSSL
    }

    // MARK: BuildableItem

    func buildSteps() -> [BuildStep] {
        [
            BuildLibCurlStep(curl: self),
            MakeStep(buildableItem: self),
            MakeInstallStep(buildableItem: self)
        ]
    }

    // MARK: Private

    fileprivate var openSSL: BuildableItem
}

private final class BuildLibCurlStep: BuildStep {

    init(curl: LibCurlBuild) {
        self.curl = curl
    }

    // MARK: BuildStep

    var stepName: String { "configure-\(curl.name)" }

    func shouldBeExecuted(_ completedSteps: [String]) -> Bool {
        let makeStepName = "make-\(curl.name)"
        return completedSteps.contains(makeStepName) == false
    }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Configure curl \(curl.arch.name)", initialState: .configure)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let curl: LibCurlBuild
    private var openSSL: BuildableItem { curl.openSSL }
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let sourceLocation = curl.sourceLocation(using: config)

        let exports1: [String] = AutoconfSettings.compilerAndHostExports(config: config, arch: curl.arch)

        let buildFolderUrl = config.buildLocation(for: curl)
        let installFolderUrl = config.installLocation(for: curl)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)
        try fileManager.createFolderIfNotExists(at: installFolderUrl)

        // TODO: Add requirement for autoconf
        //       `$ brew install autoconf automake libtool`
        let autogenCommand = ShellCommand(exports1 + ["autoreconf", "-fi"],
                                          currentDirectoryURL: sourceLocation,
                                          logger: logger)
        try await autogenCommand.execute()

        let exports2: [String] = AutoconfSettings.clangFlags(arch: curl.arch)

        // Actual list of arguments can be found in `swift-corelibs-foundation/build-android`

        let openSslInstallUrl = config.installLocation(for: openSSL)

        let configureArguments: [String] = [
            "--with-zlib=\(config.ndk.toolchainPath)/sysroot/usr",
            "--prefix=\(installFolderUrl.path)",
            "--enable-shared",
            "--disable-static",
            "--disable-dependency-tracking",
            "--without-ca-bundle",
            "--without-ca-path",
            "--enable-ipv6",
            "--enable-http",
            "--enable-ftp",
            "--disable-file",
            "--disable-ldap",
            "--disable-ldaps",
            "--disable-rtsp",
            "--disable-proxy",
            "--disable-dict",
            "--disable-telnet",
            "--disable-tftp",
            "--disable-pop3",
            "--disable-imap",
            "--disable-smtp",
            "--disable-gopher",
            "--disable-sspi",
            "--disable-manual",
            "--host=\(curl.arch.cHost)",
            "--with-ssl=\(openSslInstallUrl.path)"
        ]

        let configureUrl = sourceLocation.appendingPathComponent("configure", isDirectory: false)

        let configureScript = ShellCommand(exports1 + exports2 + [configureUrl.path] + configureArguments,
                                           currentDirectoryURL: buildFolderUrl,
                                           logger: logger)
        try await configureScript.execute()
    }
}
