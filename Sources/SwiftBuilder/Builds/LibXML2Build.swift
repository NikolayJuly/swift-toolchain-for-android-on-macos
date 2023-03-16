import Foundation
import Logging
import Shell

struct LibXml2Build: BuildableItem {

    init(repo: LibXml2Repo,
         arch: AndroidArch) {
        self.repo = repo
        self.arch = arch
    }

    // Mark: BuildableItem

    var name: String { repo.repoName + "-" + arch.name }

    func sourceLocation(using buildConfig: BuildConfig) -> URL {
        buildConfig.location(for: repo)
    }

    func buildSteps() -> [BuildStep] {
        [
            BuildLibXml2Step(libXml2: self),
            MakeStep(buildableItem: self),
            InstallLibXmlStep(libXml2: self)
        ]
    }


    // MARK: Private

    fileprivate let repo: LibXml2Repo
    fileprivate let arch: AndroidArch
}

private final class BuildLibXml2Step: BuildStep {

    init(libXml2: LibXml2Build) {
        self.libXml2 = libXml2
    }

    // MARK: BuildStep

    var stepName: String { "configure-libXml2-\(libXml2.arch.name)" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Configure LibXml2 \(libXml2.arch.name)", initialState: .configure)

        let buildFolderUrl = config.buildLocation(for: libXml2)

        try fileManager.createFolderIfNotExists(at: buildFolderUrl)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let libXml2: LibXml2Build
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let sourceLocation = libXml2.sourceLocation(using: config)

        let exports1: [String] = [
            "CC='\(config.clangPath(for: libXml2.arch))'",
            "CXX='\(config.clangPpPath(for: libXml2.arch))'",
            "CHOST=\(libXml2.arch.cHost)",
        ]

        let autogenArguments: [String] = [
            "--host=\(libXml2.arch.cHost)",
        ]

        let buildFolderUrl = config.buildLocation(for: libXml2)
        let installFolderUrl = config.installLocation(for: libXml2)

        let autogenUrl = sourceLocation.appendingPathComponent("autogen.sh", isDirectory: false)

        // TODO: Add requirement for autoconf
        //       `$ brew install autoconf automake libtool`
        let autogenCommand = ShellCommand(exports1 + [autogenUrl.path] + autogenArguments,
                                          currentDirectoryURL: buildFolderUrl,
                                          logger: logger)
        try await autogenCommand.execute()

        let exports2: [String] = [
            "CFLAGS=' -Os -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing \(libXml2.arch.cFlag)'",
            "CXXFLAGS=' -Os -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -frtti -fexceptions -std=c++11 -Wno-error=unused-command-line-argument \(libXml2.arch.cFlag)'",
            "CPPFLAGS=` -Os -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing  \(libXml2.arch.cFlag)`",
            "CC='\(config.clangPath(for: libXml2.arch))'",
            "CXX='\(config.clangPpPath(for: libXml2.arch))'",
        ]

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
            "--host=\(libXml2.arch.cHost)",
        ]



        let configureUrl = sourceLocation.appendingPathComponent("configure", isDirectory: false)

        let configureScript = ShellCommand(exports1 + exports2 + [configureUrl.path] + configureArguments,
                                           currentDirectoryURL: buildFolderUrl,
                                           logger: logger)
        try await configureScript.execute()
    }
}

private extension AndroidArch {
    var cFlag: String {
        switch self {
        case AndroidArchs.arm64:
            return ""
        case AndroidArchs.arm7:
            return "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
        case AndroidArchs.x86:
            return "-march=i686 -mtune=intel -mssse3 -mfpmath=sse -m32"
        case AndroidArchs.x86_64:
            return "-march=x86-64"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }

    var cHost: String {
        switch self {
        case AndroidArchs.arm64:
            return "aarch64-linux-android"
        case AndroidArchs.arm7:
            return "arm-linux-androideabi"
        case AndroidArchs.x86:
            return "i686-linux-android"
        case AndroidArchs.x86_64:
            return "x86_64-linux-android"
        default:
            fatalError("Unsupported arch \(name)")
        }
    }
}

final class InstallLibXmlStep: BuildStep {
    var stepName: String { "Install-\(libXml2.name)" }

    init(libXml2: LibXml2Build) {
        self.libXml2 = libXml2
    }

    func execute(_ config: BuildConfig, logger: Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Install \(libXml2.name)", initialState: .make)

        let buildFolderUrl = config.buildLocation(for: libXml2)
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
