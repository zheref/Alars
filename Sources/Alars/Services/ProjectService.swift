import Foundation

/// Protocol defining project loading and validation operations
protocol ProjectServiceProtocol {
    func loadProjects() throws -> [Project]
    func validateProject(_ project: Project) throws
}

/// Service responsible for loading and validating project configurations
/// Handles reading the xprojects.json file and validating project paths
class ProjectService: ProjectServiceProtocol {
    private let fileManager = FileManager.default

    /// Loads all projects from the xprojects.json file in the current directory
    /// - Returns: Array of Project configurations
    /// - Throws: AlarsError if file not found or invalid JSON
    func loadProjects() throws -> [Project] {
        let projectsFilePath = fileManager.currentDirectoryPath.appending("/xprojects.json")

        guard fileManager.fileExists(atPath: projectsFilePath) else {
            throw AlarsError.projectsFileNotFound
        }

        // Read and decode the JSON configuration file
        let data = try Data(contentsOf: URL(fileURLWithPath: projectsFilePath))
        let decoder = JSONDecoder()
        let projectsFile = try decoder.decode(ProjectsFile.self, from: data)

        return projectsFile.projects
    }

    /// Validates that a project's working directory exists and is accessible
    /// - Parameter project: The project to validate
    /// - Throws: AlarsError if directory doesn't exist or is not a directory
    func validateProject(_ project: Project) throws {
        let workingDirectory = project.absoluteWorkingDirectory

        // Check if the directory exists
        guard fileManager.fileExists(atPath: workingDirectory) else {
            throw AlarsError.invalidWorkingDirectory(workingDirectory)
        }

        // Verify it's actually a directory and not a file
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: workingDirectory, isDirectory: &isDirectory)
        guard isDirectory.boolValue else {
            throw AlarsError.invalidWorkingDirectory("\(workingDirectory) is not a directory")
        }
    }
}