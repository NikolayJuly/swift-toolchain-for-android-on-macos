import ConsoleKit
import Foundation

final class StepProgressReporter {

    enum State {
        case configure
        case build
        case make
        case install
        case create
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
        case .configure, .build, .make, .install, .create:
            status = state.gerund.consoleText(ConsoleStyle(color: .blue))
        case .done:
            status = "Done".consoleText(ConsoleStyle(color: .green)) +  " in \(timeMesurement.durationString).".consoleText(.plain)
        }

        terminal.output(stepNameText + status)
    }
}

private extension StepProgressReporter.State {
    var gerund: String {
        switch self {
        case .configure:
            return "Configuring..."
        case .build:
            return "Building..."
        case .make:
            return "Making..."
        case .install:
            return "Installing..."
        case .create:
            return "Creating..."
        case .done:
            fatalError()
        }
    }
}
