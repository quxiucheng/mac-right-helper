# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mac-right-helper is a macOS Finder right-click extension tool built in Swift. It adds file operations, dev tools, system enhancements, and custom scripts to the macOS Services menu (Finder right-click). The app runs as a background agent (`LSUIElement`) with a status bar icon and preferences window.

Finder integration uses `NSServices` declared in `Info.plist` — there is no separate Finder Sync extension target. All services route through `AppDelegate.handleService(_:userData:)`.

Minimum supported macOS: 12.0 (Monterey).

## Build & Test Commands

**Build (Release):**
```bash
./build.sh
```

**Build & Test (requires Xcode project):**
```bash
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'
```

**Run a single test class:**
```bash
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' -only-testing mac-right-helperTests/ConfigManagerTests
```

**Run a single test method:**
```bash
xcodebuild test -scheme mac-right-helper -destination 'platform=macOS' -only-testing mac-right-helperTests/ConfigManagerTests/testSaveAndLoadConfig
```

**Build (Release via xcodebuild):**
```bash
xcodebuild -scheme mac-right-helper -destination 'platform=macOS' -configuration Release build
```

**Note:** The Xcode project file (`.xcodeproj`) is not tracked in this repository. The build script assumes a scheme named `mac-right-helper` exists in a local Xcode project.

## High-Level Architecture

### Entry Point & Service Routing

- `main.swift` manually bootstraps `NSApplication.shared` with `AppDelegate` and calls `app.run()`. It does **not** use `@main` or `NSApplicationMain`.
- `AppDelegate.applicationDidFinishLaunching` initializes `StatusBarController`, checks permissions, and registers dynamic services via `NSUpdateDynamicServices()`.
- `AppDelegate.handleService(_:userData:)` is the **single entry point for all Finder right-click actions**. It receives an `NSPasteboard`, extracts file paths via `PasteboardReader`, and dispatches to `ActionDispatcher` using `userData` as the action ID. Because `handleService` is a synchronous NSServices callback, it internally wraps the async `ActionDispatcher.dispatch` in a `Task`.

### Configuration System

- `ConfigManager` is a singleton that persists `AppConfig` to `UserDefaults` under the key `RightHelperMenuConfig`.
- `AppConfig` is a `Codable` struct containing:
  - `builtinItems`: map of action ID → `BuiltinItemConfig` (enabled flag + sort weight)
  - `customScripts`: array of user-defined scripts
- When config changes, `ConfigManager` posts `Notification.Name("RightHelperConfigChanged")`; `AppDelegate` listens and calls `NSUpdateDynamicServices()` to hot-reload services.
- Tests for `ConfigManager` **clear `UserDefaults`** in `setUp` to avoid cross-test pollution.

### Action Dispatch System

- `ActionDispatcher` maintains a **static compile-time registry** (`handlers: [String: ActionHandler]`) of built-in action instances. Custom scripts are resolved at runtime by looking up the script ID in `ConfigManager.shared.config.customScripts` and constructing a `CustomScriptHandler`.
- All handlers implement `ActionHandler.handle(filePaths:)` and run `async`. Errors are surfaced to the user via `NSAlert` on the main actor.
- Built-in actions are grouped into:
  - `FileActions.swift` — copy path/name, new file, compress/decompress, move/copy to
  - `DevActions.swift` — open in VS Code/Terminal, git init/status, format JSON
  - `SystemActions.swift` — toggle hidden files, chmod, create symlink, open parent directory

### Script Execution

- `ScriptExecutor` provides async methods for:
  - `executeShell(script:arguments:)` — runs via `/bin/zsh`
  - `executePython(script:arguments:)` — runs via `/usr/bin/python3`
  - `executeAppleScript(source:)` — runs via `NSAppleScript`
- Shell/Python scripts receive file paths as `$1`, `$2`, etc. (the `arguments` array is appended after the `-c` flag).

### Permission Model

- `PermissionManager` checks Full Disk Access by probing `~/Library/Safari` and checks Accessibility via `AXIsProcessTrustedWithOptions`.
- `AppDelegate` shows a blocking `NSAlert` on launch if Full Disk Access is not granted, with a button to open System Settings directly.

### UI Layer

- `StatusBarController` — `NSStatusBar` item with system symbol `hand.point.up.left`. Left-click opens the preferences window directly; right-click shows the menu (Preferences, Reload Services, Quit). This is implemented by calling `sendAction(on: [.leftMouseUp, .rightMouseUp])` and inspecting `NSApp.currentEvent!.type` in the click handler.
- `PreferencesWindowController` / `PreferencesViewController` — minimal `NSTableView`-based preferences window for listing menu items. It is not yet fully wired for drag-to-reorder or checkbox toggles; the table currently only displays item names.

### Info.plist & Services Registration

- All Finder menu items are declared statically in `Info.plist` under `NSServices`. Each service maps `NSUserData` to an action ID.
- `NSUpdateDynamicServices()` is called on launch and after config changes to refresh the Services menu.
- **Important:** Adding a new built-in action requires:
  1. Implementing the `ActionHandler` in the appropriate `Actions/*.swift` file
  2. Registering it in `ActionDispatcher.handlers`
  3. Adding a corresponding `<dict>` entry in `Info.plist` under `NSServices`

## Test Notes

- Tests use `@testable import mac_right_helper`.
- Test coverage spans: `ConfigManager` (UserDefaults round-trip), `PasteboardReader` (path extraction from pasteboard), `ScriptExecutor` (shell execution and failure handling), and `PermissionManager` (status enum values).
- `ConfigManagerTests` clears `UserDefaults.standard` for `"RightHelperMenuConfig"` in `setUp`.
- `PasteboardReaderTests` creates a named `NSPasteboard` ("test") to avoid interfering with the system pasteboard.
- There is no Xcode project in the repository; running tests requires a local `.xcodeproj` with the scheme configured.
