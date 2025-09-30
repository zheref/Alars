import Foundation

protocol ProjectServiceProtocol {
    func loadProjects() throws -> [Project]
    func validateProject(_ project: Project) throws
}

class ProjectService: ProjectServiceProtocol {
    private let fileManager = FileManager.default

    func loadProjects() throws -> [Project] {
        let projectsFilePath = fileManager.currentDirectoryPath.appending("/xprojects.json")

        guard fileManager.fileExists(atPath: projectsFilePath) else {
            throw AlarsError.projectsFileNotFound
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: projectsFilePath))
        let decoder = JSONDecoder()
        let projectsFile = try decoder.decode(ProjectsFile.self, from: data)

        return projectsFile.projects
    }

    func validateProject(_ project: Project) throws {
        let workingDirectory = project.absoluteWorkingDirectory

        guard fileManager.fileExists(atPath: workingDirectory) else {
            throw AlarsError.invalidWorkingDirectory(workingDirectory)
        }

        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: workingDirectory, isDirectory: &isDirectory)
        guard isDirectory.boolValue else {
            throw AlarsError.invalidWorkingDirectory("\(workingDirectory) is not a directory")
        }
    }
}