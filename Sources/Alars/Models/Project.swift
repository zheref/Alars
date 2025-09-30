import Foundation

struct Project: Codable, Equatable {
    let name: String
    let workingDirectory: String
    let repositoryURL: String?
    let configuration: ProjectConfiguration
    let customCommands: [CustomCommand]?

    var absoluteWorkingDirectory: String {
        if workingDirectory.starts(with: "/") {
            return workingDirectory
        } else if workingDirectory.starts(with: "~") {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
            return workingDirectory.replacingOccurrences(of: "~", with: homeDirectory)
        } else {
            return FileManager.default.currentDirectoryPath.appending("/\(workingDirectory)")
        }
    }
}

struct ProjectConfiguration: Codable, Equatable {
    let defaultBranch: String
    let defaultScheme: String?
    let defaultTestScheme: String?
    let defaultSimulator: String?
    let savePreference: SavePreference?

    enum SavePreference: String, Codable {
        case stash
        case branch
    }
}

struct CustomCommand: Codable, Equatable {
    let alias: String
    let description: String
    let operations: [Operation]

    struct Operation: Codable, Equatable {
        let type: OperationType
        let parameters: [String: String]?
    }
}

enum OperationType: String, Codable, CaseIterable, CustomStringConvertible {
    case cleanSlate = "clean_slate"
    case save
    case update
    case build
    case test
    case run

    var description: String {
        switch self {
        case .cleanSlate: return "Clean Slate"
        case .save: return "Save"
        case .update: return "Update"
        case .build: return "Build"
        case .test: return "Test"
        case .run: return "Run"
        }
    }
}

struct ProjectsFile: Codable {
    let projects: [Project]
}