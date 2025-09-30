# Alars - Xcode Project Management CLI

A powerful command-line interface tool for managing multiple Xcode projects with ease. Alars allows you to perform common development operations across your iOS, macOS, watchOS, tvOS, and visionOS projects through an intuitive interactive interface.

## Features

- **Multi-Project Management**: Work with multiple Xcode projects from a single configuration file
- **Git Integration**: Clean, stash, branch, and update your repositories
- **Build & Test**: Build schemes and run tests with verbose output
- **Simulator Management**: Launch apps on specific simulators
- **Custom Commands**: Create command sequences for repetitive workflows
- **Interactive UI**: User-friendly menu system with colorful output

## Installation

### Building from Source

1. Clone the repository:
```bash
git clone <repository-url>
cd Alars
```

2. Build the project:
```bash
swift build -c release
```

3. Install the binary:
```bash
cp .build/release/alars /usr/local/bin/
```

Or build and run directly:
```bash
swift run alars
```

## Setup

### Initialize Configuration

Create an `xprojects.json` file in your workspace directory:

```bash
alars init
```

This interactive command will guide you through setting up your projects.

### Manual Configuration

Create an `xprojects.json` file with the following structure:

```json
{
  "projects": [
    {
      "name": "MyAwesomeApp",
      "workingDirectory": "~/Projects/MyAwesomeApp",
      "repositoryURL": "https://github.com/username/MyAwesomeApp.git",
      "configuration": {
        "defaultBranch": "main",
        "defaultScheme": "MyAwesomeApp",
        "defaultTestScheme": "MyAwesomeAppTests",
        "defaultSimulator": "iPhone 15",
        "savePreference": "stash"
      },
      "customCommands": [
        {
          "alias": "fresh-build",
          "description": "Clean, update, and build the project",
          "operations": [
            {
              "type": "clean_slate"
            },
            {
              "type": "update"
            },
            {
              "type": "build",
              "parameters": {
                "scheme": "MyAwesomeApp"
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### Configuration Fields

#### Project Fields
- `name`: Display name for the project
- `workingDirectory`: Path to the project (supports `~` for home directory)
- `repositoryURL`: (Optional) Git repository URL
- `configuration`: Project-specific settings
- `customCommands`: (Optional) Array of custom command sequences

#### Configuration Options
- `defaultBranch`: Main branch name (e.g., "main", "master")
- `defaultScheme`: (Optional) Default Xcode scheme for building
- `defaultTestScheme`: (Optional) Default scheme for running tests
- `defaultSimulator`: (Optional) Default simulator name
- `savePreference`: (Optional) "stash" or "branch" for saving uncommitted changes

#### Custom Commands
- `alias`: Command shortcut name
- `description`: What the command does
- `operations`: Array of operations to execute in sequence
  - `type`: Operation type (clean_slate, save, update, build, test, run)
  - `parameters`: (Optional) Operation-specific parameters

## Usage

### Interactive Mode

Run Alars from a directory containing `xprojects.json`:

```bash
alars
```

This opens an interactive menu where you can:
1. Select a project
2. Choose an operation or custom command
3. Follow the prompts

### Command Line Mode

#### List all projects:
```bash
alars list
```

#### Work with a specific project:
```bash
alars run --project MyAwesomeApp
```

#### Execute a specific operation:
```bash
alars run --project MyAwesomeApp --operation build
```

#### Run a custom command:
```bash
alars run --project MyAwesomeApp --command fresh-build
```

## Available Operations

### 1. Clean Slate
Resets the working directory to a clean state by discarding all uncommitted changes.
- Prompts for confirmation before discarding changes
- Runs `git reset --hard HEAD` and `git clean -fd`

### 2. Save
Saves uncommitted changes based on your preference:
- **Stash**: Creates a git stash with an optional message
- **Branch**: Creates a new branch and commits changes

### 3. Update
Pulls the latest changes from the configured default branch:
- Checks for uncommitted changes
- Optionally saves changes before updating
- Switches to default branch and pulls

### 4. Build
Builds the project with a selected scheme:
- Lists all available Xcode schemes
- Supports verbose output
- Uses default scheme if configured

### 5. Test
Runs test suites for the project:
- Auto-detects test schemes
- Displays test output
- Uses default test scheme if configured

### 6. Run
Launches the app on a simulator:
- Lists available simulators
- Shows simulator status (Booted/Shutdown)
- Uses default simulator if configured

## Custom Commands

Custom commands allow you to chain multiple operations together. For example:

```json
{
  "alias": "ci-build",
  "description": "Full CI build process",
  "operations": [
    { "type": "clean_slate" },
    { "type": "update" },
    { "type": "build", "parameters": { "scheme": "MyApp-CI" } },
    { "type": "test", "parameters": { "scheme": "MyAppTests" } }
  ]
}
```

Run with: `alars run --project MyApp --command ci-build`

## Requirements

- macOS 13.0 or later
- Xcode installed and configured
- Git installed
- Swift 5.9 or later

## Tips

1. **Working Directory Paths**: Use absolute paths or `~` for home directory
2. **Multiple Workspaces**: Create different `xprojects.json` files in different directories
3. **Verbose Builds**: Enable verbose output to diagnose build issues
4. **Simulator Management**: Ensure simulators are downloaded via Xcode before use

## Error Handling

Alars provides clear error messages for common issues:
- Missing `xprojects.json` file
- Invalid project configurations
- Git operation failures
- Build errors
- Simulator availability

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

[Add your license information here]