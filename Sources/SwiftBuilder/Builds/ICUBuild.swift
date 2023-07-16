import AndroidConfig
import Foundation
import FoundationExtension
import Logging
import Shell

struct ICUBuild: BuildItemForAndroidArch {

    let arch: AndroidArch

    var repo: Checkoutable { Repos.icu }

    init(arch: AndroidArch) {
        self.arch = arch
    }

    func buildSteps() -> [BuildStep] {
        [
            BuildIcuStep(icu: self),
            MakeStep(buildableItem: self),
            IcuInstallStep(icu: self)
        ]
    }

    // MARK: Private

    fileprivate var hostBuild: ICUHostBuild { Builds.hostIcu }
}

private final class BuildIcuStep: BuildStep {

    init(icu: ICUBuild) {
        self.icu = icu
    }

    // MARK: BuildStep

    var stepName: String { "configure-\(icu.name)" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Configure ICU \(icu.arch.name)", initialState: .configure)

        try await configure(config, logger: logger)

        progressReporter.update(state: .done)
    }

    // MARK: Private

    private let icu: ICUBuild
    private var fileManager: FileManager { FileManager.default }

    private func configure(_ config: BuildConfig, logger: Logging.Logger) async throws {
        let hostBuildFolderUrl = config.buildLocation(for: icu.hostBuild)

        let buildFolderUrl = config.buildLocation(for: icu)
        let installFolderUrl = config.installLocation(for: icu)
        try fileManager.createFolderIfNotExists(at: buildFolderUrl)
        try fileManager.createFolderIfNotExists(at: installFolderUrl)

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
            "--prefix=\(installFolderUrl.path)",
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

private final class IcuInstallStep: BuildStep {

    init(icu: BuildItemForAndroidArch) {
        self.icu = icu
    }

    var stepName: String { "install-\(icu.name)" }

    func execute(_ config: BuildConfig, logger: Logging.Logger) async throws {

        let progressReporter = StepProgressReporter(step: "Install ICU \(icu.arch.name)", initialState: .install)

        let defaultInstall = MakeInstallStep(buildableItem: icu)
        try await defaultInstall.execute(config, logger: logger)

        let installFodler = config.installLocation(for: icu)
        let installLibsFolder = installFodler.appendingPathComponent("lib", isDirectory: true)

        let libsFiles = try fileManager.categorizedFolderContent(at: installLibsFolder).files

        // Remove .so files, as they are symlinks
        // For now for each lib we have 3 files. For example, `libicudataswift.so`, `libicudataswift.so.65` and `libicudataswift.so.65.1`
        // We wanna remove .so and .so.65, and rename .so.65.1 to .so

        let toBeRenamedLibs = libsFiles.filter { $0.lastPathComponent.hasSuffix(".so.65.1") }
        guard toBeRenamedLibs.count == 5 else {
            throw SimpleError("Install step for \(icu.name) has unexpected number of libs \(toBeRenamedLibs.count).")
        }

        let toBeRemovedLibs = libsFiles.filter { toBeRenamedLibs.contains($0) == false }

        for toBeRemovedLib in toBeRemovedLibs {
            try fileManager.removeItem(at: toBeRemovedLib)
        }

        for lib in toBeRenamedLibs {
            // Shoortcut, assuming there is no `.` in libname itself
            let libName = lib.lastPathComponent.components(separatedBy: ".").first!

            let libFilename = libName + ".so"
            let destination = installLibsFolder.appending(path: libFilename, directoryHint: .notDirectory)
            try fileManager.moveItem(at: lib, to: destination)
        }

        progressReporter.update(state: .done)
    }


    // MARK: Private

    private let icu: BuildItemForAndroidArch
    private var fileManager: FileManager { FileManager.default }
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
