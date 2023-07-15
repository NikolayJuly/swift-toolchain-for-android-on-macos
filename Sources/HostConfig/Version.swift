import Foundation
import FoundationExtension

/// Version, were all elements are integers, might contain build, if it is integer
struct Version: Comparable, Equatable {

    let major: Int
    let minor: Int
    let patch: Int

    let versionString: String

    /// 3-4 digits, separated by '.'
    init(_ version: String) throws {
        let numberStrings = version.components(separatedBy: ".").prefix(3)
        var numbers = [Int]()

        for numberString in numberStrings {
            guard let number = Int(numberString) else {
                throw SimpleError("Failed to parse int from \(numberString)")
            }

            numbers.append(number)
        }

        self.major = numbers[0]
        self.minor = numbers.count > 1 ? numbers[1] : 0
        self.patch = numbers.count > 2 ? numbers[2] : 0

        self.versionString = version
    }

    static func < (lhs: Version, rhs: Version) -> Bool {
        let lhsNumbers = lhs.numbers
        let rhsNumbers = rhs.numbers

        for i in 0..<3 {
            if lhsNumbers[i] == rhsNumbers[i] {
                continue
            }

            return lhsNumbers[i] < rhsNumbers[i]
        }
        return true
    }

    // MARK: Private

    private var numbers: [Int] { [major, minor, patch] }

}
