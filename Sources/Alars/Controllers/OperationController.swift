import Foundation

protocol OperationControllerProtocol {
    func executeOperation(_ operation: OperationType, on project: Project, parameters: [String: String]?) async throws -> OperationResult
    func executeCustomCommand(_ command: CustomCommand, on project: Project) async throws -> [OperationResult]
}

class OperationController: OperationControllerProtocol {
    private let gitService: GitServiceProtocol
    private let xcodeService: XcodeServiceProtocol
    private let consoleView: ConsoleViewProtocol

    init(gitService: GitServiceProtocol = GitService(),
         xcodeService: XcodeServiceProtocol = XcodeService(),
         consoleView: ConsoleViewProtocol = ConsoleView()) {
        self.gitService = gitService
        self.xcodeService = xcodeService
        self.consoleView = consoleView
    }

    func executeOperation(_ operation: OperationType, on project: Project, parameters: [String: String]? = nil) async throws -> OperationResult {
        let workingDirectory = project.absoluteWorkingDirectory

        switch operation {
        case .cleanSlate:
            return try await executeCleanSlate(at: workingDirectory, project: project)
        case .save:
            return try await executeSave(at: workingDirectory, project: project)
        case .update:
            return try await executeUpdate(at: workingDirectory, project: project)
        case .build:
            return try await executeBuild(at: workingDirectory, project: project, parameters: parameters)
        case .test:
            return try await executeTest(at: workingDirectory, project: project, parameters: parameters)
        case .run:
            return try await executeRun(at: workingDirectory, project: project, parameters: parameters)
        }
    }

    func executeCustomCommand(_ command: CustomCommand, on project: Project) async throws -> [OperationResult] {
        consoleView.printInfo("Executing custom command: \(command.alias)")
        var results: [OperationResult] = []

        for operation in command.operations {
            consoleView.printInfo("Running operation: \(operation.type.rawValue)")
            let result = try await executeOperation(operation.type, on: project, parameters: operation.parameters)
            results.append(result)

            if case .failure = result {
                consoleView.printError("Operation failed. Stopping custom command execution.")
                break
            }
        }

        return results
    }

    private func executeCleanSlate(at path: String, project: Project) async throws -> OperationResult {
        consoleView.printInfo("Checking working directory status...")

        let isClean = try gitService.isCleanWorkingDirectory(at: path)
        if isClean {
            return .success("Working directory is already clean")
        }

        let shouldProceed = consoleView.askConfirmation("This will discard all uncommitted changes. Are you sure?")
        guard shouldProceed else {
            return .cancelled
        }

        consoleView.printProgress("Discarding all changes...")
        try gitService.discardAllChanges(at: path)

        return .success("Successfully cleaned working directory")
    }

    private func executeSave(at path: String, project: Project) async throws -> OperationResult {
        consoleView.printInfo("Checking working directory status...")

        let isClean = try gitService.isCleanWorkingDirectory(at: path)
        if isClean {
            return .success("Working directory is already clean")
        }

        let preference = project.configuration.savePreference ?? .stash
        let currentBranch = try gitService.getCurrentBranch(at: path)

        switch preference {
        case .stash:
            let message = consoleView.askInput("Enter stash message (optional):")
            consoleView.printProgress("Stashing changes...")
            try gitService.stashChanges(at: path, message: message?.isEmpty == true ? nil : message)
            return .success("Changes stashed successfully")

        case .branch:
            let branchName = consoleView.askInput("Enter branch name:") ?? "alars-backup-\(Date().timeIntervalSince1970)"
            consoleView.printProgress("Creating branch and committing changes...")
            try gitService.createBranch(at: path, name: branchName, commitChanges: true)
            try gitService.switchToBranch(at: path, branch: currentBranch)
            return .success("Changes saved to branch: \(branchName)")
        }
    }

    private func executeUpdate(at path: String, project: Project) async throws -> OperationResult {
        let branch = project.configuration.defaultBranch

        consoleView.printInfo("Checking working directory status...")
        let isClean = try gitService.isCleanWorkingDirectory(at: path)

        if !isClean {
            let shouldSave = consoleView.askConfirmation("You have uncommitted changes. Do you want to save them first?")
            if shouldSave {
                _ = try await executeSave(at: path, project: project)
            }
        }

        consoleView.printProgress("Pulling latest changes from \(branch)...")
        try gitService.pullLatestChanges(at: path, branch: branch)

        return .success("Successfully updated from \(branch)")
    }

    private func executeBuild(at path: String, project: Project, parameters: [String: String]?) async throws -> OperationResult {
        consoleView.printInfo("Fetching available schemes...")
        let schemes = try xcodeService.listSchemes(at: path)

        guard !schemes.isEmpty else {
            throw AlarsError.xcodeBuildFailed("No schemes found")
        }

        let selectedScheme: String
        if let paramScheme = parameters?["scheme"], schemes.contains(paramScheme) {
            selectedScheme = paramScheme
        } else if let defaultScheme = project.configuration.defaultScheme, schemes.contains(defaultScheme) {
            selectedScheme = defaultScheme
        } else {
            selectedScheme = consoleView.selectFromList("Select scheme to build:", options: schemes) ?? schemes[0]
        }

        let verbose = consoleView.askConfirmation("Enable verbose output?")

        consoleView.printProgress("Building scheme: \(selectedScheme)...")
        let output = try xcodeService.buildProject(at: path, scheme: selectedScheme, verbose: verbose)

        if verbose {
            consoleView.print(output)
        }

        return .success("Build completed successfully for scheme: \(selectedScheme)")
    }

    private func executeTest(at path: String, project: Project, parameters: [String: String]?) async throws -> OperationResult {
        consoleView.printInfo("Fetching available test schemes...")
        let schemes = try xcodeService.listSchemes(at: path)
        let testSchemes = schemes.filter { $0.contains("Test") || $0.contains("test") }

        let selectedScheme: String
        if let paramScheme = parameters?["scheme"], schemes.contains(paramScheme) {
            selectedScheme = paramScheme
        } else if let defaultTestScheme = project.configuration.defaultTestScheme, schemes.contains(defaultTestScheme) {
            selectedScheme = defaultTestScheme
        } else if !testSchemes.isEmpty {
            selectedScheme = consoleView.selectFromList("Select test scheme:", options: testSchemes) ?? testSchemes[0]
        } else {
            selectedScheme = consoleView.selectFromList("Select scheme to test:", options: schemes) ?? schemes[0]
        }

        consoleView.printProgress("Running tests for scheme: \(selectedScheme)...")
        let output = try xcodeService.runTests(at: path, scheme: selectedScheme)
        consoleView.print(output)

        return .success("Tests completed for scheme: \(selectedScheme)")
    }

    private func executeRun(at path: String, project: Project, parameters: [String: String]?) async throws -> OperationResult {
        consoleView.printInfo("Fetching available schemes...")
        let schemes = try xcodeService.listSchemes(at: path)

        guard !schemes.isEmpty else {
            throw AlarsError.xcodeBuildFailed("No schemes found")
        }

        let selectedScheme: String
        if let paramScheme = parameters?["scheme"], schemes.contains(paramScheme) {
            selectedScheme = paramScheme
        } else if let defaultScheme = project.configuration.defaultScheme, schemes.contains(defaultScheme) {
            selectedScheme = defaultScheme
        } else {
            selectedScheme = consoleView.selectFromList("Select scheme to run:", options: schemes) ?? schemes[0]
        }

        consoleView.printInfo("Fetching available simulators...")
        let simulators = try xcodeService.listSimulators()
        let availableSimulators = simulators.filter { $0.state == "Booted" || $0.state == "Shutdown" }

        let selectedSimulator: String?
        if let paramSimulator = parameters?["simulator"] {
            selectedSimulator = simulators.first { $0.name == paramSimulator }?.udid
        } else if let defaultSim = project.configuration.defaultSimulator {
            selectedSimulator = simulators.first { $0.name.contains(defaultSim) }?.udid
        } else if !availableSimulators.isEmpty {
            let simOptions = availableSimulators.map { $0.displayName }
            if let selected = consoleView.selectFromList("Select simulator:", options: simOptions) {
                let index = simOptions.firstIndex(of: selected) ?? 0
                selectedSimulator = availableSimulators[index].udid
            } else {
                selectedSimulator = nil
            }
        } else {
            selectedSimulator = nil
        }

        consoleView.printProgress("Running \(selectedScheme)...")
        try xcodeService.runProject(at: path, scheme: selectedScheme, simulator: selectedSimulator)

        return .success("Successfully launched \(selectedScheme)")
    }
}