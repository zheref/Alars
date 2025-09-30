# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Alars is a Swift Package Manager-based command-line tool for managing multiple Xcode projects. It provides an interactive interface for performing common development operations like building, testing, Git operations, and running apps on simulators.

## Build Commands

Build the project:
```bash
swift build
```

Build for release:
```bash
swift build -c release
```

Run the CLI:
```bash
swift run alars
```

Run tests:
```bash
swift test
```

## Project Structure

- `Sources/Alars/` - Main source code following MVC pattern
  - `Commands/` - ArgumentParser command definitions
  - `Controllers/` - Business logic for operations
  - `Models/` - Data structures and types
  - `Services/` - External integrations (Git, Xcode)
  - `Views/` - Console UI components
- `Tests/AlarsTests/` - Unit tests
- `Package.swift` - Swift Package Manager configuration

## Architecture

The project follows MVC pattern with clear separation:
- **Models**: Define data structures for projects, configurations, and operations
- **Views**: Handle all console I/O and user interactions
- **Controllers**: Orchestrate operations and coordinate between services
- **Services**: Encapsulate external tool interactions (Git, Xcode, etc.)

## Key Dependencies

- `swift-argument-parser` - CLI argument parsing
- `Rainbow` - Terminal colors
- `ShellOut` - Shell command execution