<div align="center">

# ⟨ ⟩ ALARS: The Eternal Project Forge ⟨ ⟩

### *"In the vast cosmos of code, every project is eternal"*

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-FA7343.svg?style=for-the-badge&logo=swift)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-1575F9.svg?style=for-the-badge&logo=xcode)](https://developer.apple.com/xcode/)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-000000.svg?style=for-the-badge&logo=apple)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-2E86AB.svg?style=for-the-badge)](LICENSE)

```
┌─────────────────────────────────────────────┐
│  ∞  Infinite Development Power Unleashed  ∞ │
│     🔮 Build • Test • Deploy • Repeat     │
└─────────────────────────────────────────────┘
```

*Inspired by Alars, the cosmic synthesizer from The Eternals, this CLI tool harnesses infinite power to manage your Xcode projects across the vast expanse of development workflows.*

</div>

---

## 🌌 **Cosmic Abilities**

**ALARS** isn't just another CLI tool—it's a **cosmic force** that transforms your development workflow into an eternal symphony of productivity:

### ⚡ **Git Flow Mastery**
- **🌟 Clean Slate**: Reset your cosmic workspace to pristine condition
- **💫 Save Power**: Stash changes or create temporal branches with a thought
- **🌠 Update Ritual**: Pull latest changes from the cosmic repository

### 🔮 **Build & Test Synthesis**
- **⚛️ Project Compilation**: Build any scheme with infinite precision
- **🧪 Test Orchestration**: Run comprehensive test suites across dimensions
- **📱 Simulator Control**: Deploy to any device across the Apple multiverse

### 🚀 **Custom Command Chains**
- **∞ Infinite Sequences**: Chain operations into powerful cosmic rituals
- **🎭 Personalized Workflows**: Create your own eternal development patterns

---

## 🎯 **Quick Start Ritual**

### **Installation Ceremony**

```bash
# Clone the eternal repository
git clone <repository-url>
cd Alars

# Build with cosmic energy
swift build -c release

# Install to your sacred path
cp .build/release/alars /usr/local/bin/
```

### **First Invocation**

```bash
# Initialize your project constellation
alars init

# Enter the eternal development flow
alars
```

---

## 📜 **Sacred Configuration**

Create an `xprojects.json` file to define your project realms:

```json
{
  "projects": [
    {
      "name": "CosmicApp",
      "workingDirectory": "~/Cosmos/CosmicApp",
      "repositoryURL": "https://github.com/eternal/CosmicApp.git",
      "configuration": {
        "defaultBranch": "main",
        "defaultScheme": "CosmicApp",
        "defaultTestScheme": "CosmicAppTests",
        "defaultSimulator": "iPhone 15 Pro",
        "savePreference": "stash"
      },
      "customCommands": [
        {
          "alias": "cosmic-deploy",
          "description": "Full deployment across the multiverse",
          "operations": [
            { "type": "clean_slate" },
            { "type": "update" },
            { "type": "build", "parameters": { "scheme": "CosmicApp-Release" } },
            { "type": "test" }
          ]
        }
      ]
    }
  ]
}
```

---

## 🎭 **Eternal Commands**

<details>
<summary><strong>🌟 Interactive Cosmic Console</strong></summary>

```bash
# Enter the eternal realm
alars

# Direct project targeting
alars run --project CosmicApp

# Execute specific cosmic operations
alars run --project CosmicApp --operation build
```
</details>

<details>
<summary><strong>⚡ Direct Power Invocation</strong></summary>

```bash
# List all project realms
alars list

# Initialize new constellation
alars init

# Execute custom command sequences
alars run --project CosmicApp --command cosmic-deploy
```
</details>

---

## 🔮 **Cosmic Operations**

| Operation | Cosmic Power | Description |
|-----------|-------------|-------------|
| `🌌 clean_slate` | **Temporal Reset** | Discard all uncommitted changes |
| `💫 save` | **Energy Preservation** | Stash or branch your cosmic work |
| `🌠 update` | **Dimensional Sync** | Pull latest from the eternal repository |
| `⚛️ build` | **Matter Compilation** | Synthesize your code into reality |
| `🧪 test` | **Reality Validation** | Verify your cosmic implementations |
| `🚀 run` | **Deployment Across Realms** | Launch on simulators and devices |

---

## 🏗️ **Development Sanctum**

### **Xcode Integration**

Open the project in Xcode for cosmic debugging:

```bash
open Package.swift
```

**Available Debug Schemes:**
- `Alars` - Interactive mode with `--help`
- `Alars-Init` - Configuration initialization
- `Alars-List` - Project enumeration
- `Alars-Build` - Direct build operations
- `Alars-Interactive` - Full interactive flow

### **Testing the Eternal Powers**

```bash
# Run the cosmic test suite
swift test

# Build and verify
swift build && swift run alars --help
```

---

## 🌟 **Architecture of Infinity**

```
Sources/Alars/
├── 🎭 Commands/     # ArgumentParser cosmic interfaces
├── 🎮 Controllers/  # Operation orchestration nexus
├── 📊 Models/       # Data structures of eternity
├── ⚙️  Services/     # External realm interactions
└── 🖥️  Views/       # Cosmic user interfaces
```

**Sacred Pattern**: **MVC Architecture**
- **Models**: Define the eternal data structures
- **Views**: Present the cosmic interface to mortals
- **Controllers**: Orchestrate the infinite operations
- **Services**: Bridge to external cosmic forces (Git, Xcode)

---

## 🤝 **Join the Eternal Council**

Contributions to the eternal forge are welcomed! See [CONTRIBUTING.md](CONTRIBUTING.md) for the sacred protocols.

### **Adding New Cosmic Powers**

1. **Define Operation**: Add to `OperationType` enum
2. **Implement Service**: Create external interaction logic
3. **Orchestrate Controller**: Add operation handling
4. **Update Interface**: Enhance the cosmic menus

---

## 📋 **System Requirements**

- **🍎 macOS**: 13.0 or later (Ventura+)
- **⚡ Xcode**: 15.0+ with command line tools
- **🔧 Swift**: 5.9 or later
- **🌐 Git**: For repository operations

---

## 🌌 **License**

This cosmic tool is released under the MIT License. See [LICENSE](LICENSE) for the eternal terms.

---

<div align="center">

### *"When you have the power of eternity, every build is perfect, every test passes, and every deployment reaches across infinite dimensions."*

**⟨ ⟩ — Alars, The Synthesizer — ⟨ ⟩**

---

**Built with cosmic energy by the Eternal Developer Council** ✨

[![Made with Swift](https://img.shields.io/badge/Made%20with-Swift-FA7343.svg?style=flat&logo=swift)](https://swift.org)
[![Powered by Eternity](https://img.shields.io/badge/Powered%20by-Eternity-9B59B6.svg?style=flat)](https://github.com/eternals)

</div>