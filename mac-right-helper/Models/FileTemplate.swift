import Foundation

struct FileTemplate: Codable, Identifiable {
    let id: String
    var name: String
    var ext: String
    var content: String

    static let defaultTemplates: [FileTemplate] = [
        FileTemplate(id: "tpl-txt", name: "Text", ext: "txt", content: ""),
        FileTemplate(id: "tpl-md", name: "Markdown", ext: "md", content: "# "),
        FileTemplate(id: "tpl-swift", name: "Swift", ext: "swift", content: "import Foundation\n"),
        FileTemplate(id: "tpl-py", name: "Python", ext: "py", content: "# -*- coding: utf-8 -*-\n"),
        FileTemplate(id: "tpl-js", name: "JavaScript", ext: "js", content: ""),
        FileTemplate(id: "tpl-html", name: "HTML", ext: "html", content: "<!DOCTYPE html>\n<html>\n<head>\n</head>\n<body>\n</body>\n</html>\n"),
        FileTemplate(id: "tpl-css", name: "CSS", ext: "css", content: ""),
        FileTemplate(id: "tpl-json", name: "JSON", ext: "json", content: "{}\n"),
        FileTemplate(id: "tpl-sh", name: "Shell", ext: "sh", content: "#!/bin/bash\n"),
        FileTemplate(id: "tpl-zsh", name: "Zsh", ext: "zsh", content: "#!/bin/zsh\n"),
    ]
}
