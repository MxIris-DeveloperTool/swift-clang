# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

swift-clang is a Swift package providing Swift bindings for the libclang C API. It enables parsing and analyzing C, Objective-C, and C++ source code from Swift. The library dynamically loads libclang at runtime (via `dlopen`/`LoadLibraryW`) rather than statically linking.

Upstream references:
- `Cclang` headers from [llvm-project](https://github.com/llvm/llvm-project)
- `CclangWrapper` dynamic loader from [SourceKitten](https://github.com/jpsim/SourceKitten)
- `Clang` Swift API from [ClangSwift](https://github.com/llvm-swift/ClangSwift)

## Build & Test Commands

```bash
# Build
swift build 2>&1 | xcsift

# Run all tests
swift test 2>&1 | xcsift

# Run a single test file (e.g., CursorTests)
swift test --filter ClangTests.CursorTests 2>&1 | xcsift

# Run a single test method
swift test --filter ClangTests.CursorTests/testMethodName 2>&1 | xcsift
```

No external dependencies. Requires Swift 6.2+ toolchain (`swift-tools-version: 6.2`). Uses `swiftLanguageModes: [.v5]`.

## Architecture

Three-layer module design:

```
Clang (Swift API)  →  CclangWrapper (dynamic loader)  →  Cclang (C headers)
```

- **Cclang**: Raw clang-c header files (`Sources/Cclang/include/clang-c/`) and a minimal C stub.
- **CclangWrapper**: Runtime dynamic library loading. `library_wrapper.swift` contains `DynamicLinkLibrary` (wraps `dlopen`/`dlsym` handles), `Loader` (platform-specific search paths), and `Subprocess` (cross-platform process execution). `library_wrapper_Clang_C.swift` contains auto-generated C function bindings. On Darwin, `toolchainLoader` resolves libclang from Xcode toolchains via environment variables (`XCODE_DEFAULT_TOOLCHAIN_OVERRIDE`, `TOOLCHAIN_DIR`), `xcrun`, or well-known Xcode.app paths.
- **Clang**: The public Swift API layer.

### Key Types and Patterns

**Cursor protocol** (`Cursor.swift`) is the central abstraction — all AST nodes conform to `Cursor`. Internally, concrete cursor types implement `ClangCursorBacked` (an internal protocol with a `clang: CXCursor` property). `CXCursor` itself conforms to `Cursor` via `@retroactive`.

**`convertCursor(_:)`** (`Cursors.swift`, ~line 1616) maps `CXCursor` to the appropriate concrete Swift struct via a ~280-case switch on `clang.kind`. Returns `nil` for null cursors or unrecognized kinds.

**Concrete cursor types** — ~100 structs in `Cursors.swift` (1900+ lines) covering C/C++/ObjC declarations, expressions, statements, attributes, and preprocessor directives.

**Core resource-managing classes** (use `deinit` for cleanup):
- `Index` — entry point; wraps `CXIndex`
- `TranslationUnit` — parsed source; wraps `CXTranslationUnit`

**OptionSet pattern** for configuration flags: `TranslationUnitOptions`, `GlobalOptions`, `NameRefOptions`.

**String conversion**: `CXString.asSwift()` and `CXString.asSwiftOptional()` in `Utilities.swift` bridge C strings to Swift.

### Source Files (Sources/Clang/)

| File | Purpose |
|------|---------|
| `Index.swift` | Index creation and management |
| `TranslationUnit.swift` | Parsing, reparsing, saving translation units |
| `Cursor.swift` | Cursor protocol, ClangCursorBacked, cursor extensions (children, type, location, etc.) |
| `Cursors.swift` | All concrete cursor type definitions + `convertCursor(_:)` |
| `CType.swift` / `CTypes.swift` | C type system wrappers |
| `Token.swift` | Lexical token representation |
| `Diagnostic.swift` | Compiler diagnostic messages |
| `Comment.swift` | Documentation comment parsing |
| `File.swift` | Source file representation |
| `FunctionDecl.swift` | Function declaration extensions |
| `Availability.swift` | Platform availability, version info |
| `Language.swift` | Language enum (C, ObjC, C++) with file extensions |
| `EvalResult.swift` | Expression evaluation result types |
| `NameRefOptions.swift` | Name reference range options |
| `ClangError.swift` | Error enums (`ClangError`, `ClangSaveError`) |
| `Utilities.swift` | CXString bridging, `Box<T>`, collection helpers |

### Tests

Tests are split into per-type files under `Tests/ClangTests/` (19 files total), with shared utilities in `TestHelpers.swift`. Test input C/Objective-C files are in `Tests/input_tests/` (15 files). Tests cover parsing from strings and files, AST traversal, diagnostics, tokenization, location lookup, reparsing, comments, availability, eval results, and AST file loading.
