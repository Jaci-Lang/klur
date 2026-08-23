# KLUR (Klee Luau Runtime) Development Guidelines & Invariants

## Project Overview
KLUR (Klee Luau Runtime) is a modern, high-performance, standardized runtime, standard library enhancement, and package manager toolchain for Jaci. Inspired by the developer experience (DX) and speed of modern runtimes like Bun, KLUR provides a batteries-included ecosystem for Luau outside Roblox Studio.

## Core Technical Focus
- **Pure Luau Implementation**: Implement all runtime logic, standard library extensions, package management, test runner, and CLI tooling 100% in Luau. Only touch C++ when integrating directly into Jaci core primitives.
- **Developer Experience (DX) First**: Instant startup, clean CLI commands, zero-config module resolution, built-in test framework, and rich terminal output.
- **Git-Based Distribution**: Standardized package distribution using Git repositories, commit pinning, tag resolution, and content-addressable cache linking.
- **Deterministic Package Management**: `Packagefile` (in Luau without file extension) and `Packagefile.lock` for reproducible dependency trees.
- **Universal Module System**: Seamless resolution of `klur_modules/`, `init.luau`, `index.luau`, bare specifiers, and scoped packages (`@scope/name`).
- **Rich Standard Batteries**: Idiomatic, low-cost abstractions for filesystem, process spawning, networking/HTTP, async/Promises, crypto, serialization, and terminal DX.

## Communication & Documentation Style
- **Imperative English**: Write documentation, code comments, and commit messages in direct, imperative English (e.g., "Add git resolver", "Fix path normalization").
- **Concise & Low-Ceremony**: Keep documentation dense, technically precise, and actionable.
- **No Emojis**: Do not use emojis in codebase documentation, commit messages, or comments.

## Package Architecture & Invariants
- **Packagefile**: The root package descriptor MUST be named `Packagefile` (no extension) and written in valid Luau returning a package table.
- **Deterministic Lockfile**: `Packagefile.lock` MUST be updated deterministically with exact commit SHAs, integrity hashes, and dependency trees.
- **Cache Store**: Downloaded Git packages are cached in `~/.klur/store/` (or `~/.cache/klur/store/`) and linked into `klur_modules/` to avoid redundant network transfers.
- **Cross-Platform**: All path operations and process commands must support Linux, macOS, and Windows seamlessly.
- **Non-Invasive Superset**: KLUR enhances standard Luau/Jaci without breaking standard semantics.

## Licensing
Copyright (c) 2026 Júlia Klee. MIT License.
