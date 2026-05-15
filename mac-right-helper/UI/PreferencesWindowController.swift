import Cocoa

class PreferencesWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Right Click Helper Preferences"
        window.center()
        self.init(window: window)
        window.contentViewController = PreferencesTabViewController()
    }
}

class PreferencesTabViewController: NSTabViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        makeTabViewItem(NSTabViewItem(viewController: GeneralPreferencesViewController()))
        makeTabViewItem(NSTabViewItem(viewController: ActionsPreferencesViewController()))
        makeTabViewItem(NSTabViewItem(viewController: TemplatesPreferencesViewController()))
        makeTabViewItem(NSTabViewItem(viewController: FoldersPreferencesViewController()))
        makeTabViewItem(NSTabViewItem(viewController: DirectoriesPreferencesViewController()))
        makeTabViewItem(NSTabViewItem(viewController: ScriptsPreferencesViewController()))
    }

    private func makeTabViewItem(_ item: NSTabViewItem) {
        if let vc = item.viewController {
            item.label = vc.title ?? "Tab"
        }
        super.addTabViewItem(item)
    }
}

// MARK: - General

class GeneralPreferencesViewController: NSViewController {
    private let configManager = ConfigManager.shared

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 660, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "General"
        let settings = configManager.config.settings

        var y: CGFloat = 420

        let hideIconCheckbox = NSButton(checkboxWithTitle: "Hide status bar icon", target: self, action: #selector(toggleHideIcon(_:)))
        hideIconCheckbox.state = settings.hideStatusBarIcon ? .on : .off
        hideIconCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        view.addSubview(hideIconCheckbox)
        y -= 36

        let trashLabel = NSTextField(labelWithString: "Trash confirmation:")
        trashLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(trashLabel)
        let trashCheckbox = NSButton(checkboxWithTitle: "Show confirmation before permanently deleting", target: self, action: #selector(toggleTrashConfirm(_:)))
        trashCheckbox.state = settings.trashConfirm ? .on : .off
        trashCheckbox.frame = NSRect(x: 160, y: y, width: 400, height: 22)
        view.addSubview(trashCheckbox)
        y -= 36

        let cutLabel = NSTextField(labelWithString: "Cut behavior:")
        cutLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(cutLabel)
        let cutCheckbox = NSButton(checkboxWithTitle: "Hide files after cutting", target: self, action: #selector(toggleCutHide(_:)))
        cutCheckbox.state = settings.cutHideFiles ? .on : .off
        cutCheckbox.frame = NSRect(x: 160, y: y, width: 400, height: 22)
        view.addSubview(cutCheckbox)
        y -= 36

        let terminalLabel = NSTextField(labelWithString: "Terminal open mode:")
        terminalLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(terminalLabel)
        let terminalPopup = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 180, height: 24))
        terminalPopup.addItems(withTitles: ["New Window", "New Tab"])
        terminalPopup.selectItem(at: settings.terminalOpenMode == .newWindow ? 0 : 1)
        terminalPopup.target = self
        terminalPopup.action = #selector(terminalModeChanged(_:))
        view.addSubview(terminalPopup)
        y -= 44

        let editorLabel = NSTextField(labelWithString: "Default editor:")
        editorLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(editorLabel)
        let editorPopup = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 280, height: 24))
        for editor in EditorConfig.allEditors {
            editorPopup.addItem(withTitle: editor.name)
        }
        if let idx = EditorConfig.allEditors.firstIndex(where: { $0.bundleID == settings.defaultEditor }) {
            editorPopup.selectItem(at: idx)
        }
        editorPopup.target = self
        editorPopup.action = #selector(defaultEditorChanged(_:))
        view.addSubview(editorPopup)
    }

    @objc private func toggleHideIcon(_ sender: NSButton) {
        configManager.config.settings.hideStatusBarIcon = sender.state == .on
        configManager.save()
    }

    @objc private func toggleTrashConfirm(_ sender: NSButton) {
        configManager.config.settings.trashConfirm = sender.state == .on
        configManager.save()
    }

    @objc private func toggleCutHide(_ sender: NSButton) {
        configManager.config.settings.cutHideFiles = sender.state == .on
        configManager.save()
    }

    @objc private func terminalModeChanged(_ sender: NSPopUpButton) {
        configManager.config.settings.terminalOpenMode = sender.indexOfSelectedItem == 0 ? .newWindow : .newTab
        configManager.save()
    }

    @objc private func defaultEditorChanged(_ sender: NSPopUpButton) {
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < EditorConfig.allEditors.count else { return }
        configManager.config.settings.defaultEditor = EditorConfig.allEditors[idx].bundleID
        configManager.save()
    }
}

// MARK: - Built-in Actions

class ActionsPreferencesViewController: NSViewController {
    private var tableView: NSTableView!
    private let configManager = ConfigManager.shared

    private var sortedKeys: [String] {
        configManager.config.builtinItems.sorted { $0.value.weight < $1.value.weight }.map { $0.key }
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 660, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Actions"
        let label = NSTextField(labelWithString: "Built-in Actions")
        label.font = NSFont.boldSystemFont(ofSize: 13)
        label.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(label)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 400))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        tableView = NSTableView()
        tableView.allowsMultipleSelection = false

        let enabledCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("enabled"))
        enabledCol.title = "Enabled"
        enabledCol.width = 60
        tableView.addTableColumn(enabledCol)

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = "Name"
        nameCol.width = 240
        tableView.addTableColumn(nameCol)

        let groupCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("group"))
        groupCol.title = "Group"
        groupCol.width = 100
        tableView.addTableColumn(groupCol)

        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self

        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    private func displayName(for actionID: String) -> String {
        let names: [String: String] = [
            "copyPath": "Copy Path", "copyFileName": "Copy File Name",
            "newFile": "New File", "newFileWithTemplate": "New File with Template",
            "newFolderFromFileName": "New Folder from File Name",
            "compress": "Compress", "decompress": "Decompress",
            "moveTo": "Move To...", "copyTo": "Copy To...",
            "cutFiles": "Cut", "sendToPicker": "Send To...",
            "sendAliasToDesktop": "Send Alias to Desktop",
            "trashPermanently": "Permanently Delete",
            "favoriteDirPicker": "Go to Directory...",
            "showFileInfo": "File Info (Hash)", "airdrop": "AirDrop",
            "openInVSCode": "Open in VS Code", "openInTerminal": "Open in Terminal",
            "openInITerm2": "Open in iTerm2", "openInSublimeText": "Open in Sublime Text",
            "openInWarp": "Open in Warp", "openInIDEA": "Open in IntelliJ IDEA",
            "gitInit": "Git Init", "gitStatus": "Git Status", "formatJSON": "Format JSON",
            "toggleHiddenFiles": "Toggle Hidden Files", "hideSelectedFiles": "Hide Selected Files",
            "unhideSelectedFiles": "Unhide Selected Files", "changePermissions": "Make Executable",
            "createSymlink": "Create Symlink", "openParentDirectory": "Open Parent Directory",
            "imageToICNS": "Convert to ICNS", "imageToIOSIcons": "Convert to iOS Icon Set",
            "imageToMacIcons": "Convert to Mac Icon Set", "setCustomIcon": "Set Custom Icon",
            "translateBaidu": "Baidu Translate", "translateGoogle": "Google Translate",
            "toQRCode": "Convert to QR Code",
            "iShotScreenshot": "iShot Screenshot", "iShotAnnotate": "iShot Annotate",
        ]
        return names[actionID] ?? actionID
    }
}

extension ActionsPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return sortedKeys.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let key = sortedKeys[row]
        guard let config = configManager.config.builtinItems[key] else { return nil }
        let cell = NSTableCellView()
        switch tableColumn?.identifier.rawValue {
        case "enabled":
            let checkbox = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleEnabled(_:)))
            checkbox.state = config.enabled ? .on : .off
            checkbox.tag = row
            cell.addSubview(checkbox)
        case "name":
            let text = NSTextField(labelWithString: displayName(for: key))
            cell.textField = text
            cell.addSubview(text)
        case "group":
            let text = NSTextField(labelWithString: config.group)
            cell.textField = text
            cell.addSubview(text)
        default:
            return nil
        }
        return cell
    }

    @objc private func toggleEnabled(_ sender: NSButton) {
        let row = sender.tag
        guard row >= 0, row < sortedKeys.count else { return }
        let key = sortedKeys[row]
        guard var config = configManager.config.builtinItems[key] else { return }
        config.enabled = sender.state == .on
        configManager.config.builtinItems[key] = config
        configManager.save()
    }
}

// MARK: - Templates

class TemplatesPreferencesViewController: NSViewController {
    private var tableView: NSTableView!
    private let configManager = ConfigManager.shared

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 660, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Templates"
        setupTable(label: "Templates", items: [
            ("Name", 120), ("Extension", 80), ("Content", 380)
        ])
    }

    private func setupTable(label: String, items: [(String, CGFloat)]) {
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: "Add", target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)

        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, width) in items {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(name.lowercased()))
            col.title = name
            col.width = width
            tableView.addTableColumn(col)
        }
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(editItem)
        tableView.target = self

        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    @objc private func addItem() {
        let editor = TemplateEditorSheet()
        editor.onSave = { [weak self] template in
            self?.configManager.config.templates.append(template)
            self?.configManager.save()
            self?.tableView.reloadData()
        }
        presentAsSheet(editor)
    }

    @objc private func removeItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < configManager.config.templates.count else { return }
        configManager.config.templates.remove(at: row)
        configManager.save()
        tableView.reloadData()
    }

    @objc private func editItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < configManager.config.templates.count else { return }
        let template = configManager.config.templates[row]
        let editor = TemplateEditorSheet(template: template)
        editor.onSave = { [weak self] updated in
            self?.configManager.config.templates[row] = updated
            self?.configManager.save()
            self?.tableView.reloadData()
        }
        presentAsSheet(editor)
    }
}

extension TemplatesPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configManager.config.templates.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let template = configManager.config.templates[row]
        let cell = NSTableCellView()
        switch tableColumn?.identifier.rawValue {
        case "name":
            let text = NSTextField(labelWithString: template.name)
            cell.textField = text; cell.addSubview(text)
        case "extension":
            let text = NSTextField(labelWithString: template.ext)
            cell.textField = text; cell.addSubview(text)
        case "content":
            let text = NSTextField(labelWithString: template.content)
            cell.textField = text; cell.addSubview(text)
        default: return nil
        }
        return cell
    }
}

class TemplateEditorSheet: NSViewController {
    var onSave: ((FileTemplate) -> Void)?
    private var editing: FileTemplate?
    private let nameField = NSTextField()
    private let extField = NSTextField()
    private let contentField = NSTextView()

    init(template: FileTemplate? = nil) {
        self.editing = template
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 280))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var y: CGFloat = 240
        for (label, field, w) in [("Name:", nameField, 120), ("Extension:", extField, 80)] {
            let lbl = NSTextField(labelWithString: label)
            lbl.frame = NSRect(x: 20, y: y, width: 80, height: 20)
            view.addSubview(lbl)
            field.frame = NSRect(x: 110, y: y - 2, width: CGFloat(w), height: 22)
            view.addSubview(field)
            y -= 34
        }
        nameField.stringValue = editing?.name ?? ""
        extField.stringValue = editing?.ext ?? ""

        let srcLabel = NSTextField(labelWithString: "Content:")
        srcLabel.frame = NSRect(x: 20, y: y, width: 80, height: 20)
        view.addSubview(srcLabel)
        let scroll = NSScrollView(frame: NSRect(x: 110, y: 60, width: 270, height: y - 70))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        contentField.string = editing?.content ?? ""
        scroll.documentView = contentField
        view.addSubview(scroll)

        let saveBtn = NSButton(title: "Save", target: self, action: #selector(save))
        saveBtn.frame = NSRect(x: 300, y: 20, width: 80, height: 28)
        view.addSubview(saveBtn)
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelBtn.frame = NSRect(x: 210, y: 20, width: 80, height: 28)
        view.addSubview(cancelBtn)
    }

    @objc private func save() {
        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let tpl = FileTemplate(
            id: editing?.id ?? UUID().uuidString,
            name: name,
            ext: extField.stringValue,
            content: contentField.string
        )
        onSave?(tpl)
        dismiss(nil)
    }

    @objc private func cancel() { dismiss(nil) }
}

// MARK: - Folders

class FoldersPreferencesViewController: NSViewController {
    private var tableView: NSTableView!
    private let configManager = ConfigManager.shared

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 660, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Folders"
        setupTable(label: "Favorite Folders", columns: [("Name", 150), ("Path", 400)])
    }

    private func setupTable(label: String, columns: [(String, CGFloat)]) {
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: "Add", target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, width) in columns {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(name.lowercased()))
            col.title = name
            col.width = width
            tableView.addTableColumn(col)
        }
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self
        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    @objc private func addItem() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let folder = FavoriteFolder(id: UUID().uuidString, name: url.lastPathComponent, path: url.path)
        configManager.config.favoriteFolders.append(folder)
        configManager.save()
        tableView.reloadData()
    }

    @objc private func removeItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < configManager.config.favoriteFolders.count else { return }
        configManager.config.favoriteFolders.remove(at: row)
        configManager.save()
        tableView.reloadData()
    }
}

extension FoldersPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configManager.config.favoriteFolders.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let folder = configManager.config.favoriteFolders[row]
        let cell = NSTableCellView()
        let text = NSTextField(labelWithString: tableColumn?.identifier.rawValue == "name" ? folder.name : folder.path)
        cell.textField = text
        cell.addSubview(text)
        return cell
    }
}

// MARK: - Directories

class DirectoriesPreferencesViewController: NSViewController {
    private var tableView: NSTableView!
    private let configManager = ConfigManager.shared

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 660, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Directories"
        let labelField = NSTextField(labelWithString: "Favorite Directories")
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: "Add", target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, w) in [("Name", 150), ("Path", 400)] {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(name.lowercased()))
            col.title = name
            col.width = CGFloat(w)
            tableView.addTableColumn(col)
        }
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self
        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    @objc private func addItem() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a directory"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let dir = FavoriteDirectory(id: UUID().uuidString, name: url.lastPathComponent, path: url.path)
        configManager.config.favoriteDirectories.append(dir)
        configManager.save()
        tableView.reloadData()
    }

    @objc private func removeItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < configManager.config.favoriteDirectories.count else { return }
        configManager.config.favoriteDirectories.remove(at: row)
        configManager.save()
        tableView.reloadData()
    }
}

extension DirectoriesPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configManager.config.favoriteDirectories.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let dir = configManager.config.favoriteDirectories[row]
        let cell = NSTableCellView()
        let text = NSTextField(labelWithString: tableColumn?.identifier.rawValue == "name" ? dir.name : dir.path)
        cell.textField = text
        cell.addSubview(text)
        return cell
    }
}

// MARK: - Scripts

class ScriptsPreferencesViewController: NSViewController {
    private var tableView: NSTableView!
    private let configManager = ConfigManager.shared

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 660, height: 460))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Scripts"
        let labelField = NSTextField(labelWithString: "Custom Scripts")
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: "Add", target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, w) in [("Name", 150), ("Type", 80), ("Source", 340)] {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(name.lowercased()))
            col.title = name
            col.width = CGFloat(w)
            tableView.addTableColumn(col)
        }
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(editItem)
        tableView.target = self
        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    @objc private func addItem() {
        let editor = ScriptEditorSheet()
        editor.onSave = { [weak self] script in
            self?.configManager.config.customScripts.append(script)
            self?.configManager.save()
            self?.tableView.reloadData()
        }
        presentAsSheet(editor)
    }

    @objc private func removeItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < configManager.config.customScripts.count else { return }
        configManager.config.customScripts.remove(at: row)
        configManager.save()
        tableView.reloadData()
    }

    @objc private func editItem() {
        let row = tableView.selectedRow
        guard row >= 0, row < configManager.config.customScripts.count else { return }
        let script = configManager.config.customScripts[row]
        let editor = ScriptEditorSheet(script: script)
        editor.onSave = { [weak self] updated in
            self?.configManager.config.customScripts[row] = updated
            self?.configManager.save()
            self?.tableView.reloadData()
        }
        presentAsSheet(editor)
    }
}

extension ScriptsPreferencesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return configManager.config.customScripts.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let script = configManager.config.customScripts[row]
        let cell = NSTableCellView()
        let text: String
        switch tableColumn?.identifier.rawValue {
        case "name": text = script.name
        case "type": text = script.type.rawValue
        case "source": text = script.source
        default: text = ""
        }
        let field = NSTextField(labelWithString: text)
        cell.textField = field
        cell.addSubview(field)
        return cell
    }
}

// MARK: - Script Editor Sheet

class ScriptEditorSheet: NSViewController {
    var onSave: ((CustomScript) -> Void)?
    private var editingScript: CustomScript?

    private let nameField = NSTextField()
    private let typePopup = NSPopUpButton()
    private let sourceField = NSTextView()

    init(script: CustomScript? = nil) {
        self.editingScript = script
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let nameLabel = NSTextField(labelWithString: "Name:")
        nameLabel.frame = NSRect(x: 20, y: 260, width: 60, height: 20)
        view.addSubview(nameLabel)

        nameField.frame = NSRect(x: 90, y: 258, width: 290, height: 22)
        nameField.stringValue = editingScript?.name ?? ""
        view.addSubview(nameField)

        let typeLabel = NSTextField(labelWithString: "Type:")
        typeLabel.frame = NSRect(x: 20, y: 228, width: 60, height: 20)
        view.addSubview(typeLabel)

        typePopup.frame = NSRect(x: 90, y: 226, width: 120, height: 24)
        typePopup.addItems(withTitles: ["shell", "python", "appleScript"])
        if let script = editingScript {
            typePopup.selectItem(withTitle: script.type.rawValue)
        }
        view.addSubview(typePopup)

        let sourceLabel = NSTextField(labelWithString: "Source:")
        sourceLabel.frame = NSRect(x: 20, y: 198, width: 60, height: 20)
        view.addSubview(sourceLabel)

        let scrollView = NSScrollView(frame: NSRect(x: 90, y: 60, width: 290, height: 150))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        sourceField.isEditable = true
        sourceField.isSelectable = true
        sourceField.string = editingScript?.source ?? ""
        scrollView.documentView = sourceField
        view.addSubview(scrollView)

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.frame = NSRect(x: 280, y: 20, width: 80, height: 28)
        view.addSubview(saveButton)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: 190, y: 20, width: 80, height: 28)
        view.addSubview(cancelButton)
    }

    @objc private func save() {
        let id = editingScript?.id ?? UUID().uuidString
        let name = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let type = ScriptType(rawValue: typePopup.titleOfSelectedItem ?? "shell") ?? .shell
        let source = sourceField.string
        let script = CustomScript(
            id: id,
            name: name,
            type: type,
            source: source,
            icon: nil,
            sendTypes: ["public.item"],
            sortWeight: editingScript?.sortWeight ?? 1000
        )
        onSave?(script)
        dismiss(nil)
    }

    @objc private func cancel() {
        dismiss(nil)
    }
}
