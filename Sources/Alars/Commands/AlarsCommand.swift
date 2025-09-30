import ArgumentParser
import Foundation

@main
struct AlarsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "alars",
        abstract: "A powerful Xcode project management CLI",
        version: "1.0.0",
        subcommands: [
            RunCommand.self,
            ListCommand.self,
            InitCommand.self
        ],
        defaultSubcommand: RunCommand.self
    )
}