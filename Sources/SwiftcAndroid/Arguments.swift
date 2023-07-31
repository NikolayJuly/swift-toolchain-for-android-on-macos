import AndroidConfig
import Foundation
import FoundationExtension

extension String {
    // TODO: Add to documentation NDK_PATH env key
    static let ndkPathEnvKey = "NDK_PATH"
}

struct Arguments {
    let isVerbose: Bool
    let target: AndroidArch

    init() throws {
        let commandArguments = CommandLine.arguments.dropFirst()
        let targetKeyIndex = commandArguments.firstIndex(where: { $0 == "-target" })
        guard let targetKeyIndex else {
            throw SimpleError("Failed to find `-target` in command arguments: \(commandArguments.joined(separator: " "))")
        }

        let targetIndex = commandArguments.index(after: targetKeyIndex)

        guard commandArguments.endIndex > targetIndex else {
            throw SimpleError("Failed to find value for `-target` in command arguments: \(commandArguments.joined(separator: " "))")
        }

        let target = commandArguments[targetIndex]
        let androidArch = AndroidArchs.all.first(where: { $0.swiftTarget == target })

        guard let androidArch else {
            throw SimpleError("Unknown swift android target - \(target)")
        }

        self.target = androidArch

        self.isVerbose = commandArguments.contains("-v")
    }
}
