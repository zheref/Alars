import Foundation

/// Service responsible for generating error reports
class ErrorReportService {
    private let fileManager = FileManager.default

    /// Generates a comprehensive error report file
    /// - Parameters:
    ///   - operation: The operation that failed (build, test, etc.)
    ///   - project: The project that was being operated on
    ///   - error: The error that occurred
    ///   - output: Any output from the failed operation
    /// - Returns: Path to the generated report file
    func generateErrorReport(
        operation: String,
        project: Project,
        error: Error,
        output: String? = nil
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "\(project.name)-report-\(timestamp).log"
        let filepath = fileManager.currentDirectoryPath.appending("/\(filename)")

        var reportContent = """
        ═══════════════════════════════════════════════════════════════
        ALARS ERROR REPORT
        ═══════════════════════════════════════════════════════════════

        Generated: \(Date())
        Operation: \(operation)
        Project: \(project.name)
        Working Directory: \(project.workingDirectory)
        Absolute Path: \(project.absoluteWorkingDirectory)

        ───────────────────────────────────────────────────────────────
        ERROR DETAILS
        ───────────────────────────────────────────────────────────────

        Error Type: \(type(of: error))
        Error Description: \(error.localizedDescription)

        """

        if let output = output, !output.isEmpty {
            reportContent += """

            ───────────────────────────────────────────────────────────────
            OPERATION OUTPUT
            ───────────────────────────────────────────────────────────────

            \(output)

            """
        }

        reportContent += """

        ───────────────────────────────────────────────────────────────
        SYSTEM INFORMATION
        ───────────────────────────────────────────────────────────────

        Current Directory: \(fileManager.currentDirectoryPath)
        User: \(NSUserName())
        Home Directory: \(NSHomeDirectory())

        ───────────────────────────────────────────────────────────────
        PROJECT CONFIGURATION
        ───────────────────────────────────────────────────────────────

        Default Branch: \(project.configuration.defaultBranch)
        Default Scheme: \(project.configuration.defaultScheme ?? "None")
        Default Test Scheme: \(project.configuration.defaultTestScheme ?? "None")
        Default Simulator: \(project.configuration.defaultSimulator ?? "None")
        Save Preference: \(project.configuration.savePreference?.rawValue ?? "None")

        """

        if let customCommands = project.customCommands, !customCommands.isEmpty {
            reportContent += """

            ───────────────────────────────────────────────────────────────
            CUSTOM COMMANDS
            ───────────────────────────────────────────────────────────────

            """
            for command in customCommands {
                reportContent += """
                - \(command.alias): \(command.description)
                  Operations: \(command.operations.map { $0.type.rawValue }.joined(separator: ", "))

                """
            }
        }

        reportContent += """
        ═══════════════════════════════════════════════════════════════
        END OF REPORT
        ═══════════════════════════════════════════════════════════════
        """

        do {
            try reportContent.write(toFile: filepath, atomically: true, encoding: .utf8)
            return filepath
        } catch {
            // If we can't write the report file, just return the error
            return "Failed to write report: \(error.localizedDescription)"
        }
    }
}
