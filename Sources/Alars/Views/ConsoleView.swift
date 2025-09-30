import Foundation
import Rainbow

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

class ConsoleView: ConsoleViewProtocol {
    func print(_ message: String) {
        Swift.print(message)
    }

    func printSuccess(_ message: String) {
        Swift.print("✅ \(message)".green)
    }

    func printError(_ message: String) {
        Swift.print("❌ \(message)".red)
    }

    func printWarning(_ message: String) {
        Swift.print("⚠️  \(message)".yellow)
    }

    func printInfo(_ message: String) {
        Swift.print("ℹ️  \(message)".cyan)
    }

    func printProgress(_ message: String) {
        Swift.print("⏳ \(message)".blue)
    }

    func askConfirmation(_ question: String) -> Bool {
        Swift.print("\(question) [y/N]: ".yellow, terminator: "")
        let response = readLine()?.lowercased() ?? "n"
        return response == "y" || response == "yes"
    }

    func askInput(_ prompt: String) -> String? {
        Swift.print("\(prompt) ".cyan, terminator: "")
        return readLine()
    }

    func selectFromList<T: CustomStringConvertible>(_ prompt: String, options: [T]) -> T? {
        guard !options.isEmpty else { return nil }

        Swift.print("\n\(prompt)".bold)
        for (index, option) in options.enumerated() {
            Swift.print("  \(index + 1). \(option)")
        }

        Swift.print("\nEnter your choice (1-\(options.count)): ".cyan, terminator: "")

        guard let input = readLine(),
              let choice = Int(input),
              choice > 0 && choice <= options.count else {
            printError("Invalid choice")
            return nil
        }

        return options[choice - 1]
    }

    func clear() {
        Swift.print("\u{001B}[2J\u{001B}[H")
    }
}