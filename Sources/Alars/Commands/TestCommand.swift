import ArgumentParser
import Foundation

/// Command for running tests on a project directly
struct TestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run tests on a project directly"
    )

    @Argument(help: "Project name to test")
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

            let result = try await operationController.executeOperation(.test, on: project)

            switch result {
            case .success(let message):
                consoleView.printSuccess(message)
            case .failure(let error):
                consoleView.printError("Failed: \(error.localizedDescription)")
                throw ExitCode.failure
            case .cancelled:
                consoleView.printWarning("Operation cancelled")
            }
        } catch {
            consoleView.printError(error.localizedDescription)
            throw ExitCode.failure
        }
    }
}
