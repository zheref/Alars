import ArgumentParser
import Foundation
import Rainbow

/// Command for running Alars in interactive or direct mode
/// This is the default command that handles project operations
struct RunCommand: AsyncParsableCommand {
    /// Configuration for the run command
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run Alars in interactive mode"
    )

    /// Optional project name for direct operation (bypasses project selection)
    @Option(name: .shortAndLong, help: "Project name to work with directly")
    var project: String?

    /// Optional operation to execute directly (bypasses interactive menu)
    @Option(name: .shortAndLong, help: "Operation to execute directly")
    var operation: String?

    /// Optional custom command alias to execute directly
    @Option(name: .shortAndLong, help: "Custom command to execute")
    var command: String?

    /// Main execution method for the run command
    /// Handles both interactive and direct operation modes
    /// - Throws: ExitCode.failure if operation fails
    func run() async throws {
        let projectService = ProjectService()
        let consoleView = ConsoleView()
        let operationController = OperationController()

        // Show current working directory to help users understand context
        let currentDir = FileManager.default.currentDirectoryPath
        consoleView.printInfo("Working directory: \(currentDir)")

        do {
            // Load project configurations from xprojects.json
            let projects = try projectService.loadProjects()

            // Ensure we have at least one project configured
            if projects.isEmpty {
                consoleView.printError("No projects found in xprojects.json")
                return
            }

            // Handle direct project specification
            if let projectName = project {
                // Find the specified project by name
                guard let selectedProject = projects.first(where: { $0.name == projectName }) else {
                    throw AlarsError.projectNotFound(projectName)
                }

                // Validate project configuration
                try projectService.validateProject(selectedProject)

                // Execute specific operation if provided
                if let operationName = operation,
                   let operationType = OperationType(rawValue: operationName) {
                    let result = try await operationController.executeOperation(operationType, on: selectedProject)
                    handleResult(result, consoleView: consoleView)
                // Execute custom command if provided
                } else if let commandAlias = command,
                          let customCommand = selectedProject.customCommands?.first(where: { $0.alias == commandAlias }) {
                    let results = try await operationController.executeCustomCommand(customCommand, on: selectedProject)
                    for result in results {
                        handleResult(result, consoleView: consoleView)
                    }
                // Fall back to interactive mode for this project
                } else {
                    await runInteractiveMode(projects: projects, selectedProject: selectedProject)
                }
            // No project specified - start with full interactive mode
            } else {
                await runInteractiveMode(projects: projects, selectedProject: nil)
            }

        } catch {
            // Handle specific case where xprojects.json is not found
            if let alarsError = error as? AlarsError {
                switch alarsError {
                case .projectsFileNotFound:
                    consoleView.printError("No xprojects.json file found in current directory")
                    consoleView.printInfo("Current directory: \(FileManager.default.currentDirectoryPath)")
                    let shouldCreate = consoleView.askConfirmation("Would you like to create one now?")
                    if shouldCreate {
                        // Use the init command to create the configuration
                        let initCommand = InitCommand()
                        try initCommand.run()
                        // After creation, try again
                        try await run()
                        return
                    } else {
                        consoleView.printInfo("You can create one later by running: alars init")
                    }
                default:
                    consoleView.printError(error.localizedDescription)
                }
            } else {
                consoleView.printError(error.localizedDescription)
            }
            throw ExitCode.failure
        }
    }

    /// Runs the interactive menu system
    /// - Parameters:
    ///   - projects: All available projects
    ///   - selectedProject: Pre-selected project (optional)
    private func runInteractiveMode(projects: [Project], selectedProject: Project?) async {
        let menuView = MenuView()
        let consoleView = ConsoleView()
        let projectService = ProjectService()
        let operationController = OperationController()

        menuView.showMainMenu()

        var currentProject = selectedProject
        var shouldExit = false

        // Main interactive loop
        while !shouldExit {
            // Project selection phase
            if currentProject == nil {
                currentProject = menuView.selectProject(from: projects)
                if currentProject == nil {
                    // User chose to exit
                    shouldExit = true
                    continue
                }
            }

            guard let project = currentProject else { break }

            // Validate the selected project
            do {
                try projectService.validateProject(project)
            } catch {
                consoleView.printError("Invalid project: \(error.localizedDescription)")
                currentProject = nil
                continue
            }

            // Show project menu and get user selection
            guard let menuOption = menuView.showProjectMenu(for: project) else {
                continue
            }

            // Handle user's menu selection
            switch menuOption {
            case .operation(let operationType):
                // Execute standard operation
                do {
                    let result = try await operationController.executeOperation(operationType, on: project)
                    handleResult(result, consoleView: consoleView)
                } catch {
                    consoleView.printError("Operation failed: \(error.localizedDescription)")
                }

            case .customCommand(let alias):
                // Execute custom command sequence
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
                // Return to project selection
                currentProject = nil

            case .exit:
                // Exit the application
                shouldExit = true
            }

            // Wait for user acknowledgment before continuing
            if !shouldExit && currentProject != nil {
                consoleView.print("\nPress Enter to continue...".dim)
                _ = readLine()
            }
        }

        consoleView.printInfo("Goodbye! 👋")
    }

    /// Handles and displays operation results
    /// - Parameters:
    ///   - result: The operation result to handle
    ///   - consoleView: Console view for output
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