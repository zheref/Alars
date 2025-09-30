import XCTest
@testable import Alars

final class ProjectModelTests: XCTestCase {
    func testProjectInitialization() {
        let config = ProjectConfiguration(
            defaultBranch: "main",
            defaultScheme: "MyApp",
            defaultTestScheme: "MyAppTests",
            defaultSimulator: "iPhone 15",
            savePreference: .branch
        )

        let customCommand = CustomCommand(
            alias: "full-build",
            description: "Clean, update, and build",
            operations: [
                CustomCommand.Operation(type: .cleanSlate, parameters: nil),
                CustomCommand.Operation(type: .update, parameters: nil),
                CustomCommand.Operation(type: .build, parameters: ["scheme": "MyApp"])
            ]
        )

        let project = Project(
            name: "TestProject",
            workingDirectory: "~/Projects/Test",
            repositoryURL: "https://github.com/test/repo.git",
            configuration: config,
            customCommands: [customCommand]
        )

        XCTAssertEqual(project.name, "TestProject")
        XCTAssertEqual(project.workingDirectory, "~/Projects/Test")
        XCTAssertEqual(project.repositoryURL, "https://github.com/test/repo.git")
        XCTAssertEqual(project.configuration.defaultBranch, "main")
        XCTAssertEqual(project.configuration.defaultScheme, "MyApp")
        XCTAssertEqual(project.configuration.defaultTestScheme, "MyAppTests")
        XCTAssertEqual(project.configuration.defaultSimulator, "iPhone 15")
        XCTAssertEqual(project.configuration.savePreference, .branch)
        XCTAssertEqual(project.customCommands?.count, 1)
        XCTAssertEqual(project.customCommands?[0].alias, "full-build")
        XCTAssertEqual(project.customCommands?[0].operations.count, 3)
    }

    func testAbsoluteWorkingDirectory() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

        let project1 = createTestProject(workingDirectory: "~/Projects/Test")
        XCTAssertTrue(project1.absoluteWorkingDirectory.starts(with: homeDirectory))
        XCTAssertTrue(project1.absoluteWorkingDirectory.contains("Projects/Test"))

        let project2 = createTestProject(workingDirectory: "/absolute/path")
        XCTAssertEqual(project2.absoluteWorkingDirectory, "/absolute/path")

        let project3 = createTestProject(workingDirectory: "relative/path")
        XCTAssertTrue(project3.absoluteWorkingDirectory.contains("relative/path"))
        XCTAssertTrue(project3.absoluteWorkingDirectory.starts(with: "/"))
    }

    func testProjectsFileDecoding() throws {
        let json = """
        {
            "projects": [
                {
                    "name": "App1",
                    "workingDirectory": "/path/to/app1",
                    "configuration": {
                        "defaultBranch": "main"
                    }
                },
                {
                    "name": "App2",
                    "workingDirectory": "/path/to/app2",
                    "repositoryURL": "https://github.com/test/app2.git",
                    "configuration": {
                        "defaultBranch": "develop",
                        "defaultScheme": "App2-Dev"
                    },
                    "customCommands": [
                        {
                            "alias": "quick-test",
                            "description": "Run tests quickly",
                            "operations": [
                                {
                                    "type": "test",
                                    "parameters": {
                                        "scheme": "App2Tests"
                                    }
                                }
                            ]
                        }
                    ]
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let projectsFile = try decoder.decode(ProjectsFile.self, from: data)

        XCTAssertEqual(projectsFile.projects.count, 2)

        let app1 = projectsFile.projects[0]
        XCTAssertEqual(app1.name, "App1")
        XCTAssertEqual(app1.workingDirectory, "/path/to/app1")
        XCTAssertNil(app1.repositoryURL)
        XCTAssertEqual(app1.configuration.defaultBranch, "main")
        XCTAssertNil(app1.configuration.defaultScheme)
        XCTAssertNil(app1.customCommands)

        let app2 = projectsFile.projects[1]
        XCTAssertEqual(app2.name, "App2")
        XCTAssertEqual(app2.workingDirectory, "/path/to/app2")
        XCTAssertEqual(app2.repositoryURL, "https://github.com/test/app2.git")
        XCTAssertEqual(app2.configuration.defaultBranch, "develop")
        XCTAssertEqual(app2.configuration.defaultScheme, "App2-Dev")
        XCTAssertEqual(app2.customCommands?.count, 1)
        XCTAssertEqual(app2.customCommands?[0].alias, "quick-test")
    }

    func testOperationTypeAllCases() {
        let allCases = OperationType.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.cleanSlate))
        XCTAssertTrue(allCases.contains(.save))
        XCTAssertTrue(allCases.contains(.update))
        XCTAssertTrue(allCases.contains(.build))
        XCTAssertTrue(allCases.contains(.test))
        XCTAssertTrue(allCases.contains(.run))
    }

    private func createTestProject(workingDirectory: String) -> Project {
        return Project(
            name: "Test",
            workingDirectory: workingDirectory,
            repositoryURL: nil,
            configuration: ProjectConfiguration(
                defaultBranch: "main",
                defaultScheme: nil,
                defaultTestScheme: nil,
                defaultSimulator: nil,
                savePreference: nil
            ),
            customCommands: nil
        )
    }
}