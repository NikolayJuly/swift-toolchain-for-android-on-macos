import ConsoleKit
import Foundation

final class StepProgressReporter {

    enum State {
        case configure
        case build
        case make
        case install
        case done
    }

    init(step: String, initialState: State) {
        self.step = step
        self.state = initialState
        printCurrentState()
    }

    func update(state: State) {
        self.state = state
        terminal.popEphemeral()
        printCurrentState()
    }

    // MARK: Private

    private let timeMesurement = TimeMesurement()
    private let terminal = Terminal()

    private let step: String
    private var state: State

    private func printCurrentState() {
        terminal.pushEphemeral()
        let stepNameText = "\(step): ".consoleText(.plain)
        let status: ConsoleText
        switch state {
        case .configure:
            status = "Configuring...".consoleText(ConsoleStyle(color: .blue))
        case .build:
            status = "Building...".consoleText(ConsoleStyle(color: .blue))
        case .make:
            status = "Making...".consoleText(ConsoleStyle(color: .blue))
        case .install:
            status = "Installing...".consoleText(ConsoleStyle(color: .blue))
        case .done:
            status = "Done".consoleText(ConsoleStyle(color: .green)) +  " in \(timeMesurement.durationString).".consoleText(.plain)
        }

        terminal.output(stepNameText + status)
    }
}
