import ArgumentParser
import Foundation

/// Command for cleaning a project's working directory directly
struct CleanCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clean",
        abstract: "Clean a project's working directory (clean slate)"
    )

    @Argument(help: "Project name to clean")
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

            let result = try await operationController.executeOperation(.cleanSlate, on: project)

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
