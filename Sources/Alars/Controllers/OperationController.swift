import Foundation
import ShellOut

/// Protocol defining the operation controller interface
/// Allows for dependency injection and testing
protocol OperationControllerProtocol {
    func executeOperation(_ operation: OperationType, on project: Project, parameters: [String: String]?) async throws -> OperationResult
    func executeCustomCommand(_ command: CustomCommand, on project: Project) async throws -> [OperationResult]
}

/// Controller responsible for orchestrating project operations
/// Coordinates between services and user interface to execute operations
class OperationController: OperationControllerProtocol {
    // Service dependencies for external operations
    private let gitService: GitServiceProtocol
    private let xcodeService: XcodeServiceProtocol
    private let consoleView: ConsoleViewProtocol
    private let errorReportService: ErrorReportService

    /// Initializes the controller with service dependencies
    /// - Parameters:
    ///   - gitService: Service for Git operations
    ///   - xcodeService: Service for Xcode operations
    ///   - consoleView: Service for user interface
    ///   - errorReportService: Service for error reporting
    init(gitService: GitServiceProtocol = GitService(),
         xcodeService: XcodeServiceProtocol = XcodeService(),
         consoleView: ConsoleViewProtocol = ConsoleView(),
         errorReportService: ErrorReportService = ErrorReportService()) {
        self.gitService = gitService
        self.xcodeService = xcodeService
        self.consoleView = consoleView
        self.errorReportService = errorReportService
    }

    /// Executes a single operation on the specified project
    /// - Parameters:
    ///   - operation: Type of operation to execute
    ///   - project: Target project configuration
    ///   - parameters: Optional operation-specific parameters
    /// - Returns: Result of the operation
    /// - Throws: Various errors depending on the operation
    func executeOperation(_ operation: OperationType, on project: Project, parameters: [String: String]? = nil) async throws -> OperationResult {
        let workingDirectory = project.absoluteWorkingDirectory

        // Route to appropriate operation handler
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
        case .reset:
            return try await executeReset(at: workingDirectory, project: project)
        }
    }

    /// Executes a custom command (sequence of operations) on the specified project
    /// - Parameters:
    ///   - command: Custom command containing operation sequence
    ///   - project: Target project configuration
    /// - Returns: Array of results for each operation in the sequence
    /// - Throws: Various errors depending on the operations
    func executeCustomCommand(_ command: CustomCommand, on project: Project) async throws -> [OperationResult] {
        consoleView.printInfo("Executing custom command: \(command.alias)")
        var results: [OperationResult] = []

        // Execute each operation in sequence
        for operation in command.operations {
            consoleView.printInfo("Running operation: \(operation.type.rawValue)")
            let result = try await executeOperation(operation.type, on: project, parameters: operation.parameters)
            results.append(result)

            // Stop execution on first failure
            if case .failure = result {
                consoleView.printError("Operation failed. Stopping custom command execution.")
                break
            }
        }

        return results
    }

    /// Executes the clean slate operation - resets working directory to clean state
    /// WARNING: This discards all uncommitted changes permanently
    /// - Parameters:
    ///   - path: Path to the project directory
    ///   - project: Project configuration (unused but kept for consistency)
    /// - Returns: Operation result
    private func executeCleanSlate(at path: String, project: Project) async throws -> OperationResult {
        consoleView.printInfo("Checking working directory status...")

        // Check if directory is already clean
        let isClean = try gitService.isCleanWorkingDirectory(at: path)
        if isClean {
            return .success("Working directory is already clean")
        }

        // Confirm with user before destructive operation
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

        do {
            let output = try xcodeService.buildProject(at: path, scheme: selectedScheme, verbose: verbose)

            if verbose {
                consoleView.print(output)
            }

            return .success("Build completed successfully for scheme: \(selectedScheme)")
        } catch {
            // Generate error report for build failures
            let reportPath = errorReportService.generateErrorReport(
                operation: "build",
                project: project,
                error: error,
                output: (error as? ShellOutError)?.output
            )
            consoleView.printWarning("Error report generated: \(reportPath)")
            throw error
        }
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

        do {
            let output = try xcodeService.runTests(at: path, scheme: selectedScheme)
            consoleView.print(output)

            return .success("Tests completed for scheme: \(selectedScheme)")
        } catch {
            // Generate error report for test failures
            let reportPath = errorReportService.generateErrorReport(
                operation: "test",
                project: project,
                error: error,
                output: (error as? ShellOutError)?.output
            )
            consoleView.printWarning("Error report generated: \(reportPath)")
            throw error
        }
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

    private func executeReset(at path: String, project: Project) async throws -> OperationResult {
        consoleView.printInfo("This will clean build folder, remove derived data, and reinstall dependencies")

        let shouldProceed = consoleView.askConfirmation("Are you sure you want to reset the project?")
        guard shouldProceed else {
            return .cancelled
        }

        consoleView.printProgress("Cleaning build folder...")
        try xcodeService.cleanBuildFolder(at: path)

        consoleView.printProgress("Removing derived data...")
        try xcodeService.cleanDerivedData()

        consoleView.printProgress("Reinstalling dependencies...")
        // Check for different dependency managers
        let fileManager = FileManager.default

        // Check for SPM (Package.swift or .xcodeproj with SPM)
        let packageSwiftPath = (path as NSString).appendingPathComponent("Package.swift")
        if fileManager.fileExists(atPath: packageSwiftPath) {
            consoleView.printInfo("Detected Swift Package Manager")
            try shellOut(to: "swift package resolve", at: path)
        }

        // Check for CocoaPods (Podfile)
        let podfilePath = (path as NSString).appendingPathComponent("Podfile")
        if fileManager.fileExists(atPath: podfilePath) {
            consoleView.printInfo("Detected CocoaPods")
            try shellOut(to: "pod install", at: path)
        }

        // Check for Carthage (Cartfile)
        let cartfilePath = (path as NSString).appendingPathComponent("Cartfile")
        if fileManager.fileExists(atPath: cartfilePath) {
            consoleView.printInfo("Detected Carthage")
            try shellOut(to: "carthage bootstrap --use-xcframeworks", at: path)
        }

        return .success("Successfully reset project")
    }
}