import Foundation

/// Class receives bytes of data, data must be utf8 representation of mutiline string
/// At the end, we need to call  `complete`, to decode last line, which might not end with "\n"
/// This implementation is attempt to repoduce usefull `AsyncBytes` from `URLSession` or `FileHandler`
final class AsyncBytesToLines: AsyncSequence {

    typealias Element = String

    struct AsyncIterator: AsyncIteratorProtocol {

        typealias Element = String

        init(_ asyncBytes: AsyncBytesToLines) {
            self.asyncBytes = asyncBytes
        }

        mutating func next() async -> String? {
            return await withCheckedContinuation { continuation in
                asyncBytes.lock.lock()
                defer { asyncBytes.lock.unlock() }
                if count < asyncBytes.lines.count {
                    defer { count += 1 }
                    continuation.resume(with: .success(asyncBytes.lines[count]))
                    return
                }

                guard asyncBytes.expectingBytes else {
                    continuation.resume(with: .success(nil))
                    return
                }

                let oldCounter = count
                count += 1

                asyncBytes.updateWaiters.append { [self] in
                    self.asyncBytes.lock.lock()
                    defer { self.asyncBytes.lock.unlock() }
                    if oldCounter < asyncBytes.lines.count {
                        continuation.resume(with: .success(asyncBytes.lines[oldCounter]))
                        return
                    }
                    guard asyncBytes.expectingBytes else {
                        continuation.resume(with: .success(nil))
                        return
                    }

                    fatalError("In this block we expect or new value or end of bytes")
                }
            }
        }

        private let asyncBytes: AsyncBytesToLines
        private var count = 0
    }

    func add(_ bytes: some Sequence<UInt8>) {

        let waiters: [UpdateWaiter]
        do {
            lock.lock()
            defer { lock.unlock() }
            guard expectingBytes else {
                fatalError("We do not expect more bytes")
            }
            notProcessedBytes.append(contentsOf: bytes)
            var didAddAtLeastOneLine = false
            while true {
                let `continue` = processCurrentBytes()
                guard `continue` else {
                    break
                }
                didAddAtLeastOneLine = true
            }

            if didAddAtLeastOneLine {
                waiters = self.updateWaiters
                self.updateWaiters.removeAll()
            } else {
                waiters = []
            }
        }

        waiters.forEach { $0() }
    }

    func complete() {
        lock.lock()
        expectingBytes = false
        let line = String(bytes: notProcessedBytes, encoding: .utf8)!
        notProcessedBytes.removeAll()
        let newLines = line.components(separatedBy: "\n")
        lines.append(contentsOf: newLines)
        let waiters: [UpdateWaiter] = self.updateWaiters
        self.updateWaiters.removeAll()
        lock.unlock()
        waiters.forEach { $0() }
    }

    // MARK: AsyncSequence

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(self)
    }

    // MARK: Private

    private typealias UpdateWaiter = () -> Void

    private let lock = NSLock()
    private var notProcessedBytes = [UInt8]()
    private var lines = [String]()
    private var expectingBytes = true

    private var updateWaiters = [UpdateWaiter]()

    /// - returns: true, if new line was generated
    private func processCurrentBytes() -> Bool {
        guard notProcessedBytes.count > 1 else {
            return false
        }

        let separatorBytes = "\n".data(using: .utf8)!

        precondition(separatorBytes.count == 1)

        let newLineByte = separatorBytes.first!

        let firstIndex = notProcessedBytes.firstIndex(of: newLineByte)

        guard let firstIndex else {
            return false
        }

        let lineBytes = notProcessedBytes.prefix(firstIndex)
        let line = String(bytes: lineBytes, encoding: .utf8)!

        let subSequence = notProcessedBytes.dropFirst(firstIndex + 1)
        notProcessedBytes = Array(subSequence)

        lines.append(line)
        return true
    }
}

