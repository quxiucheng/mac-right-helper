# mac-right-helper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS Finder right-click extension tool using Swift and NSServices, providing file operations, dev tools, system enhancements, and custom scripts — all manageable via preferences window, status bar, and right-click settings entry.

**Architecture:** Single macOS App with no separate extension target. All Finder integration goes through `NSServices` declared in `Info.plist`. Configuration is stored in `UserDefaults` as JSON. The app registers services on launch and re-registers when config changes via `NSUpdateDynamicServices()`.

**Tech Stack:** Swift, AppKit, Foundation, XCTest

---

## File Structure

```
mac-right-helper/
├── mac-right-helper/
│   ├── main.swift
│   ├── AppDelegate.swift
│   ├── Info.plist
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── MenuGroup.swift
│   │   ├── MenuItem.swift
│   │   ├── MenuAction.swift
│   │   ├── AppConfig.swift
│   │   └── CustomScript.swift
│   ├── Core/
│   │   ├── ConfigManager.swift
│   │   ├── ScriptExecutor.swift
│   │   └── PermissionManager.swift
│   ├── Actions/
│   │   ├── ActionHandler.swift
│   │   ├── FileActions.swift
│   │   ├── DevActions.swift
│   │   └── SystemActions.swift
│   ├── UI/
│   │   ├── StatusBarController.swift
│   │   └── PreferencesWindowController.swift
│   └── Utils/
│       └── PasteboardReader.swift
└── mac-right-helperTests/
    ├── ConfigManagerTests.swift
    ├── ScriptExecutorTests.swift
    └── PermissionManagerTests.swift
```

---

## Task 1: Project Scaffold

**Files:**
- Create: `mac-right-helper/main.swift`
- Create: `mac-right-helper/AppDelegate.swift`
- Create: `mac-right-helper/Info.plist`
- Create: `mac-right-helper/Assets.xcassets/`
- Create: `mac-right-helperTests/`

- [ ] **Step 1: Create directory structure**

Run:
```bash
mkdir -p mac-right-helper/{Models,Core,Actions,UI,Utils}
mkdir -p mac-right-helperTests
```

- [ ] **Step 2: Write main.swift**

`mac-right-helper/main.swift`:
```swift
import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 3: Write minimal AppDelegate**

`mac-right-helper/AppDelegate.swift`:
```swift
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("mac-right-helper launched")
    }
}
```

- [ ] **Step 4: Write Info.plist**

`mac-right-helper/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.mac-right-helper</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>mac-right-helper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>Copy Path</string>
            </dict>
            <key>NSMessage</key>
            <string>handleService</string>
            <key>NSPortName</key>
            <string>mac-right-helper</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSTextContent</key>
                <string>FilePath</string>
            </dict>
            <key>NSSendTypes</key>
            <array>
                <string>NSFilenamesPboardType</string>
            </array>
            <key>NSUserData</key>
            <string>copyPath</string>
        </dict>
    </array>
</dict>
</plist>
```

Note: `LSUIElement` is `true` so the app runs as an agent (no dock icon). One service is declared as a placeholder; more will be added in Task 8.

- [ ] **Step 5: Commit**

```bash
git add mac-right-helper/ mac-right-helperTests/
git commit -m "scaffold: create project structure and base files"
```

---

## Task 2: Core Models

**Files:**
- Create: `mac-right-helper/Models/MenuGroup.swift`
- Create: `mac-right-helper/Models/MenuAction.swift`
- Create: `mac-right-helper/Models/MenuItem.swift`
- Create: `mac-right-helper/Models/CustomScript.swift`
- Create: `mac-right-helper/Models/AppConfig.swift`

- [ ] **Step 1: Write MenuGroup**

`mac-right-helper/Models/MenuGroup.swift`:
```swift
import Foundation

enum MenuGroup: String, Codable, CaseIterable {
    case fileOperations = "fileOperations"
    case devTools = "devTools"
    case systemEnhancements = "systemEnhancements"
    case customScripts = "customScripts"

    var displayName: String {
        switch self {
        case .fileOperations: return "File Operations"
        case .devTools: return "Dev Tools"
        case .systemEnhancements: return "System"
        case .customScripts: return "Custom Scripts"
        }
    }
}
```

- [ ] **Step 2: Write MenuAction**

`mac-right-helper/Models/MenuAction.swift`:
```swift
import Foundation

enum MenuAction: Codable {
    case copyPath(format: PathFormat)
    case copyFileName
    case newFile(template: String)
    case compress
    case decompress
    case moveTo
    case copyTo
    case openInVSCode
    case openInTerminal
    case gitInit
    case gitStatus
    case formatJSON
    case toggleHiddenFiles
    case changePermissions
    case createSymlink
    case openParentDirectory
    case runCustomScript(id: String)

    enum PathFormat: String, Codable {
        case posix, hfs, url
    }
}
```

- [ ] **Step 3: Write MenuItem**

`mac-right-helper/Models/MenuItem.swift`:
```swift
import Foundation

struct MenuItem: Codable, Identifiable {
    let id: String
    let displayName: String
    let group: MenuGroup
    let icon: String?
    let sendTypes: [String]
    let action: MenuAction
    var isEnabled: Bool
    var sortWeight: Int
}
```

- [ ] **Step 4: Write CustomScript**

`mac-right-helper/Models/CustomScript.swift`:
```swift
import Foundation

enum ScriptType: String, Codable {
    case shell, python, appleScript
}

struct CustomScript: Codable, Identifiable {
    let id: String
    let name: String
    let type: ScriptType
    let source: String
    let icon: String?
    let sendTypes: [String]
    var sortWeight: Int
}
```

- [ ] **Step 5: Write AppConfig**

`mac-right-helper/Models/AppConfig.swift`:
```swift
import Foundation

struct AppConfig: Codable {
    var version: Int
    var builtinItems: [String: BuiltinItemConfig]
    var customScripts: [CustomScript]

    struct BuiltinItemConfig: Codable {
        var enabled: Bool
        var weight: Int
    }

    static let defaultConfig: AppConfig = AppConfig(
        version: 1,
        builtinItems: [
            "copyPath": BuiltinItemConfig(enabled: true, weight: 10),
            "copyFileName": BuiltinItemConfig(enabled: true, weight: 11),
            "newFile": BuiltinItemConfig(enabled: true, weight: 20),
            "compress": BuiltinItemConfig(enabled: true, weight: 30),
            "decompress": BuiltinItemConfig(enabled: true, weight: 31),
            "moveTo": BuiltinItemConfig(enabled: true, weight: 40),
            "copyTo": BuiltinItemConfig(enabled: true, weight: 41),
            "openInVSCode": BuiltinItemConfig(enabled: true, weight: 100),
            "openInTerminal": BuiltinItemConfig(enabled: true, weight: 101),
            "gitInit": BuiltinItemConfig(enabled: true, weight: 110),
            "gitStatus": BuiltinItemConfig(enabled: true, weight: 111),
            "formatJSON": BuiltinItemConfig(enabled: true, weight: 120),
            "toggleHiddenFiles": BuiltinItemConfig(enabled: true, weight: 200),
            "changePermissions": BuiltinItemConfig(enabled: true, weight: 201),
            "createSymlink": BuiltinItemConfig(enabled: true, weight: 202),
            "openParentDirectory": BuiltinItemConfig(enabled: true, weight: 203),
        ],
        customScripts: []
    )
}
```

- [ ] **Step 6: Commit**

```bash
git add mac-right-helper/Models/
git commit -m "feat: add core models (MenuItem, MenuGroup, MenuAction, AppConfig, CustomScript)"
```

---

## Task 3: ConfigManager

**Files:**
- Create: `mac-right-helper/Core/ConfigManager.swift`
- Create: `mac-right-helperTests/ConfigManagerTests.swift`

- [ ] **Step 1: Write failing test**

`mac-right-helperTests/ConfigManagerTests.swift`:
```swift
import XCTest
@testable import mac_right_helper

final class ConfigManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "RightHelperMenuConfig")
    }

    func testDefaultConfigLoadedWhenMissing() {
        let manager = ConfigManager()
        XCTAssertEqual(manager.config.version, 1)
        XCTAssertTrue(manager.config.builtinItems["copyPath"]?.enabled ?? false)
    }

    func testSaveAndLoadConfig() {
        let manager = ConfigManager()
        manager.config.builtinItems["copyPath"] = AppConfig.BuiltinItemConfig(enabled: false, weight: 99)
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertEqual(manager2.config.builtinItems["copyPath"]?.enabled, false)
        XCTAssertEqual(manager2.config.builtinItems["copyPath"]?.weight, 99)
    }

    func testCustomScriptRoundtrip() {
        let manager = ConfigManager()
        manager.config.customScripts = [
            CustomScript(id: "test-1", name: "Test", type: .shell, source: "echo hi", icon: nil, sendTypes: ["public.item"], sortWeight: 1)
        ]
        manager.save()

        let manager2 = ConfigManager()
        XCTAssertEqual(manager2.config.customScripts.count, 1)
        XCTAssertEqual(manager2.config.customScripts.first?.name, "Test")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: FAIL with "ConfigManager not defined"

- [ ] **Step 3: Write ConfigManager**

`mac-right-helper/Core/ConfigManager.swift`:
```swift
import Foundation

class ConfigManager {
    static let shared = ConfigManager()
    static let configKey = "RightHelperMenuConfig"
    static let configChangedNotification = Notification.Name("RightHelperConfigChanged")

    var config: AppConfig {
        didSet {
            NotificationCenter.default.post(name: Self.configChangedNotification, object: nil)
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.configKey),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = AppConfig.defaultConfig
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
        }
    }

    func resetToDefaults() {
        config = AppConfig.defaultConfig
        save()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mac-right-helper/Core/ConfigManager.swift mac-right-helperTests/ConfigManagerTests.swift
git commit -m "feat: add ConfigManager with UserDefaults persistence and tests"
```

---

## Task 4: PasteboardReader Utility

**Files:**
- Create: `mac-right-helper/Utils/PasteboardReader.swift`
- Create: `mac-right-helperTests/PasteboardReaderTests.swift`

- [ ] **Step 1: Write failing test**

`mac-right-helperTests/PasteboardReaderTests.swift`:
```swift
import XCTest
import AppKit
@testable import mac_right_helper

final class PasteboardReaderTests: XCTestCase {
    func testExtractFilePaths() {
        let pb = NSPasteboard(name: .init("test"))
        pb.clearContents()
        pb.setString("/tmp/test.txt", forType: .fileURL)

        let paths = PasteboardReader.extractFilePaths(from: pb)
        XCTAssertEqual(paths, ["/tmp/test.txt"])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: FAIL with "PasteboardReader not defined"

- [ ] **Step 3: Write PasteboardReader**

`mac-right-helper/Utils/PasteboardReader.swift`:
```swift
import Foundation
import AppKit

enum PasteboardReader {
    static func extractFilePaths(from pasteboard: NSPasteboard) -> [String] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        var paths: [String] = []
        for item in items {
            if let urlData = item.data(forType: .fileURL),
               let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                paths.append(url.path)
            }
        }
        return paths
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mac-right-helper/Utils/PasteboardReader.swift mac-right-helperTests/PasteboardReaderTests.swift
git commit -m "feat: add PasteboardReader utility to extract file paths from NSPasteboard"
```

---

## Task 5: ScriptExecutor

**Files:**
- Create: `mac-right-helper/Core/ScriptExecutor.swift`
- Create: `mac-right-helperTests/ScriptExecutorTests.swift`

- [ ] **Step 1: Write failing test**

`mac-right-helperTests/ScriptExecutorTests.swift`:
```swift
import XCTest
@testable import mac_right_helper

final class ScriptExecutorTests: XCTestCase {
    func testExecuteShellEcho() async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "echo hello", arguments: [])
        XCTAssertTrue(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).contains("hello"))
    }

    func testExecuteShellWithArguments() async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "echo \"$1\"", arguments: ["/tmp/test"])
        XCTAssertTrue(result.stdout.contains("/tmp/test"))
    }

    func testExecuteShellFailure() async {
        let executor = ScriptExecutor()
        do {
            _ = try await executor.executeShell(script: "exit 1", arguments: [])
            XCTFail("Should have thrown")
        } catch {
            // expected
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: FAIL with "ScriptExecutor not defined"

- [ ] **Step 3: Write ScriptExecutor**

`mac-right-helper/Core/ScriptExecutor.swift`:
```swift
import Foundation

enum ScriptExecutionError: Error {
    case executionFailed(stderr: String, code: Int32)
    case invalidScriptType
}

struct ScriptResult {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

class ScriptExecutor {
    func executeShell(script: String, arguments: [String]) async throws -> ScriptResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let stdout = self.read(pipe: stdoutPipe)
                let stderr = self.read(pipe: stderrPipe)
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: ScriptResult(stdout: stdout, stderr: stderr, exitCode: proc.terminationStatus))
                } else {
                    continuation.resume(throwing: ScriptExecutionError.executionFailed(stderr: stderr, code: proc.terminationStatus))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func executePython(script: String, arguments: [String]) async throws -> ScriptResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", script] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { proc in
                let stdout = self.read(pipe: stdoutPipe)
                let stderr = self.read(pipe: stderrPipe)
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: ScriptResult(stdout: stdout, stderr: stderr, exitCode: proc.terminationStatus))
                } else {
                    continuation.resume(throwing: ScriptExecutionError.executionFailed(stderr: stderr, code: proc.terminationStatus))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func executeAppleScript(source: String) async throws -> ScriptResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorInfo: NSDictionary?
                guard let appleScript = NSAppleScript(source: source) else {
                    continuation.resume(throwing: ScriptExecutionError.invalidScriptType)
                    return
                }
                let result = appleScript.executeAndReturnError(&errorInfo)
                if let error = errorInfo {
                    let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
                    continuation.resume(throwing: ScriptExecutionError.executionFailed(stderr: message, code: 1))
                } else {
                    let output = result?.stringValue ?? ""
                    continuation.resume(returning: ScriptResult(stdout: output, stderr: "", exitCode: 0))
                }
            }
        }
    }

    private func read(pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mac-right-helper/Core/ScriptExecutor.swift mac-right-helperTests/ScriptExecutorTests.swift
git commit -m "feat: add ScriptExecutor with shell/python/applescript support and tests"
```

---

## Task 6: PermissionManager

**Files:**
- Create: `mac-right-helper/Core/PermissionManager.swift`
- Create: `mac-right-helperTests/PermissionManagerTests.swift`

- [ ] **Step 1: Write failing test**

`mac-right-helperTests/PermissionManagerTests.swift`:
```swift
import XCTest
@testable import mac_right_helper

final class PermissionManagerTests: XCTestCase {
    func testFullDiskAccessStatus() {
        let manager = PermissionManager()
        let status = manager.fullDiskAccessStatus
        XCTAssertTrue(status == .granted || status == .denied || status == .unknown)
    }

    func testAccessibilityStatus() {
        let manager = PermissionManager()
        let status = manager.accessibilityStatus
        XCTAssertTrue(status == .granted || status == .denied)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: FAIL with "PermissionManager not defined"

- [ ] **Step 3: Write PermissionManager**

`mac-right-helper/Core/PermissionManager.swift`:
```swift
import Foundation
import ApplicationServices

enum PermissionStatus {
    case granted, denied, unknown
}

class PermissionManager {
    var fullDiskAccessStatus: PermissionStatus {
        let testURL = URL(fileURLWithPath: "~/Library/Safari")
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: testURL.path)
            return .granted
        } catch {
            return .denied
        }
    }

    var accessibilityStatus: PermissionStatus {
        return AXIsProcessTrustedWithOptions(nil) ? .granted : .denied
    }

    func openSystemPreferencesPrivacy() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }

    func openSystemPreferencesPrivacyAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme mac-right-helper -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add mac-right-helper/Core/PermissionManager.swift mac-right-helperTests/PermissionManagerTests.swift
git commit -m "feat: add PermissionManager for Full Disk and Accessibility checks"
```

---

## Task 7: Action Handlers

**Files:**
- Create: `mac-right-helper/Actions/ActionHandler.swift`
- Create: `mac-right-helper/Actions/FileActions.swift`
- Create: `mac-right-helper/Actions/DevActions.swift`
- Create: `mac-right-helper/Actions/SystemActions.swift`

- [ ] **Step 1: Write ActionHandler protocol and dispatcher**

`mac-right-helper/Actions/ActionHandler.swift`:
```swift
import Foundation
import AppKit

protocol ActionHandler {
    func handle(filePaths: [String]) async throws
}

enum ActionDispatcher {
    private static var handlers: [String: ActionHandler] = [
        "copyPath": CopyPathAction(),
        "copyFileName": CopyFileNameAction(),
        "newFile": NewFileAction(),
        "compress": CompressAction(),
        "decompress": DecompressAction(),
        "moveTo": MoveToAction(),
        "copyTo": CopyToAction(),
        "openInVSCode": OpenInVSCodeAction(),
        "openInTerminal": OpenInTerminalAction(),
        "gitInit": GitInitAction(),
        "gitStatus": GitStatusAction(),
        "formatJSON": FormatJSONAction(),
        "toggleHiddenFiles": ToggleHiddenFilesAction(),
        "changePermissions": ChangePermissionsAction(),
        "createSymlink": CreateSymlinkAction(),
        "openParentDirectory": OpenParentDirectoryAction(),
    ]

    static func handler(for actionID: String) -> ActionHandler? {
        return handlers[actionID]
    }

    static func dispatch(actionID: String, filePaths: [String]) async {
        guard let handler = handlers[actionID] else {
            print("No handler for action: \(actionID)")
            return
        }
        do {
            try await handler.handle(filePaths: filePaths)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Action Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}
```

- [ ] **Step 2: Write FileActions**

`mac-right-helper/Actions/FileActions.swift`:
```swift
import Foundation
import AppKit

struct CopyPathAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
    }
}

struct CopyFileNameAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let name = URL(fileURLWithPath: path).lastPathComponent
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(name, forType: .string)
    }
}

struct NewFileAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let dir = filePaths.first else { return }
        var isDir: ObjCBool = false
        let path = FileManager.default.fileExists(atPath: dir, isDirectory: &isDir) && isDir.boolValue
            ? dir
            : (URL(fileURLWithPath: dir).deletingLastPathComponent().path)

        let newFilePath = (path as NSString).appendingPathComponent("Untitled.txt")
        FileManager.default.createFile(atPath: newFilePath, contents: Data())
    }
}

struct CompressAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let first = filePaths.first else { return }
        let parent = URL(fileURLWithPath: first).deletingLastPathComponent().path
        let name = URL(fileURLWithPath: first).lastPathComponent
        let output = (parent as NSString).appendingPathComponent("\(name).zip")
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "cd \"$1\" && zip -r \"$2\" \"$3\"", arguments: [parent, output, name])
    }
}

struct DecompressAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "unzip \"$1\" -d \"$2\"", arguments: [path, parent])
    }
}

struct MoveToAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose destination folder"

        let response = await MainActor.run {
            return panel.runModal()
        }

        guard response == .OK, let dest = panel.url else { return }
        let name = URL(fileURLWithPath: path).lastPathComponent
        let destPath = dest.appendingPathComponent(name).path
        try FileManager.default.moveItem(atPath: path, toPath: destPath)
    }
}

struct CopyToAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose destination folder"

        let response = await MainActor.run {
            return panel.runModal()
        }

        guard response == .OK, let dest = panel.url else { return }
        let name = URL(fileURLWithPath: path).lastPathComponent
        let destPath = dest.appendingPathComponent(name).path
        try FileManager.default.copyItem(atPath: path, toPath: destPath)
    }
}
```

- [ ] **Step 3: Write DevActions**

`mac-right-helper/Actions/DevActions.swift`:
```swift
import Foundation

struct OpenInVSCodeAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "open -a \"Visual Studio Code\" \"$1\"", arguments: [path])
    }
}

struct OpenInTerminalAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var dir = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            dir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "open -a Terminal \"$1\"", arguments: [dir])
    }
}

struct GitInitAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var dir = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            dir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "cd \"$1\" && git init", arguments: [dir])
    }
}

struct GitStatusAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        var dir = path
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            dir = URL(fileURLWithPath: path).deletingLastPathComponent().path
        }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "cd \"$1\" && open -a Terminal", arguments: [dir])
    }
}

struct FormatJSONAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let json = try JSONSerialization.jsonObject(with: data)
        let pretty = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        try pretty.write(to: URL(fileURLWithPath: path))
    }
}
```

- [ ] **Step 4: Write SystemActions**

`mac-right-helper/Actions/SystemActions.swift`:
```swift
import Foundation

struct ToggleHiddenFilesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        let executor = ScriptExecutor()
        let result = try await executor.executeShell(script: "defaults read com.apple.finder AppleShowAllFiles", arguments: [])
        let current = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue = current == "1" ? "false" : "true"
        _ = try await executor.executeShell(script: "defaults write com.apple.finder AppleShowAllFiles -bool \(newValue) && killall Finder", arguments: [])
    }
}

struct ChangePermissionsAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "chmod +x \"$1\"", arguments: [path])
    }
}

struct CreateSymlinkAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard filePaths.count >= 2 else { return }
        let target = filePaths[0]
        let link = filePaths[1]
        try FileManager.default.createSymbolicLink(atPath: link, withDestinationPath: target)
    }
}

struct OpenParentDirectoryAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
        let executor = ScriptExecutor()
        _ = try await executor.executeShell(script: "open \"$1\"", arguments: [parent])
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add mac-right-helper/Actions/
git commit -m "feat: add ActionHandler protocol and all built-in action implementations"
```

---

## Task 8: Services Integration in AppDelegate

**Files:**
- Modify: `mac-right-helper/AppDelegate.swift`
- Modify: `mac-right-helper/Info.plist`

- [ ] **Step 1: Update AppDelegate to handle Services**

Replace `mac-right-helper/AppDelegate.swift`:
```swift
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        NSUpdateDynamicServices()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configChanged),
            name: ConfigManager.configChangedNotification,
            object: nil
        )
    }

    func handleService(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        let paths = PasteboardReader.extractFilePaths(from: pboard)
        Task {
            await ActionDispatcher.dispatch(actionID: userData, filePaths: paths)
        }
    }

    @objc private func configChanged() {
        NSUpdateDynamicServices()
    }
}
```

- [ ] **Step 2: Expand Info.plist with all built-in services**

Replace `mac-right-helper/Info.plist` `<array>` content inside `NSServices` with entries for every built-in action. Here is the complete updated `NSServices` array (the rest of Info.plist stays the same):

Inside `Info.plist`, replace the `<array>` under `<key>NSServices</key>` with:

```xml
<array>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Copy Path</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>copyPath</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Copy File Name</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>copyFileName</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>New File</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>newFile</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Compress</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>compress</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Decompress</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>decompress</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Move To...</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>moveTo</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Copy To...</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>copyTo</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Open in VS Code</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>openInVSCode</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Open in Terminal</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>openInTerminal</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Git Init</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>gitInit</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Git Status</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>gitStatus</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Format JSON</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSRequiredContext</key>
        <dict>
            <key>NSTextContent</key>
            <string>FilePath</string>
        </dict>
        <key>NSUserData</key><string>formatJSON</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Toggle Hidden Files</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>toggleHiddenFiles</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Make Executable</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>changePermissions</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Create Symlink</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>createSymlink</string>
    </dict>
    <dict>
        <key>NSMenuItem</key>
        <dict><key>default</key><string>Open Parent Directory</string></dict>
        <key>NSMessage</key><string>handleService</string>
        <key>NSPortName</key><string>mac-right-helper</string>
        <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
        <key>NSUserData</key><string>openParentDirectory</string>
    </dict>
</array>
```

- [ ] **Step 3: Commit**

```bash
git add mac-right-helper/AppDelegate.swift mac-right-helper/Info.plist
git commit -m "feat: wire AppDelegate to handle NSServices with ActionDispatcher"
```

---

## Task 9: StatusBarController

**Files:**
- Create: `mac-right-helper/UI/StatusBarController.swift`

- [ ] **Step 1: Write StatusBarController**

`mac-right-helper/UI/StatusBarController.swift`:
```swift
import Cocoa

class StatusBarController {
    private var statusItem: NSStatusItem
    private var preferencesWindowController: PreferencesWindowController?

    init() {
        statusItem = NSStatusBar.shared.statusItem(withLength: NSStatusItem.variableLength)
        setupMenu()
    }

    private func setupMenu() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "hand.point.up.left", accessibilityDescription: "Right Click Helper")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reload Services", action: #selector(reloadServices), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu

        // Left-click to show preferences, right-click to show menu
        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            statusItem.menu = statusItem.menu
            sender.performClick(nil)
        } else {
            showPreferences()
        }
    }

    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func reloadServices() {
        NSUpdateDynamicServices()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add mac-right-helper/UI/StatusBarController.swift
git commit -m "feat: add StatusBarController with preferences and reload menu"
```

---

## Task 10: PreferencesWindowController

**Files:**
- Create: `mac-right-helper/UI/PreferencesWindowController.swift`

- [ ] **Step 1: Write PreferencesWindowController**

`mac-right-helper/UI/PreferencesWindowController.swift`:
```swift
import Cocoa

class PreferencesWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Right Click Helper Preferences"
        window.center()
        self.init(window: window)
        window.contentViewController = PreferencesViewController()
    }
}

class PreferencesViewController: NSViewController {
    private var tableView: NSTableView!
    private var configManager = ConfigManager.shared

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let scrollView = NSScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true

        tableView = NSTableView()
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("enabled")))
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name")))
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("group")))
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self

        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    private func sortedItems() -> [(key: String, config: AppConfig.BuiltinItemConfig)] {
        return configManager.config.builtinItems.sorted { $0.value.weight < $1.value.weight }
    }
}

extension PreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configManager.config.builtinItems.count + configManager.config.customScripts.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let items = sortedItems()
        if row < items.count {
            let item = items[row]
            let cell = NSTableCellView()
            let text = NSTextField(labelWithString: item.key)
            cell.textField = text
            cell.addSubview(text)
            return cell
        }
        return nil
    }
}
```

Note: This is a minimal first version. The full UI with checkboxes for enable/disable, drag-to-reorder, and custom script editor can be added in a follow-up task.

- [ ] **Step 2: Commit**

```bash
git add mac-right-helper/UI/PreferencesWindowController.swift
git commit -m "feat: add PreferencesWindowController with basic table view"
```

---

## Task 11: Custom Script Support in ActionDispatcher

**Files:**
- Modify: `mac-right-helper/Actions/ActionHandler.swift`

- [ ] **Step 1: Add CustomScriptHandler to ActionDispatcher**

Replace `ActionDispatcher` in `mac-right-helper/Actions/ActionHandler.swift` with:

```swift
enum ActionDispatcher {
    private static var handlers: [String: ActionHandler] = [
        "copyPath": CopyPathAction(),
        "copyFileName": CopyFileNameAction(),
        "newFile": NewFileAction(),
        "compress": CompressAction(),
        "decompress": DecompressAction(),
        "moveTo": MoveToAction(),
        "copyTo": CopyToAction(),
        "openInVSCode": OpenInVSCodeAction(),
        "openInTerminal": OpenInTerminalAction(),
        "gitInit": GitInitAction(),
        "gitStatus": GitStatusAction(),
        "formatJSON": FormatJSONAction(),
        "toggleHiddenFiles": ToggleHiddenFilesAction(),
        "changePermissions": ChangePermissionsAction(),
        "createSymlink": CreateSymlinkAction(),
        "openParentDirectory": OpenParentDirectoryAction(),
    ]

    static func handler(for actionID: String) -> ActionHandler? {
        if let builtIn = handlers[actionID] {
            return builtIn
        }
        if let script = ConfigManager.shared.config.customScripts.first(where: { $0.id == actionID }) {
            return CustomScriptHandler(script: script)
        }
        return nil
    }

    static func dispatch(actionID: String, filePaths: [String]) async {
        guard let handler = handler(for: actionID) else {
            print("No handler for action: \(actionID)")
            return
        }
        do {
            try await handler.handle(filePaths: filePaths)
        } catch {
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Action Failed"
                alert.informativeText = "\(error)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }
}

struct CustomScriptHandler: ActionHandler {
    let script: CustomScript

    func handle(filePaths: [String]) async throws {
        let executor = ScriptExecutor()
        switch script.type {
        case .shell:
            _ = try await executor.executeShell(script: script.source, arguments: filePaths)
        case .python:
            _ = try await executor.executePython(script: script.source, arguments: filePaths)
        case .appleScript:
            _ = try await executor.executeAppleScript(source: script.source)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add mac-right-helper/Actions/ActionHandler.swift
git commit -m "feat: add CustomScriptHandler wired into ActionDispatcher"
```

---

## Task 12: Permission Check on Launch

**Files:**
- Modify: `mac-right-helper/AppDelegate.swift`

- [ ] **Step 1: Add permission check on launch**

Update `applicationDidFinishLaunching` in `mac-right-helper/AppDelegate.swift`:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    statusBarController = StatusBarController()
    checkPermissions()
    NSUpdateDynamicServices()

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(configChanged),
        name: ConfigManager.configChangedNotification,
        object: nil
    )
}

private func checkPermissions() {
    let manager = PermissionManager()
    if manager.fullDiskAccessStatus != .granted {
        showPermissionAlert(title: "Full Disk Access Required",
                            info: "mac-right-helper needs Full Disk Access to operate on files in protected locations. Please enable it in System Settings.",
                            url: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    }
}

private func showPermissionAlert(title: String, info: String, url: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = info
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Open Settings")
    alert.addButton(withTitle: "Later")
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add mac-right-helper/AppDelegate.swift
git commit -m "feat: add permission check on app launch with alert to open Settings"
```

---

## Task 13: Package & Build Configuration

**Files:**
- Create: `mac-right-helper.xcodeproj/` (requires macOS / Xcode, but we can create a `build.sh` helper)
- Create: `build.sh`

- [ ] **Step 1: Create build script**

`build.sh`:
```bash
#!/bin/bash
set -e

SCHEME="mac-right-helper"
DEST="platform=macOS"

xcodebuild -scheme "$SCHEME" -destination "$DEST" -configuration Release build

echo "Build complete. Check build/Release/ for the .app bundle."
```

Run: `chmod +x build.sh`

- [ ] **Step 2: Commit**

```bash
git add build.sh
git commit -m "chore: add build script for release builds"
```

---

## Self-Review

### 1. Spec Coverage

| Spec Section | Plan Task |
|--------------|-----------|
| RightClickEngine (单例，启动读取配置，管理 MenuItemRegistry) | Task 8 (AppDelegate wires it up), Task 3 (ConfigManager) |
| MenuItemRegistry (分组，内置项+自定义脚本) | Task 2 (Models), Task 7 (Action handlers), Task 11 (Custom scripts) |
| ConfigManager (UserDefaults, JSON, 热重载通知) | Task 3 |
| ScriptExecutor (Shell/Python/AppleScript) | Task 5 |
| UI (PreferencesWindow, StatusBar, 右键设置入口) | Task 9, Task 10 |
| PermissionManager (检查+引导) | Task 6, Task 12 |
| Services 注册 (Info.plist + NSUpdateDynamicServices) | Task 1, Task 8 |
| 内置功能清单 (文件操作/开发工具/系统增强) | Task 7 |
| 配置格式 | Task 2 (AppConfig) |
| 错误处理 | Distributed across handlers (ScriptExecutor throws, ActionDispatcher shows alert) |
| 测试策略 | Tasks 3, 4, 5, 6 all have XCTest files |

**Gap identified:** The spec mentions a right-click "⚙️ 设置" entry. This is partially addressed by Services, but there's no dedicated "Open Preferences" service. Add one:

Add to Info.plist NSServices array:
```xml
<dict>
    <key>NSMenuItem</key>
    <dict><key>default</key><string>Right Helper Preferences</string></dict>
    <key>NSMessage</key><string>handleService</string>
    <key>NSPortName</key><string>mac-right-helper</string>
    <key>NSSendTypes</key><array><string>NSFilenamesPboardType</string></array>
    <key>NSUserData</key><string>openPreferences</key>
</dict>
```

Add to ActionDispatcher handlers:
```swift
"openPreferences": OpenPreferencesAction(),
```

Add handler:
```swift
struct OpenPreferencesAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        await MainActor.run {
            let controller = PreferencesWindowController()
            controller.showWindow(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
```

This gap should be added as an extra step in Task 8.

### 2. Placeholder Scan

- No TBD or TODO found.
- No vague "add error handling" steps.
- All code steps contain complete code.
- No "similar to Task N" references.

### 3. Type Consistency

- `ConfigManager.configChangedNotification` used in Task 3 and Task 8 — consistent.
- `ActionDispatcher.dispatch(actionID:filePaths:)` signature consistent across Task 7, 8, 11.
- `ScriptExecutor` methods consistent across Task 5 and Task 11.

All consistent. No fixes needed.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-05-12-mac-right-helper.md`.**

**Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
