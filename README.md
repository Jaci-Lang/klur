# KLUR (Klee Luau Runtime)

**KLUR** is a modern, high-performance, standardized runtime, standard library batteries suite, and package manager toolchain for Jaci. Inspired by the speed and developer experience (DX) of Bun and Cargo, KLUR delivers a batteries-included ecosystem for general-purpose Luau development.

## Highlights

- **100% Pure Luau Engine**: Runtime logic, package manager, test framework, and standard batteries are implemented completely in Luau.
- **Universal Module System**: Zero-config resolution of `klur_modules/`, `init.luau`, `index.luau`, bare specifiers (`require("pkg")`), and scoped packages (`require("@scope/pkg")`).
- **Deterministic Package Management**: `Packagefile` (written in Luau, no file extension) and `Packagefile.lock` for reproducible dependency trees.
- **Git-Based Distribution**: First-class support for Git repositories (`github:user/repo#tag`), commit pinning, and semantic version resolution.
- **Content-Addressable Cache Store**: Global cache store (`~/.klur/store/`) with fast linking into `klur_modules/` to eliminate duplicate downloads and save disk space.
- **Rich Standard Batteries**:
  - `@klur/fs`: Cross-platform path normalization, recursive directory operations (`mkdirp`, `rimraf`), file walking, globbing, and atomic writes.
  - `@klur/process`: Command execution, pipelines, process spawning, environment variables, and binary lookup (`which`).
  - `@klur/net`: Fetch-like HTTP client with JSON serialization, query parameter formatting, and micro HTTP server with routing and middlewares.
  - `@klur/async`: Promises/A+ compliant implementation, worker pools (`pLimit`), sleep, retry with exponential backoff, and async combinators.
  - `@klur/crypto`: SHA-256, SHA-512, MD5, HMAC, UUID v4/v7 generation, random hex generators, and timing-safe equality.
  - `@klur/serde`: TOML parser/serializer, `.env` file loader, and JSON encoders.
  - `@klur/term`: ANSI styling, terminal spinners, tables, and interactive prompts.
  - `@klur/log`: Level-based structured logging with timestamps and color badges.
  - `@klur/test`: Full-featured test runner with `describe`, `test`/`it`, `beforeEach`/`afterEach`, and rich assertions (`expect(a).toBe(b)`).
- **Single-Binary Compiler Integration**: Compile any Luau script and its dependencies into a standalone native executable using `klur build`.

---

## Installation

KLUR ships as the KLUR layer of a Jaci toolchain. The recommended install path is **jaciup**, the official toolchain manager:

```bash
# 1. Install jaciup (macOS / Linux)
curl -fsSL https://raw.githubusercontent.com/Jaci-Lang/jaciup/main/scripts/install.sh | bash

# Windows (PowerShell)
iwr -UseBasicParsing https://raw.githubusercontent.com/Jaci-Lang/jaciup/main/scripts/install.ps1 -OutFile install.ps1
./install.ps1
```

```bash
# 2. Install a toolchain (Jaci engine + KLUR layer), shims and shell PATH
jaciup toolchain install latest
```

Open a new shell — `klur`, `luau`, `luau-analyze` and friends are on the PATH via `~/.jaciup/bin`. Useful flags:

- `install.sh --with-toolchain` — steps 1 + 2 in one go.
- `jaciup doctor` — diagnoses the installation (toolchains, shims, PATH).
- `jaciup toolchain klur` — (re)installs the KLUR layer into the active toolchain.

### From source (development)

```bash
git clone https://github.com/Jaci-Lang/klur.git
cd klur
JACI_BIN=/path/to/luau ./bin/klur test   # run the test suite
JACI_BIN=/path/to/luau ./bin/klur init   # in a project directory
```

The `JACI_BIN` environment variable points the `klur` launcher at a Jaci/Luau
engine binary (a `jaciup` toolchain install provides one at
`~/.jaciup/toolchains/<version>/luau`).

## Quick Start

### 1. Initialize a Project

```bash
klur init
```

This creates:
- `Packagefile`
- `src/init.luau`
- `tests/main.test.luau`
- `.gitignore`

### 2. Run Scripts

```bash
klur run src/init.luau
# or run scripts declared in Packagefile
klur start
```

### 3. Run Tests

```bash
klur test
```

### 4. Build Standalone Native Executable

```bash
klur build src/init.luau --output dist/myapp
./dist/myapp
```

---

## Packagefile Specification

A `Packagefile` is written in standard Luau:

```luau
return {
    name = "@myorg/service",
    version = "1.0.0",
    description = "A high performance Luau service",
    main = "src/init.luau",
    bin = {
        myservice = "src/cli.luau"
    },
    scripts = {
        start = "klur run src/init.luau",
        test = "klur test",
        build = "klur build src/init.luau --output dist/myservice"
    },
    dependencies = {
        ["@klur/net"] = "github:klur-lang/net#v1.0.0",
        ["utils"] = "link:../local-utils",
    },
    devDependencies = {
        ["@klur/test"] = "github:klur-lang/test#v1.0.0"
    },
    license = "MIT",
}
```

---

## CLI Commands

| Command | Description |
|---|---|
| `klur init` | Initialize a new project with `Packagefile` |
| `klur run <file \| script>` | Execute a `.luau` file or script defined in `Packagefile` |
| `klur install` (or `klur i`) | Install dependencies into `klur_modules/` |
| `klur add <spec>` | Add a dependency to `Packagefile` and install |
| `klur remove <name>` | Remove a dependency from `Packagefile` and `klur_modules/` |
| `klur test` | Discover and run test suites (`*.test.luau`, `*.spec.luau`) |
| `klur build <entry>` | Bundle and compile into a single native binary executable |
| `klur link [name]` | Register or link local packages for development |
| `klur unlink [name]` | Remove package links |
| `klur cache [clean\|dir\|list]` | Manage global content-addressable cache store |
| `klur info` | Inspect runtime environment and paths |
| `klur publish` | Create and publish release Git tag |
| `klur --version` (or `-v`) | Print KLUR version |

---

## Architecture & Modular Structure

```
klur/
├── Packagefile                     # Package manifest
├── bin/
│   └── klur                        # Executable CLI launcher
├── src/
│   ├── init.luau                   # Runtime entrypoint
│   ├── core/                       # Versioning, errors, system metadata
│   ├── pm/                         # Package manager engine (Packagefile, Lockfile, Git, Store, Resolver)
│   ├── cli/                        # Argument parser, dispatcher, and command handlers
│   └── std/                        # Standard Batteries (@klur/*)
│       ├── fs/                     # Filesystem and cross-platform path library
│       ├── process/                # Process spawning and execution
│       ├── net/                    # HTTP client, server router, fetch
│       ├── async/                  # Promises, worker pools, sleep, retry
│       ├── crypto/                 # Hashing (SHA-256, SHA-512, MD5, HMAC), UUID
│       ├── serde/                  # TOML, DotEnv, JSON
│       ├── term/                   # Terminal colors, spinners, tables, prompts
│       ├── log/                    # Leveled structured logging
│       └── test/                   # Test runner and assertion framework
└── tests/                          # Test suites for all modules
```

---

## License

Copyright (c) 2026 Júlia Klee. Licensed under the MIT License.
