import Foundation
import ShellOut

/// Protocol defining Git operations interface
/// Allows for easy mocking in tests
protocol GitServiceProtocol {
    func isCleanWorkingDirectory(at path: String) throws -> Bool
    func discardAllChanges(at path: String) throws
    func stashChanges(at path: String, message: String?) throws
    func createBranch(at path: String, name: String, commitChanges: Bool) throws
    func pullLatestChanges(at path: String, branch: String) throws
    func getCurrentBranch(at path: String) throws -> String
    func getMainBranch(at path: String, configuredDefaultBranch: String?) throws -> String?
    func switchToBranch(at path: String, branch: String) throws
    func branchExists(at path: String, branch: String) throws -> Bool
    func stashWithName(at path: String, name: String) throws
    func getStashList(at path: String) throws -> [String]
    func popStashByName(at path: String, name: String) throws -> Bool
}

/// Service responsible for executing Git operations
/// Uses ShellOut to run git commands in the specified directories
class GitService: GitServiceProtocol {
    /// Checks if the Git working directory has any uncommitted changes
    /// - Parameter path: Path to the Git repository
    /// - Returns: true if working directory is clean, false otherwise
    /// - Throws: ShellOut error if git command fails
    func isCleanWorkingDirectory(at path: String) throws -> Bool {
        // git status --porcelain returns empty output for clean directories
        let output = try shellOut(to: "git status --porcelain", at: path)
        return output.isEmpty
    }

    /// Discards all uncommitted changes and untracked files
    /// WARNING: This operation cannot be undone
    /// - Parameter path: Path to the Git repository
    /// - Throws: ShellOut error if git commands fail
    func discardAllChanges(at path: String) throws {
        // Reset all tracked files to HEAD state
        try shellOut(to: "git reset --hard HEAD", at: path)
        // Remove all untracked files and directories
        try shellOut(to: "git clean -fd", at: path)
    }

    /// Stashes all uncommitted changes with an optional message
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - message: Optional custom message for the stash
    /// - Throws: ShellOut error if stash fails
    func stashChanges(at path: String, message: String?) throws {
        // Create stash command with custom or auto-generated message
        let stashCommand = if let message = message {
            "git stash push -m \"\(message)\""
        } else {
            // Auto-generate timestamp-based message if none provided
            "git stash push -m \"Alars auto-stash: \(Date().ISO8601Format())\""
        }
        try shellOut(to: stashCommand, at: path)
    }

    /// Creates a new branch and optionally commits current changes
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - name: Name for the new branch
    ///   - commitChanges: Whether to commit current changes before branching
    /// - Throws: ShellOut error if branch creation fails
    func createBranch(at path: String, name: String, commitChanges: Bool) throws {
        if commitChanges {
            // Stage all changes
            try shellOut(to: "git add .", at: path)
            // Create a WIP commit
            try shellOut(to: "git commit -m \"WIP: Auto-commit by Alars\"", at: path)
        }
        // Create and switch to the new branch
        try shellOut(to: "git checkout -b \(name)", at: path)
    }

    /// Pulls latest changes from the remote repository
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - branch: Branch to pull from
    /// - Throws: ShellOut error if pull fails
    func pullLatestChanges(at path: String, branch: String) throws {
        // Ensure we're on the correct branch
        let currentBranch = try getCurrentBranch(at: path)
        if currentBranch != branch {
            try switchToBranch(at: path, branch: branch)
        }
        // Pull from origin
        try shellOut(to: "git pull origin \(branch)", at: path)
    }

    /// Gets the name of the currently checked out branch
    /// - Parameter path: Path to the Git repository
    /// - Returns: Name of the current branch
    /// - Throws: ShellOut error if command fails
    func getCurrentBranch(at path: String) throws -> String {
        let output = try shellOut(to: "git rev-parse --abbrev-ref HEAD", at: path)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Gets the name of the main branch
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - configuredDefaultBranch: Name of the configured default branch from the project configuration
    /// - Returns: Name of the main branch
    /// - Throws: ShellOut error if command fails
    func getMainBranch(at path: String, configuredDefaultBranch: String? = nil) throws -> String? {
        let possibleBranchNames = [configuredDefaultBranch, "develop", "main", "master"]
        let mainBranchName = possibleBranchNames
            .compactMap { $0 }
            .first {
                try! self.branchExists(at: path, branch: $0)
            }
        return mainBranchName
    }

    /// Switches to a different branch
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - branch: Name of the branch to switch to
    /// - Throws: ShellOut error if checkout fails
    func switchToBranch(at path: String, branch: String) throws {
        try shellOut(to: "git checkout \(branch)", at: path)
    }

    /// Checks if a branch exists in the repository
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - branch: Name of the branch to check
    /// - Returns: true if branch exists, false otherwise
    /// - Throws: ShellOut error if command fails
    func branchExists(at path: String, branch: String) throws -> Bool {
        do {
            let output = try shellOut(to: "git rev-parse --verify \(branch)", at: path)
            return !output.isEmpty
        } catch {
            // If the command fails, the branch doesn't exist
            return false
        }
    }

    /// Stashes changes with a specific name for changeset management
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - name: Name/identifier for the stash (e.g., "changeset-TICKET-123")
    /// - Throws: ShellOut error if stash fails
    func stashWithName(at path: String, name: String) throws {
        let stashMessage = "alars-changeset: \(name)"
        try shellOut(to: "git stash push -m \"\(stashMessage)\"", at: path)
    }

    /// Gets a list of all stash entries with their messages
    /// - Parameter path: Path to the Git repository
    /// - Returns: Array of stash entries (format: "stash@{N}: message")
    /// - Throws: ShellOut error if command fails
    func getStashList(at path: String) throws -> [String] {
        let output = try shellOut(to: "git stash list", at: path)
        if output.isEmpty {
            return []
        }
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    /// Pops a stash entry by its changeset name
    /// - Parameters:
    ///   - path: Path to the Git repository
    ///   - name: Changeset name to look for in stash messages
    /// - Returns: true if stash was found and popped, false if not found
    /// - Throws: ShellOut error if pop operation fails
    func popStashByName(at path: String, name: String) throws -> Bool {
        let stashList = try getStashList(at: path)
        let searchString = "alars-changeset: \(name)"

        // Find the stash index that matches our changeset name
        for (index, stashEntry) in stashList.enumerated() {
            if stashEntry.contains(searchString) {
                // Pop the specific stash by index
                try shellOut(to: "git stash pop stash@{\(index)}", at: path)
                return true
            }
        }

        return false
    }
}
