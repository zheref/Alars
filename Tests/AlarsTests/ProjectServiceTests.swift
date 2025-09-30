import XCTest
@testable import Alars

final class ProjectServiceTests: XCTestCase {
    var sut: ProjectService!
    var testDirectory: URL!

    override func setUp() {
        super.setUp()
        sut = ProjectService()
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        FileManager.default.changeCurrentDirectoryPath(testDirectory.path)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testDirectory)
        super.tearDown()
    }

    func testLoadProjectsThrowsErrorWhenFileNotFound() {
        XCTAssertThrowsError(try sut.loadProjects()) { error in
            XCTAssertTrue(error is AlarsError)
            if let alarsError = error as? AlarsError {
                switch alarsError {
                case .projectsFileNotFound:
                    XCTAssertTrue(true)
                default:
                    XCTFail("Expected projectsFileNotFound error")
                }
            }
        }
    }

    func testLoadProjectsSuccessfully() throws {
        let projectsJSON = """
        {
            "projects": [
                {
                    "name": "TestApp",
                    "workingDirectory": "~/Projects/TestApp",
                    "repositoryURL": "https://github.com/test/app.git",
                    "configuration": {
                        "defaultBranch": "main",
                        "defaultScheme": "TestApp",
                        "savePreference": "stash"
                    }
                }
            ]
        }
        """

        let fileURL = testDirectory.appendingPathComponent("xprojects.json")
        try projectsJSON.write(to: fileURL, atomically: true, encoding: .utf8)

        let projects = try sut.loadProjects()

        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].name, "TestApp")
        XCTAssertEqual(projects[0].workingDirectory, "~/Projects/TestApp")
        XCTAssertEqual(projects[0].configuration.defaultBranch, "main")
        XCTAssertEqual(projects[0].configuration.savePreference, .stash)
    }

    func testValidateProjectThrowsErrorForInvalidDirectory() {
        let project = Project(
            name: "Invalid",
            workingDirectory: "/nonexistent/path",
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

        XCTAssertThrowsError(try sut.validateProject(project)) { error in
            XCTAssertTrue(error is AlarsError)
            if let alarsError = error as? AlarsError {
                switch alarsError {
                case .invalidWorkingDirectory:
                    XCTAssertTrue(true)
                default:
                    XCTFail("Expected invalidWorkingDirectory error")
                }
            }
        }
    }

    func testValidateProjectSucceedsForValidDirectory() throws {
        let project = Project(
            name: "Valid",
            workingDirectory: testDirectory.path,
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

        XCTAssertNoThrow(try sut.validateProject(project))
    }
}