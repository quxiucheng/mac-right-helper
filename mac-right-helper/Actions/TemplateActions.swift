import Foundation

struct NewFileWithTemplateAction: ActionHandler {
    let template: FileTemplate

    func handle(filePaths: [String]) async throws {
        guard let dir = filePaths.first else { return }
        var isDir: ObjCBool = false
        let path = FileManager.default.fileExists(atPath: dir, isDirectory: &isDir) && isDir.boolValue
            ? dir
            : (URL(fileURLWithPath: dir).deletingLastPathComponent().path)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        let newFilePath = (path as NSString).appendingPathComponent("Untitled_\(dateStr).\(template.ext)")
        let contentData = template.content.data(using: .utf8) ?? Data()
        FileManager.default.createFile(atPath: newFilePath, contents: contentData)
    }
}

struct NewFolderFromFileNameAction: ActionHandler {
    func handle(filePaths: [String]) async throws {
        guard !filePaths.isEmpty else { return }
        for path in filePaths {
            let name = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            let folderPath = (parent as NSString).appendingPathComponent(name)
            try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
        }
    }
}
