import ArgumentParser
import Foundation

/// Main entry point for the Alars CLI application
/// This is where the Swift runtime starts execution
@main
struct AlarsCommand: AsyncParsableCommand {
    /// Configuration for the main command and its subcommands
    /// Defines the CLI structure, version, and default behavior
    static let configuration = CommandConfiguration(
        commandName: "alars",
        abstract: "A powerful Xcode project management CLI",
        version: "1.0.0",
        subcommands: [
            RunCommand.self,        // Interactive mode and direct operations
            ListCommand.self,       // List all configured projects
            InitCommand.self,       // Initialize new configuration
            QuickCommand.self,      // Quick sequence execution
            ChangesetCommand.self,  // Changeset management
            BuildCommand.self,      // Build shortcut
            TestCommand.self,       // Test shortcut
            CleanCommand.self,      // Clean slate shortcut
            ResetCommand.self,      // Reset shortcut
            SaveCommand.self,       // Save shortcut
            UpdateCommand.self      // Update shortcut
        ],
        defaultSubcommand: RunCommand.self  // Run interactive mode by default
    )
}
