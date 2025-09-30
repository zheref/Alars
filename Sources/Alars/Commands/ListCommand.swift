import ArgumentParser
import Foundation
import Rainbow

struct ListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all configured projects"
    )

    func run() throws {
        let projectService = ProjectService()
        let consoleView = ConsoleView()

        do {
            let projects = try projectService.loadProjects()

            if projects.isEmpty {
                consoleView.printWarning("No projects found in xprojects.json")
                return
            }

            consoleView.print("\n" + "Configured Projects".bold.green)
            consoleView.print("═".repeated(60).cyan)

            for (index, project) in projects.enumerated() {
                consoleView.print("\n\(index + 1). \(project.name)".bold)
                consoleView.print("   Directory: \(project.workingDirectory)".dim)
                consoleView.print("   Branch: \(project.configuration.defaultBranch)")

                if let repoURL = project.repositoryURL {
                    consoleView.print("   Repository: \(repoURL)".dim)
                }

                if let scheme = project.configuration.defaultScheme {
                    consoleView.print("   Default Scheme: \(scheme)")
                }

                if let commands = project.customCommands, !commands.isEmpty {
                    consoleView.print("   Custom Commands: \(commands.map { $0.alias }.joined(separator: ", "))")
                }
            }

            consoleView.print("\n" + "═".repeated(60).cyan)
            consoleView.print("Total: \(projects.count) project(s)\n")

        } catch {
            consoleView.printError(error.localizedDescription)
            throw ExitCode.failure
        }
    }
}