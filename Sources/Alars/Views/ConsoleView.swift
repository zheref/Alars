import Foundation
import Rainbow

/// Protocol defining console interaction interface
/// Allows for easy testing and different UI implementations
protocol ConsoleViewProtocol {
    func print(_ message: String)
    func printSuccess(_ message: String)
    func printError(_ message: String)
    func printWarning(_ message: String)
    func printInfo(_ message: String)
    func printProgress(_ message: String)
    func askConfirmation(_ question: String) -> Bool
    func askInput(_ prompt: String) -> String?
    func selectFromList<T: CustomStringConvertible>(_ prompt: String, options: [T]) -> T?
    func clear()
}

/// Default console view implementation using terminal I/O
/// Provides colorized output and interactive prompts
class ConsoleView: ConsoleViewProtocol {
    /// Prints a plain message to the console
    /// - Parameter message: Text to display
    func print(_ message: String) {
        Swift.print(message)
    }

    /// Prints a success message in green with checkmark
    /// - Parameter message: Success message to display
    func printSuccess(_ message: String) {
        Swift.print("✅ \(message)".green)
    }

    /// Prints an error message in red with X mark
    /// - Parameter message: Error message to display
    func printError(_ message: String) {
        Swift.print("❌ \(message)".red)
    }

    /// Prints a warning message in yellow with warning symbol
    /// - Parameter message: Warning message to display
    func printWarning(_ message: String) {
        Swift.print("⚠️  \(message)".yellow)
    }

    /// Prints an informational message in cyan with info symbol
    /// - Parameter message: Information to display
    func printInfo(_ message: String) {
        Swift.print("ℹ️  \(message)".cyan)
    }

    /// Prints a progress message in blue with hourglass symbol
    /// - Parameter message: Progress update to display
    func printProgress(_ message: String) {
        Swift.print("⏳ \(message)".blue)
    }

    /// Asks user for yes/no confirmation
    /// - Parameter question: Question to ask the user
    /// - Returns: true if user confirms, false otherwise
    func askConfirmation(_ question: String) -> Bool {
        Swift.print("\(question) [y/N]: ".yellow, terminator: "")
        let response = readLine()?.lowercased() ?? "n"
        return response == "y" || response == "yes"
    }

    /// Prompts user for text input
    /// - Parameter prompt: Prompt message to display
    /// - Returns: User's input or nil if cancelled
    func askInput(_ prompt: String) -> String? {
        Swift.print("\(prompt) ".cyan, terminator: "")
        return readLine()
    }

    /// Displays a numbered list and asks user to select an option
    /// - Parameters:
    ///   - prompt: Question or instruction to display
    ///   - options: Array of options to choose from
    /// - Returns: Selected option or nil if invalid choice
    func selectFromList<T: CustomStringConvertible>(_ prompt: String, options: [T]) -> T? {
        guard !options.isEmpty else { return nil }

        // Display the prompt and numbered options
        Swift.print("\n\(prompt)".bold)
        for (index, option) in options.enumerated() {
            Swift.print("  \(index + 1). \(option)")
        }

        Swift.print("\nEnter your choice (1-\(options.count)): ".cyan, terminator: "")

        // Parse and validate user input
        guard let input = readLine(),
              let choice = Int(input),
              choice > 0 && choice <= options.count else {
            printError("Invalid choice")
            return nil
        }

        return options[choice - 1]
    }

    /// Clears the terminal screen
    func clear() {
        // ANSI escape codes to clear screen and move cursor to top
        Swift.print("\u{001B}[2J\u{001B}[H")
    }
}