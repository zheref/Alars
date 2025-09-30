import ArgumentParser
import Foundation
import Rainbow

struct InitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new xprojects.json file"
    )

    func run() throws {
        let consoleView = ConsoleView()
        let fileManager = FileManager.default
        let projectsFilePath = fileManager.currentDirectoryPath.appending("/xprojects.json")

        if fileManager.fileExists(atPath: projectsFilePath) {
            let overwrite = consoleView.askConfirmation("xprojects.json already exists. Overwrite?")
            guard overwrite else {
                consoleView.printWarning("Initialization cancelled")
                return
            }
        }

        consoleView.printInfo("Let's create your xprojects.json file!")
        consoleView.print("")

        var projects: [Project] = []
        var addMore = true

        while addMore {
            if let project = createProject(consoleView: consoleView) {
                projects.append(project)
                consoleView.printSuccess("Project '\(project.name)' added")
            }

            addMore = consoleView.askConfirmation("Add another project?")
        }

        if projects.isEmpty {
            consoleView.printWarning("No projects added. Initialization cancelled")
            return
        }

        let projectsFile = ProjectsFile(projects: projects)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(projectsFile)
            try data.write(to: URL(fileURLWithPath: projectsFilePath))
            consoleView.printSuccess("xprojects.json created successfully with \(projects.count) project(s)")
        } catch {
            consoleView.printError("Failed to create xprojects.json: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private func createProject(consoleView: ConsoleViewProtocol) -> Project? {
        consoleView.print("\n" + "─".repeated(40).dim)
        consoleView.print("New Project Configuration".bold)
        consoleView.print("─".repeated(40).dim)

        guard let name = consoleView.askInput("Project name:"), !name.isEmpty else {
            consoleView.printError("Project name is required")
            return nil
        }

        guard let workingDir = consoleView.askInput("Working directory path:"), !workingDir.isEmpty else {
            consoleView.printError("Working directory is required")
            return nil
        }

        let repoURL = consoleView.askInput("Repository URL (optional):")
        let defaultBranch = consoleView.askInput("Default branch (main/master):") ?? "main"
        let defaultScheme = consoleView.askInput("Default build scheme (optional):")
        let defaultTestScheme = consoleView.askInput("Default test scheme (optional):")
        let defaultSimulator = consoleView.askInput("Default simulator (optional, e.g., iPhone 15):")

        var savePreference: ProjectConfiguration.SavePreference?
        if consoleView.askConfirmation("Configure save preference?") {
            let useStash = consoleView.askConfirmation("Use stash for saving changes? (No = use branch)")
            savePreference = useStash ? .stash : .branch
        }

        let configuration = ProjectConfiguration(
            defaultBranch: defaultBranch,
            defaultScheme: defaultScheme?.isEmpty == true ? nil : defaultScheme,
            defaultTestScheme: defaultTestScheme?.isEmpty == true ? nil : defaultTestScheme,
            defaultSimulator: defaultSimulator?.isEmpty == true ? nil : defaultSimulator,
            savePreference: savePreference
        )

        var customCommands: [CustomCommand] = []
        if consoleView.askConfirmation("Add custom commands?") {
            while true {
                if let command = createCustomCommand(consoleView: consoleView) {
                    customCommands.append(command)
                    consoleView.printSuccess("Custom command '\(command.alias)' added")
                }

                if !consoleView.askConfirmation("Add another custom command?") {
                    break
                }
            }
        }

        return Project(
            name: name,
            workingDirectory: workingDir,
            repositoryURL: repoURL?.isEmpty == true ? nil : repoURL,
            configuration: configuration,
            customCommands: customCommands.isEmpty ? nil : customCommands
        )
    }

    private func createCustomCommand(consoleView: ConsoleViewProtocol) -> CustomCommand? {
        guard let alias = consoleView.askInput("Command alias:"), !alias.isEmpty else {
            consoleView.printError("Command alias is required")
            return nil
        }

        guard let description = consoleView.askInput("Command description:"), !description.isEmpty else {
            consoleView.printError("Command description is required")
            return nil
        }

        var operations: [CustomCommand.Operation] = []

        consoleView.printInfo("Add operations for this command (in order)")
        while true {
            let operationTypes = OperationType.allCases.map { $0.rawValue }
            guard let selected = consoleView.selectFromList("Select operation type:", options: operationTypes),
                  let operationType = OperationType(rawValue: selected) else {
                break
            }

            var parameters: [String: String] = [:]

            switch operationType {
            case .build, .test:
                if let scheme = consoleView.askInput("Specific scheme (optional):"), !scheme.isEmpty {
                    parameters["scheme"] = scheme
                }
            case .run:
                if let scheme = consoleView.askInput("Specific scheme (optional):"), !scheme.isEmpty {
                    parameters["scheme"] = scheme
                }
                if let simulator = consoleView.askInput("Specific simulator (optional):"), !simulator.isEmpty {
                    parameters["simulator"] = simulator
                }
            default:
                break
            }

            let operation = CustomCommand.Operation(
                type: operationType,
                parameters: parameters.isEmpty ? nil : parameters
            )
            operations.append(operation)

            if !consoleView.askConfirmation("Add another operation to this command?") {
                break
            }
        }

        guard !operations.isEmpty else {
            consoleView.printError("At least one operation is required")
            return nil
        }

        return CustomCommand(alias: alias, description: description, operations: operations)
    }
}