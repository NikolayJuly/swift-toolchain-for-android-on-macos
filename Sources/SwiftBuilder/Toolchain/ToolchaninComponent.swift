import Foundation
import Logging
import Shell

enum ToolchaninComponents {
    static let allComponents: [ToolchaninComponent] = {
        let builds = Builds.buildOrder.compactMap { $0 as? ToolchaninComponent }
        let libs: [BuildItemForAndroidArch] = AndroidArchs.all.flatMap { arch -> [BuildItemForAndroidArch] in
            let xml = LibXml2Build(arch: arch)
            let openSSL = LibOpenSSLBuild(arch: arch)
            let curl = LibCurlBuild(arch: arch, openSSL: openSSL)
            let icu = Builds.androidIcus.first { $0.arch == arch }!
            return [xml, openSSL, curl, icu]
        }

        let libsComponents = libs.map { ArchedLibToolchainComponent(buildItem: $0) }

        return builds + libsComponents
    }()
}

protocol ToolchaninComponent {
    /// - parameter url: usr folder in toolchain
    func copy(to url: URL, config: BuildConfig, logger: Logger) async throws
}

extension ToolchaninComponent where Self: BuildableItem {
    /// - parameter url: usr folder in toolchain
    func copy(to url: URL, config: BuildConfig, logger: Logger) async throws {
        logger.info("Copying files from install fodler of \(name)")

        let installFolder = config.installLocation(for: self)
        let ditto = ShellCommand("ditto", "-v", "--noacl", "--noqtn",
                                 installFolder.path, url.path,
                                 logger: logger)
        try await ditto.execute()
    }
}

extension SwiftBuild: ToolchaninComponent {}

extension SPMBuild: ToolchaninComponent {}

extension SwiftLLBuildBuild: ToolchaninComponent {}

extension SwiftToolsSupportCoreBuild: ToolchaninComponent {}

extension SwiftArgumentParserRepo: ToolchaninComponent {}

extension YamsRepo: ToolchaninComponent {}

extension SwiftDriverRepo: ToolchaninComponent {}

extension SwiftCryptoRepo: ToolchaninComponent {}

extension LibDispatchBuild: ToolchaninComponent {}

extension LibFoundationBuild: ToolchaninComponent {}

extension StdLibBuild: ToolchaninComponent {}

