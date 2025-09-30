import Foundation

/// Represents a single Xcode project configuration
/// This is the main data model for projects managed by Alars
struct Project: Codable, Equatable {
    /// Display name for the project
    let name: String

    /// Path to the project directory (supports ~ for home directory)
    let workingDirectory: String

    /// Optional Git repository URL
    let repositoryURL: String?

    /// Project-specific configuration settings
    let configuration: ProjectConfiguration

    /// Optional array of custom command sequences
    let customCommands: [CustomCommand]?

    /// Converts the working directory path to an absolute path
    /// Handles three cases:
    /// - Absolute paths (starting with /)
    /// - Home directory paths (starting with ~)
    /// - Relative paths (resolved from current directory)
    var absoluteWorkingDirectory: String {
        if workingDirectory.starts(with: "/") {
            // Already an absolute path
            return workingDirectory
        } else if workingDirectory.starts(with: "~") {
            // Replace ~ with actual home directory
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
            return workingDirectory.replacingOccurrences(of: "~", with: homeDirectory)
        } else {
            // Treat as relative path from current directory
            return FileManager.default.currentDirectoryPath.appending("/\(workingDirectory)")
        }
    }
}

/// Configuration settings for a project
/// Contains defaults and preferences for various operations
struct ProjectConfiguration: Codable, Equatable {
    /// The main branch name (e.g., "main" or "master")
    let defaultBranch: String

    /// Default Xcode scheme for building
    let defaultScheme: String?

    /// Default scheme for running tests
    let defaultTestScheme: String?

    /// Default simulator name for running apps
    let defaultSimulator: String?

    /// Preference for saving uncommitted changes
    let savePreference: SavePreference?

    /// Defines how uncommitted changes should be saved
    enum SavePreference: String, Codable {
        case stash  // Use git stash
        case branch // Create a new branch
    }
}

/// Represents a custom command that chains multiple operations
/// Allows users to create reusable workflows
struct CustomCommand: Codable, Equatable {
    /// Short name to invoke this command
    let alias: String

    /// Human-readable description of what the command does
    let description: String

    /// Ordered list of operations to execute
    let operations: [Operation]

    /// Single operation within a custom command
    struct Operation: Codable, Equatable {
        /// The type of operation to perform
        let type: OperationType

        /// Optional parameters for the operation (e.g., scheme name)
        let parameters: [String: String]?
    }
}

/// All available operations that can be performed on a project
enum OperationType: String, Codable, CaseIterable, CustomStringConvertible {
    case cleanSlate = "clean_slate"  // Reset working directory
    case save                         // Save uncommitted changes
    case update                       // Pull latest from remote
    case build                        // Build the project
    case test                         // Run tests
    case run                          // Launch the app
    case reset                        // Clean build folder, derived data, and reinstall dependencies

    /// User-friendly display name for the operation
    var description: String {
        switch self {
        case .cleanSlate: return "Clean Slate"
        case .save: return "Save"
        case .update: return "Update"
        case .build: return "Build"
        case .test: return "Test"
        case .run: return "Run"
        case .reset: return "Reset"
        }
    }
}

/// Root structure of the xprojects.json file
/// Contains all project configurations
struct ProjectsFile: Codable {
    /// Array of all configured projects
    let projects: [Project]
}