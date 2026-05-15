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
        let dest = await MainActor.run { () -> URL? in
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.message = L("chooseDestinationFolder")
            guard panel.runModal() == .OK else { return nil }
            return panel.url
        }
        guard let dest = dest else { return }
        let name = URL(fileURLWithPath: path).lastPathComponent
        let destPath = dest.appendingPathComponent(name).path
        try FileManager.default.moveItem(atPath: path, toPath: destPath)
    }
}

struct CopyToAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard let path = filePaths.first else { return }
        let dest = await MainActor.run { () -> URL? in
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.message = L("chooseDestinationFolder")
            guard panel.runModal() == .OK else { return nil }
            return panel.url
        }
        guard let dest = dest else { return }
        let name = URL(fileURLWithPath: path).lastPathComponent
        let destPath = dest.appendingPathComponent(name).path
        try FileManager.default.copyItem(atPath: path, toPath: destPath)
    }
}
