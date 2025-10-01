import ArgumentParser
import Foundation

/// Command for managing changesets across different work efforts
struct ChangesetCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "changeset",
        abstract: "Manage work across different tickets/efforts using changesets",
        subcommands: [FreshCommand.self, ResumeCommand.self]
    )

    /// Creates a fresh changeset for new work
    struct FreshCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "fresh",
            abstract: "Start a fresh changeset by stashing current work and creating a new branch"
        )

        @Argument(help: "Changeset/ticket identifier (e.g., TICKET-123)")
        var changesetId: String

        @Option(name: .shortAndLong, help: "Project name")
        var project: String?

        func run() async throws {
            let projectService = ProjectService()
            let consoleView = ConsoleView()
            let gitService = GitService()

            do {
                let projects = try projectService.loadProjects()

                let selectedProject: Project
                if let projectName = project {
                    guard let proj = projects.first(where: { $0.name == projectName }) else {
                        throw AlarsError.projectNotFound(projectName)
                    }
                    selectedProject = proj
                } else {
                    // Interactive project selection
                    let menuView = MenuView()
                    guard let proj = menuView.selectProject(from: projects) else {
                        consoleView.printWarning("No project selected")
                        throw ExitCode.failure
                    }
                    selectedProject = proj
                }

                try projectService.validateProject(selectedProject)
                let workingDir = selectedProject.absoluteWorkingDirectory

                consoleView.printInfo("Creating fresh changeset: \(changesetId)")

                // Check if we have uncommitted changes
                let isClean = try gitService.isCleanWorkingDirectory(at: workingDir)
                if !isClean {
                    consoleView.printProgress("Stashing uncommitted changes...")
                    let currentBranch = try gitService.getCurrentBranch(at: workingDir)
                    let stashName = currentBranch
                    try gitService.stashWithName(at: workingDir, name: stashName)
                    consoleView.printSuccess("Changes stashed with name: \(stashName)")
                }

                // Create the changeset branch
                let branchName = "changeset/\(changesetId)"
                let branchExists = try gitService.branchExists(at: workingDir, branch: branchName)

                if branchExists {
                    consoleView.printWarning("Branch '\(branchName)' already exists. Switching to it...")
                    try gitService.switchToBranch(at: workingDir, branch: branchName)
                } else {
                    consoleView.printProgress("Creating new branch: \(branchName)")
                    try gitService.createBranch(at: workingDir, name: branchName, commitChanges: false)
                }

                consoleView.printSuccess("✓ Fresh changeset ready!")
                consoleView.printInfo("You are now on branch: \(branchName)")

            } catch {
                consoleView.printError(error.localizedDescription)
                throw ExitCode.failure
            }
        }
    }

    /// Resumes an existing changeset
    struct ResumeCommand: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "resume",
            abstract: "Resume a previous changeset by stashing current work and restoring the changeset"
        )

        @Argument(help: "Changeset/ticket identifier to resume (e.g., TICKET-123)")
        var changesetId: String

        @Option(name: .shortAndLong, help: "Project name")
        var project: String?

        func run() async throws {
            let projectService = ProjectService()
            let consoleView = ConsoleView()
            let gitService = GitService()

            do {
                let projects = try projectService.loadProjects()

                let selectedProject: Project
                if let projectName = project {
                    guard let proj = projects.first(where: { $0.name == projectName }) else {
                        throw AlarsError.projectNotFound(projectName)
                    }
                    selectedProject = proj
                } else {
                    // Interactive project selection
                    let menuView = MenuView()
                    guard let proj = menuView.selectProject(from: projects) else {
                        consoleView.printWarning("No project selected")
                        throw ExitCode.failure
                    }
                    selectedProject = proj
                }

                try projectService.validateProject(selectedProject)
                let workingDir = selectedProject.absoluteWorkingDirectory

                consoleView.printInfo("Resuming changeset: \(changesetId)")

                // Check if we have uncommitted changes
                let isClean = try gitService.isCleanWorkingDirectory(at: workingDir)
                if !isClean {
                    consoleView.printProgress("Stashing uncommitted changes...")
                    let currentBranch = try gitService.getCurrentBranch(at: workingDir)
                    let stashName = currentBranch
                    try gitService.stashWithName(at: workingDir, name: stashName)
                    consoleView.printSuccess("Changes stashed with name: \(stashName)")
                }

                // Switch to the changeset branch
                let branchName = "changeset/\(changesetId)"
                let branchExists = try gitService.branchExists(at: workingDir, branch: branchName)

                if !branchExists {
                    consoleView.printError("Changeset branch '\(branchName)' does not exist")
                    consoleView.printInfo("Use 'alars changeset fresh \(changesetId)' to create it")
                    throw ExitCode.failure
                }

                consoleView.printProgress("Switching to branch: \(branchName)")
                try gitService.switchToBranch(at: workingDir, branch: branchName)

                // Try to pop the stash for this changeset
                consoleView.printProgress("Looking for stashed changes for this changeset...")
                let stashPopped = try gitService.popStashByName(at: workingDir, name: branchName)

                if stashPopped {
                    consoleView.printSuccess("✓ Stashed changes restored!")
                } else {
                    consoleView.printInfo("No stashed changes found for this changeset")
                }

                consoleView.printSuccess("✓ Changeset resumed!")
                consoleView.printInfo("You are now on branch: \(branchName)")

            } catch {
                consoleView.printError(error.localizedDescription)
                throw ExitCode.failure
            }
        }
    }
}
