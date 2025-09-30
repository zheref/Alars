import ArgumentParser
import Foundation
import Rainbow

struct RunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run Alars in interactive mode"
    )

    @Option(name: .shortAndLong, help: "Project name to work with directly")
    var project: String?

    @Option(name: .shortAndLong, help: "Operation to execute directly")
    var operation: String?

    @Option(name: .shortAndLong, help: "Custom command to execute")
    var command: String?

    func run() async throws {
        let projectService = ProjectService()
        let consoleView = ConsoleView()
        let operationController = OperationController()

        do {
            let projects = try projectService.loadProjects()

            if projects.isEmpty {
                consoleView.printError("No projects found in xprojects.json")
                return
            }

            if let projectName = project {
                guard let selectedProject = projects.first(where: { $0.name == projectName }) else {
                    throw AlarsError.projectNotFound(projectName)
                }

                try projectService.validateProject(selectedProject)

                if let operationName = operation,
                   let operationType = OperationType(rawValue: operationName) {
                    let result = try await operationController.executeOperation(operationType, on: selectedProject)
                    handleResult(result, consoleView: consoleView)
                } else if let commandAlias = command,
                          let customCommand = selectedProject.customCommands?.first(where: { $0.alias == commandAlias }) {
                    let results = try await operationController.executeCustomCommand(customCommand, on: selectedProject)
                    for result in results {
                        handleResult(result, consoleView: consoleView)
                    }
                } else {
                    await runInteractiveMode(projects: projects, selectedProject: selectedProject)
                }
            } else {
                await runInteractiveMode(projects: projects, selectedProject: nil)
            }

        } catch {
            consoleView.printError(error.localizedDescription)
            throw ExitCode.failure
        }
    }

    private func runInteractiveMode(projects: [Project], selectedProject: Project?) async {
        let menuView = MenuView()
        let consoleView = ConsoleView()
        let projectService = ProjectService()
        let operationController = OperationController()

        menuView.showMainMenu()

        var currentProject = selectedProject
        var shouldExit = false

        while !shouldExit {
            if currentProject == nil {
                currentProject = menuView.selectProject(from: projects)
                if currentProject == nil {
                    shouldExit = true
                    continue
                }
            }

            guard let project = currentProject else { break }

            do {
                try projectService.validateProject(project)
            } catch {
                consoleView.printError("Invalid project: \(error.localizedDescription)")
                currentProject = nil
                continue
            }

            guard let menuOption = menuView.showProjectMenu(for: project) else {
                continue
            }

            switch menuOption {
            case .operation(let operationType):
                do {
                    let result = try await operationController.executeOperation(operationType, on: project)
                    handleResult(result, consoleView: consoleView)
                } catch {
                    consoleView.printError("Operation failed: \(error.localizedDescription)")
                }

            case .customCommand(let alias):
                if let command = project.customCommands?.first(where: { $0.alias == alias }) {
                    do {
                        let results = try await operationController.executeCustomCommand(command, on: project)
                        for result in results {
                            handleResult(result, consoleView: consoleView)
                        }
                    } catch {
                        consoleView.printError("Custom command failed: \(error.localizedDescription)")
                    }
                }

            case .back:
                currentProject = nil

            case .exit:
                shouldExit = true
            }

            if !shouldExit && currentProject != nil {
                consoleView.print("\nPress Enter to continue...".dim)
                _ = readLine()
            }
        }

        consoleView.printInfo("Goodbye! 👋")
    }

    private func handleResult(_ result: OperationResult, consoleView: ConsoleViewProtocol) {
        switch result {
        case .success(let message):
            consoleView.printSuccess(message)
        case .failure(let error):
            consoleView.printError("Failed: \(error.localizedDescription)")
        case .cancelled:
            consoleView.printWarning("Operation cancelled")
        }
    }
}