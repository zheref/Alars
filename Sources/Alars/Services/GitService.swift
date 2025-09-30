import Foundation
import ShellOut

protocol GitServiceProtocol {
    func isCleanWorkingDirectory(at path: String) throws -> Bool
    func discardAllChanges(at path: String) throws
    func stashChanges(at path: String, message: String?) throws
    func createBranch(at path: String, name: String, commitChanges: Bool) throws
    func pullLatestChanges(at path: String, branch: String) throws
    func getCurrentBranch(at path: String) throws -> String
    func switchToBranch(at path: String, branch: String) throws
}

class GitService: GitServiceProtocol {
    func isCleanWorkingDirectory(at path: String) throws -> Bool {
        let output = try shellOut(to: "git status --porcelain", at: path)
        return output.isEmpty
    }

    func discardAllChanges(at path: String) throws {
        try shellOut(to: "git reset --hard HEAD", at: path)
        try shellOut(to: "git clean -fd", at: path)
    }

    func stashChanges(at path: String, message: String?) throws {
        let stashCommand = if let message = message {
            "git stash push -m \"\(message)\""
        } else {
            "git stash push -m \"Alars auto-stash: \(Date().ISO8601Format())\""
        }
        try shellOut(to: stashCommand, at: path)
    }

    func createBranch(at path: String, name: String, commitChanges: Bool) throws {
        if commitChanges {
            try shellOut(to: "git add .", at: path)
            try shellOut(to: "git commit -m \"WIP: Auto-commit by Alars\"", at: path)
        }
        try shellOut(to: "git checkout -b \(name)", at: path)
    }

    func pullLatestChanges(at path: String, branch: String) throws {
        let currentBranch = try getCurrentBranch(at: path)
        if currentBranch != branch {
            try switchToBranch(at: path, branch: branch)
        }
        try shellOut(to: "git pull origin \(branch)", at: path)
    }

    func getCurrentBranch(at path: String) throws -> String {
        let output = try shellOut(to: "git rev-parse --abbrev-ref HEAD", at: path)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func switchToBranch(at path: String, branch: String) throws {
        try shellOut(to: "git checkout \(branch)", at: path)
    }
}