# Contributing to Alars

Thank you for your interest in contributing to Alars! This document provides guidelines and instructions for extending the CLI with new operations and features.

## Application Entry Point

The Alars application starts execution in the `AlarsCommand` struct in `Sources/Alars/Commands/AlarsCommand.swift`. This is marked with the `@main` attribute, making it the Swift runtime's entry point.

### Execution Flow

1. **Main Entry**: `AlarsCommand` serves as the root command
2. **Subcommand Routing**: ArgumentParser routes to one of three subcommands:
   - `RunCommand` (default) - Interactive mode and direct operations
   - `ListCommand` - List all configured projects
   - `InitCommand` - Initialize new xprojects.json configuration
3. **Service Initialization**: Each command creates its required services
4. **Operation Execution**: Services coordinate to execute the requested operations

### Key Components

- **Commands Layer**: ArgumentParser-based CLI interface (`Commands/`)
- **Controllers Layer**: Business logic orchestration (`Controllers/`)
- **Services Layer**: External tool interactions (`Services/`)
- **Models Layer**: Data structures and types (`Models/`)
- **Views Layer**: User interface and console output (`Views/`)

## Architecture Overview

Alars follows the MVC (Model-View-Controller) pattern:

```
Sources/Alars/
├── Commands/          # ArgumentParser command definitions
├── Controllers/       # Business logic and operation orchestration
├── Models/           # Data structures and types
├── Services/         # External interactions (Git, Xcode, etc.)
├── Views/            # User interface and console output
└── Utilities/        # Helper functions and extensions
```

## Adding a New Operation

### Step 1: Define the Operation Type

Add your new operation to the `OperationType` enum in `Models/Project.swift`:

```swift
enum OperationType: String, Codable, CaseIterable {
    case cleanSlate = "clean_slate"
    case save
    case update
    case build
    case test
    case run
    case yourNewOperation = "your_new_operation"  // Add this
}
```

### Step 2: Create or Extend a Service

If your operation requires new external interactions, create a service in `Services/`:

```swift
// Services/YourService.swift
import Foundation

protocol YourServiceProtocol {
    func performAction(at path: String) throws -> String
}

class YourService: YourServiceProtocol {
    func performAction(at path: String) throws -> String {
        // Implementation using ShellOut or other methods
        return try shellOut(to: "your-command", at: path)
    }
}
```

### Step 3: Implement the Operation Controller

Add the operation logic to `Controllers/OperationController.swift`:

```swift
// In executeOperation method's switch statement:
case .yourNewOperation:
    return try await executeYourNewOperation(at: workingDirectory, project: project, parameters: parameters)

// Add the implementation method:
private func executeYourNewOperation(at path: String, project: Project, parameters: [String: String]?) async throws -> OperationResult {
    consoleView.printInfo("Starting your new operation...")

    // Your operation logic here
    let service = YourService()
    let result = try service.performAction(at: path)

    return .success("Your operation completed: \(result)")
}
```

### Step 4: Update the Menu

Modify `Views/MenuView.swift` to include your operation in the menu:

```swift
// In showProjectMenu method:
menuItems.append("🎯 Your Operation - Description of what it does")

// Update the switch statement:
case 7: return .operation(.yourNewOperation)
// Adjust other case numbers accordingly
```

### Step 5: Add Tests

Create tests for your new functionality:

```swift
// Tests/AlarsTests/YourOperationTests.swift
import XCTest
@testable import Alars

final class YourOperationTests: XCTestCase {
    func testYourOperation() throws {
        // Test your operation logic
    }
}
```

## Adding Custom Parameters

Operations can accept parameters for flexibility:

```swift
// In your operation implementation:
private func executeYourOperation(at path: String, project: Project, parameters: [String: String]?) async throws -> OperationResult {
    let customParam = parameters?["yourParam"] ?? "defaultValue"
    // Use the parameter in your logic
}
```

## Adding Interactive Options

Use the `ConsoleView` protocol for user interaction:

```swift
// Ask for confirmation
let proceed = consoleView.askConfirmation("Continue with operation?")

// Get user input
let value = consoleView.askInput("Enter a value:")

// Select from options
let options = ["Option 1", "Option 2", "Option 3"]
let selected = consoleView.selectFromList("Choose an option:", options: options)
```

## Service Integration Guidelines

### Git Operations

Use the `GitService` for Git-related operations:

```swift
let gitService = GitService()
let isClean = try gitService.isCleanWorkingDirectory(at: path)
try gitService.switchToBranch(at: path, branch: "feature-branch")
```

### Xcode Operations

Use the `XcodeService` for Xcode-related operations:

```swift
let xcodeService = XcodeService()
let schemes = try xcodeService.listSchemes(at: path)
let output = try xcodeService.buildProject(at: path, scheme: scheme, verbose: true)
```

## Error Handling

Define custom errors in `Models/OperationResult.swift`:

```swift
enum AlarsError: LocalizedError {
    case yourNewError(String)

    var errorDescription: String? {
        switch self {
        case .yourNewError(let message):
            return "Your error: \(message)"
        // ... other cases
        }
    }
}
```

## Console Output Guidelines

Use appropriate console methods for different message types:

```swift
consoleView.printSuccess("Operation completed!")      // ✅ Green
consoleView.printError("Operation failed")            // ❌ Red
consoleView.printWarning("Be careful")                // ⚠️  Yellow
consoleView.printInfo("Information")                  // ℹ️  Cyan
consoleView.printProgress("Working...")               // ⏳ Blue
```

## Testing Your Changes

Run tests locally:

```bash
swift test
```

Build and test the CLI:

```bash
swift build
swift run alars
```

Test with a sample configuration:

```bash
# Create a test xprojects.json
swift run alars init

# Test your new operation
swift run alars run --project TestProject --operation your_new_operation
```

## Debugging in Xcode

The project is configured to open in Xcode for debugging:

1. **Open in Xcode**: Double-click `Package.swift` or run `open Package.swift`
2. **Set Arguments**: Edit the "alars" scheme to set command line arguments
3. **Set Breakpoints**: Use the full Xcode debugging experience
4. **Working Directory**: The scheme is configured to use the project directory as working directory

### Common Debug Arguments

- `--help` - Show help (default in scheme)
- `list` - List projects
- `init` - Initialize configuration
- `run --project ProjectName --operation build` - Direct operation

### Debugging Tips

- Set breakpoints in `AlarsCommand.swift` to trace command routing
- Use `RunCommand.swift` breakpoints for interactive flow debugging
- Service classes are where external tool interactions happen
- View classes handle all user input/output

## Code Style Guidelines

1. **Swift Conventions**: Follow standard Swift naming conventions
2. **Protocol-Oriented**: Define protocols for services and major components
3. **Dependency Injection**: Pass dependencies through initializers
4. **Error Handling**: Use proper error types and provide meaningful messages
5. **Documentation**: Add comments for complex logic
6. **Testability**: Write testable code with clear separation of concerns

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-operation`
3. Make your changes following the guidelines above
4. Add tests for your changes
5. Ensure all tests pass: `swift test`
6. Commit with clear messages: `git commit -m "Add new operation: description"`
7. Push to your fork: `git push origin feature/your-operation`
8. Create a pull request with:
   - Clear description of the changes
   - Any new configuration requirements
   - Example usage
   - Test coverage information

## Common Patterns

### Adding a Confirmable Operation

```swift
private func executeDestructiveOperation() async throws -> OperationResult {
    let confirmed = consoleView.askConfirmation("This will delete data. Continue?")
    guard confirmed else {
        return .cancelled
    }
    // Proceed with operation
}
```

### Progress Reporting

```swift
private func executeLongOperation() async throws -> OperationResult {
    consoleView.printProgress("Step 1 of 3: Preparing...")
    // Step 1 logic

    consoleView.printProgress("Step 2 of 3: Processing...")
    // Step 2 logic

    consoleView.printProgress("Step 3 of 3: Finalizing...")
    // Step 3 logic

    return .success("Operation completed in 3 steps")
}
```

### Handling Optional Configuration

```swift
private func executeConfigurableOperation(project: Project) async throws -> OperationResult {
    let config = project.configuration
    let value = config.customValue ?? "default"
    // Use the configuration value
}
```

## Questions and Support

If you have questions about contributing:

1. Check existing issues and pull requests
2. Open a new issue for discussion
3. Join our community discussions

Thank you for contributing to Alars!