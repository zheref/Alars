import Foundation
import Rainbow

/// Protocol defining menu display and interaction interface
protocol MenuViewProtocol {
    func showMainMenu()
    func showProjectMenu(for project: Project) -> MenuOption?
    func selectProject(from projects: [Project]) -> Project?
    func selectOperation() -> OperationType?
}

/// Represents user's menu selection
enum MenuOption {
    case operation(OperationType)  // User selected a standard operation
    case customCommand(String)     // User selected a custom command by alias
    case back                      // User wants to go back to project selection
    case exit                      // User wants to exit the application
}

/// Menu view implementation providing interactive project and operation selection
class MenuView: MenuViewProtocol {
    /// Console view dependency for user interaction
    private let consoleView: ConsoleViewProtocol

    /// Initializes the menu view with console dependency
    /// - Parameter consoleView: Console view for user interaction
    init(consoleView: ConsoleViewProtocol = ConsoleView()) {
        self.consoleView = consoleView
    }

    /// Displays the main application header
    /// Clears screen and shows the Alars CLI banner
    func showMainMenu() {
        consoleView.clear()
        let header = """
        ╔════════════════════════════════════╗
        ║           ALARS CLI                ║
        ║   Xcode Project Manager            ║
        ╚════════════════════════════════════╝
        """.cyan.bold

        consoleView.print(header)
        consoleView.print("")
    }

    /// Displays the project menu with available operations and custom commands
    /// - Parameter project: Project to show menu for
    /// - Returns: User's menu selection or nil if invalid
    func showProjectMenu(for project: Project) -> MenuOption? {
        // Display project header
        consoleView.print("\n" + "═".repeated(40).cyan)
        consoleView.print("Project: \(project.name)".bold.green)
        consoleView.print("Directory: \(project.workingDirectory)".dim)
        consoleView.print("═".repeated(40).cyan + "\n")

        // Build the menu with standard operations
        var menuItems: [String] = []
        menuItems.append("📦 Clean Slate - Reset working directory")
        menuItems.append("💾 Save - Stash or branch uncommitted changes")
        menuItems.append("🔄 Update - Pull latest changes")
        menuItems.append("🔨 Build - Build the project")
        menuItems.append("🧪 Test - Run tests")
        menuItems.append("▶️  Run - Launch the app")

        // Add custom commands if any are defined
        if let customCommands = project.customCommands, !customCommands.isEmpty {
            menuItems.append("─".repeated(30).dim)
            menuItems.append("Custom Commands:".bold)
            for command in customCommands {
                menuItems.append("⚡ \(command.alias) - \(command.description)")
            }
        }

        menuItems.append("─".repeated(30).dim)
        menuItems.append("🔙 Back to project selection")
        menuItems.append("🚪 Exit")

        for (index, item) in menuItems.enumerated() {
            if item.starts(with: "─") || item == "Custom Commands:".bold {
                consoleView.print(item)
            } else {
                consoleView.print("  \(index + 1). \(item)")
            }
        }

        Swift.print("\nSelect an option: ".cyan, terminator: "")

        guard let input = readLine() else {
            return .exit
        }

        if input.lowercased() == "exit" || input.lowercased() == "quit" {
            return .exit
        }

        guard let choice = Int(input) else {
            if let customCommands = project.customCommands {
                if customCommands.contains(where: { $0.alias == input }) {
                    return .customCommand(input)
                }
            }
            consoleView.printError("Invalid choice")
            return nil
        }

        let operationCount = 6
        let customCommandsCount = project.customCommands?.count ?? 0

        switch choice {
        case 1: return .operation(.cleanSlate)
        case 2: return .operation(.save)
        case 3: return .operation(.update)
        case 4: return .operation(.build)
        case 5: return .operation(.test)
        case 6: return .operation(.run)
        case 7...operationCount + customCommandsCount where customCommandsCount > 0:
            let commandIndex = choice - operationCount - 1
            if let command = project.customCommands?[commandIndex] {
                return .customCommand(command.alias)
            }
            return nil
        case operationCount + customCommandsCount + 1:
            return .back
        case operationCount + customCommandsCount + 2:
            return .exit
        default:
            consoleView.printError("Invalid choice")
            return nil
        }
    }

    /// Displays project selection menu
    /// - Parameter projects: Array of available projects
    /// - Returns: Selected project or nil if user exits
    func selectProject(from projects: [Project]) -> Project? {
        consoleView.print("\n" + "Available Projects:".bold.green)
        consoleView.print("─".repeated(40).dim)

        for (index, project) in projects.enumerated() {
            consoleView.print("  \(index + 1). \(project.name.bold) - \(project.workingDirectory.dim)")
        }

        consoleView.print("─".repeated(40).dim)
        consoleView.print("  0. Exit")

        Swift.print("\nSelect a project: ".cyan, terminator: "")

        guard let input = readLine(), let choice = Int(input) else {
            consoleView.printError("Invalid choice")
            return nil
        }

        if choice == 0 {
            return nil
        }

        guard choice > 0 && choice <= projects.count else {
            consoleView.printError("Invalid project selection")
            return nil
        }

        return projects[choice - 1]
    }

    /// Displays operation selection menu (used for direct operation selection)
    /// - Returns: Selected operation type or nil if cancelled
    func selectOperation() -> OperationType? {
        let options = OperationType.allCases
        let selected = consoleView.selectFromList("Select an operation:", options: options)
        return selected
    }
}

/// Extension to repeat strings for UI formatting
extension String {
    /// Creates a string by repeating this string a specified number of times
    /// - Parameter count: Number of times to repeat the string
    /// - Returns: New string with repeated content
    func repeated(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}