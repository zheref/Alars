import ArgumentParser
import Foundation

/// Command for running a quick sequence of operations
struct QuickCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "quick",
        abstract: "Run a quick sequence of operations (e.g., 'alars quick cbtr ProjectName' runs clean, build, test, run)"
    )

    @Argument(help: "Sequence of operation letters (e.g., 'cbtr' for clean, build, test, run)")
    var sequence: String

    @Argument(help: "Project name to run operations on")
    var projectName: String

    func run() async throws {
        let projectService = ProjectService()
        let consoleView = ConsoleView()
        let operationController = OperationController()

        do {
            let projects = try projectService.loadProjects()

            guard let project = projects.first(where: { $0.name == projectName }) else {
                throw AlarsError.projectNotFound(projectName)
            }

            try projectService.validateProject(project)

            // Parse the sequence into operations
            var operations: [OperationType] = []
            for char in sequence.lowercased() {
                if let operation = OperationType(fromLetter: String(char)) {
                    operations.append(operation)
                } else {
                    consoleView.printWarning("Skipping invalid operation letter: '\(char)'")
                }
            }

            if operations.isEmpty {
                consoleView.printError("No valid operations found in sequence '\(sequence)'")
                consoleView.printInfo("Valid letters: c=clean, s=save, u=update, b=build, t=test, r=run, e=reset")
                throw ExitCode.failure
            }

            consoleView.printInfo("Running sequence: \(operations.map { $0.description }.joined(separator: " → "))")

            // Execute each operation in sequence
            for operation in operations {
                consoleView.printInfo("\n▶ Running: \(operation.description)")

                let result = try await operationController.executeOperation(operation, on: project)

                switch result {
                case .success(let message):
                    consoleView.printSuccess(message)
                case .failure(let error):
                    consoleView.printError("Failed: \(error.localizedDescription)")
                    consoleView.printError("Stopping sequence execution due to failure")
                    throw ExitCode.failure
                case .cancelled:
                    consoleView.printWarning("Operation cancelled")
                    consoleView.printWarning("Stopping sequence execution")
                    throw ExitCode.failure
                }
            }

            consoleView.printSuccess("\n✓ All operations completed successfully!")

        } catch {
            consoleView.printError(error.localizedDescription)
            throw ExitCode.failure
        }
    }
}
