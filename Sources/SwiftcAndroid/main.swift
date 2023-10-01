import AndroidConfig
import Foundation
import FoundationExtension
import Logging
import Shell

let exeutablePath = CommandLine.arguments[0]
let exeutavleFileUrl = URL(filePath: exeutablePath, directoryHint: .notDirectory)
let binFolderUrl = exeutavleFileUrl.deletingLastPathComponent()
let swiftcUrl = binFolderUrl.appending(path: "swiftc", directoryHint: .notDirectory)

let fileManager = FileManager.default
guard fileManager.fileExists(at: swiftcUrl) else {
    throw SimpleError("Failed to find swiftc at \(swiftcUrl.path(percentEncoded: false))")
}

let currentDirectoryURL = URL(filePath: fileManager.currentDirectoryPath, directoryHint: .isDirectory)

// Apart from call to compile, we might get couple extra calls
// Lets move this away from our path
let isArbitraryCall = CommandLine.argc == 2

// Right now I found one more extra case `-modulewrap`. This is not compile operation.
// I will do a trick here - if I can't see `.swift` in arguments, mean this is not a compile command, and I will not add anything
// FIXME: I start thinking that this executable should not exist at all, we should be able to pass all needed parameters with `-Xswiftc`
let isModuleWrap = CommandLine.arguments.dropFirst().contains("-modulewrap")

let shouldEnrichCall = !isModuleWrap && !isArbitraryCall

guard shouldEnrichCall else {

    let passedArguments = CommandLine.arguments.dropFirst()
    let silentLogger = Logger(label: "swiftc-android",
                              factory: { SwiftLogNoOpLogHandler($0) })

    let swiftcCommand = ExecuteBinaryCommand(swiftcUrl,
                                             Array(passedArguments),
                                             currentDirectoryURL: currentDirectoryURL,
                                             logger: silentLogger)
    let output = try await swiftcCommand.execute()
    // we need to reprint exact output
    print(output)
    exit(0)
}

// We assume that this call is to compile, so we will add extra parameters needed for android

let arguments = try Arguments()

var logger = Logger(label: "swiftc-android",
                    factory: { _ in PlainPrintLogger() })

logger.logLevel = arguments.isVerbose ? .debug : .error

let host = try Host()

// Folder which contains `usr` folder
let toolchainRootFolderUrl = binFolderUrl.deletingLastPathComponent().deletingLastPathComponent()
let toolchainRootFolderPath = toolchainRootFolderUrl.path(percentEncoded: false)

let adnroidApiArgument: [String]
let existeApiLevelParametr = CommandLine.arguments.dropFirst().first(where: { $0.contains("-D__ANDROID_API__") })
if existeApiLevelParametr != nil {
    adnroidApiArgument = []
} else {
    adnroidApiArgument = ["-Xcc", "-D__ANDROID_API__=\(String.androidApiLevel)"]
}

//let ndkToolchainPath = host.ndk.toolchainPath

let sysrootLibs = "\(host.ndk.sysrootLibPath)/\(arguments.target.ndkLibArchName)/\(String.androidApiLevel)"

let extraArguments: [String] = [
    "-tools-directory", "\(host.ndk.toolchainPath)/bin",
    "-Xclang-linker", "--sysroot=\(sysrootLibs)",
    "-Xclang-linker", "--gcc-toolchain=\(host.ndk.toolchainPath)",

    // Here is explanation, that we need -B with path passed to linker, so it will search for crtbegin + crtend
    // https://github.com/android/ndk/issues/1690#issuecomment-1529928723
    "-Xclang-linker", "-B",
    "-Xclang-linker", "\(sysrootLibs)",

    "-Xcc", "-I\(host.ndk.toolchain)",
    "-Xcc", "-I\(host.ndk.sysrootIncludePath)/\(arguments.target.ndkLibArchName)",
    "-L", "\(toolchainRootFolderPath)/usr/lib/swift/android/\(arguments.target.swiftArch)",
    "-L", "\(sysrootLibs)",
] + adnroidApiArgument

let newArguments = CommandLine.arguments.dropFirst() + extraArguments

let callSwiftC = ExecuteBinaryCommand(swiftcUrl, Array(newArguments), logger: logger)
try await callSwiftC.execute()
