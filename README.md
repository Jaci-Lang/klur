# KLUR

**KLUR** is the toolchain layer for [Jaci](https://github.com/Jaci-Lang/jaci)
(the Luau fork): a package manager, standard library, test runner, and
single-binary builder — written 100% in Luau and running on top of the Jaci
engine.

The split in one line: `luau` is the engine that runs Luau; `klur` is the
ecosystem around it — dependencies, tests, and shipping your app as one
standalone native binary.

## Install

**jaciup** (the toolchain manager) installs the engine and the KLUR layer
in one step:

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/Jaci-Lang/jaciup/main/scripts/install.sh | bash
```

Windows (PowerShell):

```powershell
iwr -UseBasicParsing https://raw.githubusercontent.com/Jaci-Lang/jaciup/main/scripts/install.ps1 -OutFile install.ps1
./install.ps1
```

Open a new shell: `klur`, `luau`, and friends are on the PATH.
`jaciup doctor` diagnoses any problem.

## Quick Start

```bash
klur init                                    # Packagefile + src/ + tests/
klur run src/init.luau                       # run a script
klur test                                    # run tests (*test.luau)
klur build src/init.luau --output dist/app   # one native binary, no runtime needed
./dist/app
```

## Packages

Dependencies are declared in `Packagefile` (plain Luau, no extension):

```luau
return {
    name = "@myorg/service",
    version = "1.0.0",
    main = "src/init.luau",
    dependencies = {
        ["@klur/net"] = "github:user/repo#v1.0.0",
        ["local-utils"] = "link:../local-utils",
    },
}
```

`klur install` resolves dependencies (git tags, versions, local links) into
`klur_modules/`, with a global content-addressable cache in
`~/.klur/store/`. `klur add` and `klur remove` edit the Packagefile for you.

## Commands

| Command | Description |
|---|---|
| `klur init` | Initialize a new project with `Packagefile` |
| `klur run <file \| script>` | Execute a `.luau` file or a `Packagefile` script |
| `klur install` | Install dependencies into `klur_modules/` |
| `klur add <spec>` / `klur remove <name>` | Add or remove a dependency |
| `klur test` | Discover and run test suites (`*.test.luau`) |
| `klur build <entry>` | Bundle and compile into a single native binary |
| `klur link [name]` / `klur unlink` | Link or unlink local packages |
| `klur cache [clean\|dir\|list]` | Manage the global cache store |
| `klur info` | Inspect runtime environment and paths |
| `klur --version` | Print the KLUR version |

## Standard library

| Module | What it is |
|---|---|
| `@klur/fs` | Filesystem: paths, `mkdirp`/`rimraf`, walk, glob, atomic writes |
| `@klur/process` | Spawn commands, pipelines, environment, `which` |
| `@klur/net` | Fetch-like HTTP client + tiny server with routing |
| `@klur/async` | Promises, worker pools, sleep, retry with backoff |
| `@klur/crypto` | SHA-256/512, MD5, HMAC, UUID |
| `@klur/serde` | TOML, `.env`, JSON |
| `@klur/term` | ANSI colors, spinners, tables, prompts |
| `@klur/log` | Leveled structured logging |
| `@klur/test` | Test runner + `expect()` assertions |

## Development

```bash
git clone https://github.com/Jaci-Lang/klur.git && cd klur
JACI_BIN=/path/to/luau ./bin/klur test
```

`JACI_BIN` points the launcher at an engine binary (a jaciup toolchain keeps
one at `~/.jaciup/toolchains/<version>/luau`).

## License

Copyright (c) 2026 Júlia Klee. MIT License.
