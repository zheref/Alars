import Foundation

/// Represents the outcome of an operation execution
enum OperationResult {
    case success(String)  // Operation succeeded with a message
    case failure(Error)   // Operation failed with an error
    case cancelled        // User cancelled the operation

    /// Convenience property to check if the operation succeeded
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

/// Custom error types for Alars operations
/// Provides user-friendly error messages
enum AlarsError: LocalizedError {
    case projectsFileNotFound
    case invalidProjectsFile
    case projectNotFound(String)
    case invalidWorkingDirectory(String)
    case gitOperationFailed(String)
    case xcodeBuildFailed(String)
    case simulatorNotFound(String)
    case schemeNotFound(String)
    case customCommandNotFound(String)
    case operationCancelled

    /// Provides localized, user-friendly error descriptions
    var errorDescription: String? {
        switch self {
        case .projectsFileNotFound:
            return "xprojects.json file not found in current directory"
        case .invalidProjectsFile:
            return "Invalid xprojects.json file format"
        case .projectNotFound(let name):
            return "Project '\(name)' not found"
        case .invalidWorkingDirectory(let path):
            return "Invalid working directory: \(path)"
        case .gitOperationFailed(let message):
            return "Git operation failed: \(message)"
        case .xcodeBuildFailed(let message):
            return "Xcode build failed: \(message)"
        case .simulatorNotFound(let name):
            return "Simulator '\(name)' not found"
        case .schemeNotFound(let name):
            return "Scheme '\(name)' not found"
        case .customCommandNotFound(let alias):
            return "Custom command '\(alias)' not found"
        case .operationCancelled:
            return "Operation cancelled by user"
        }
    }
}