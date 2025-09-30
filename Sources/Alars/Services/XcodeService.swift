import Foundation
import ShellOut

/// Protocol defining Xcode build and run operations
protocol XcodeServiceProtocol {
    func listSchemes(at projectPath: String) throws -> [String]
    func buildProject(at path: String, scheme: String, verbose: Bool) throws -> String
    func runTests(at path: String, scheme: String) throws -> String
    func listSimulators() throws -> [Simulator]
    func runProject(at path: String, scheme: String, simulator: String?) throws
}

/// Represents an iOS/tvOS/watchOS simulator
struct Simulator: Equatable {
    /// Simulator name (e.g., "iPhone 15")
    let name: String

    /// Unique device identifier
    let udid: String

    /// Current state ("Booted", "Shutdown", etc.)
    let state: String

    /// Platform identifier (e.g., "iOS-17-0")
    let platform: String

    /// Formatted display name for UI presentation
    var displayName: String {
        "\(name) (\(platform)) - \(state)"
    }
}

/// Service responsible for Xcode-related operations
/// Handles building, testing, and running Xcode projects
class XcodeService: XcodeServiceProtocol {
    /// Lists all available schemes in an Xcode project or workspace
    /// - Parameter projectPath: Path to the directory containing the Xcode project
    /// - Returns: Array of scheme names
    /// - Throws: AlarsError if no project found or xcodebuild fails
    func listSchemes(at projectPath: String) throws -> [String] {
        // Find project or workspace files in the directory
        let projectFiles = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: projectPath),
                                                                      includingPropertiesForKeys: nil)

        let xcodeproj = projectFiles.first { $0.pathExtension == "xcodeproj" }
        let xcworkspace = projectFiles.first { $0.pathExtension == "xcworkspace" }

        let projectArg: String
        if let workspace = xcworkspace {
            projectArg = "-workspace \(workspace.lastPathComponent)"
        } else if let project = xcodeproj {
            projectArg = "-project \(project.lastPathComponent)"
        } else {
            throw AlarsError.xcodeBuildFailed("No Xcode project or workspace found")
        }

        let output = try shellOut(to: "xcodebuild \(projectArg) -list", at: projectPath)

        var schemes: [String] = []
        var inSchemesSection = false

        for line in output.split(separator: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine == "Schemes:" {
                inSchemesSection = true
            } else if inSchemesSection {
                if trimmedLine.isEmpty {
                    break
                }
                schemes.append(trimmedLine)
            }
        }

        return schemes
    }

    func buildProject(at path: String, scheme: String, verbose: Bool) throws -> String {
        let projectFiles = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path),
                                                                      includingPropertiesForKeys: nil)

        let xcodeproj = projectFiles.first { $0.pathExtension == "xcodeproj" }
        let xcworkspace = projectFiles.first { $0.pathExtension == "xcworkspace" }

        let projectArg: String
        if let workspace = xcworkspace {
            projectArg = "-workspace \(workspace.lastPathComponent)"
        } else if let project = xcodeproj {
            projectArg = "-project \(project.lastPathComponent)"
        } else {
            throw AlarsError.xcodeBuildFailed("No Xcode project or workspace found")
        }

        let verboseFlag = verbose ? "" : "-quiet"
        let buildCommand = "xcodebuild \(projectArg) -scheme \(scheme) -configuration Debug -sdk iphonesimulator build \(verboseFlag)"

        return try shellOut(to: buildCommand, at: path)
    }

    func runTests(at path: String, scheme: String) throws -> String {
        let projectFiles = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path),
                                                                      includingPropertiesForKeys: nil)

        let xcodeproj = projectFiles.first { $0.pathExtension == "xcodeproj" }
        let xcworkspace = projectFiles.first { $0.pathExtension == "xcworkspace" }

        let projectArg: String
        if let workspace = xcworkspace {
            projectArg = "-workspace \(workspace.lastPathComponent)"
        } else if let project = xcodeproj {
            projectArg = "-project \(project.lastPathComponent)"
        } else {
            throw AlarsError.xcodeBuildFailed("No Xcode project or workspace found")
        }

        let testCommand = "xcodebuild \(projectArg) -scheme \(scheme) -sdk iphonesimulator test"
        return try shellOut(to: testCommand, at: path)
    }

    func listSimulators() throws -> [Simulator] {
        let output = try shellOut(to: "xcrun simctl list devices available -j")
        guard let data = output.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            return []
        }

        var simulators: [Simulator] = []
        for (platform, deviceList) in devices {
            let cleanPlatform = platform.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
            for device in deviceList {
                if let name = device["name"] as? String,
                   let udid = device["udid"] as? String,
                   let state = device["state"] as? String {
                    simulators.append(Simulator(name: name, udid: udid, state: state, platform: cleanPlatform))
                }
            }
        }

        return simulators.sorted { $0.name < $1.name }
    }

    func runProject(at path: String, scheme: String, simulator: String?) throws {
        let projectFiles = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path),
                                                                      includingPropertiesForKeys: nil)

        let xcodeproj = projectFiles.first { $0.pathExtension == "xcodeproj" }
        let xcworkspace = projectFiles.first { $0.pathExtension == "xcworkspace" }

        let projectArg: String
        if let workspace = xcworkspace {
            projectArg = "-workspace \(workspace.lastPathComponent)"
        } else if let project = xcodeproj {
            projectArg = "-project \(project.lastPathComponent)"
        } else {
            throw AlarsError.xcodeBuildFailed("No Xcode project or workspace found")
        }

        var runCommand = "xcodebuild \(projectArg) -scheme \(scheme) -configuration Debug"

        if let simulatorId = simulator {
            runCommand += " -destination \"platform=iOS Simulator,id=\(simulatorId)\""
        } else {
            runCommand += " -destination \"platform=iOS Simulator,name=iPhone 15\""
        }

        runCommand += " run"

        try shellOut(to: runCommand, at: path)
    }
}