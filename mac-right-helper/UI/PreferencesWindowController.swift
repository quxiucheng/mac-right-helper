import Cocoa

class PreferencesWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L("preferences")
        window.center()
        self.init(window: window)
        window.contentViewController = PreferencesTabViewController()
    }
}

class PreferencesTabViewController: NSTabViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        addTab(GeneralPreferencesViewController(), label: L("generalTab"))
        addTab(ActionsPreferencesViewController(), label: L("actionsTab"))
        addTab(TemplatesPreferencesViewController(), label: L("templatesTab"))
        addTab(FoldersPreferencesViewController(), label: L("foldersTab"))
        addTab(DirectoriesPreferencesViewController(), label: L("directoriesTab"))
        addTab(ScriptsPreferencesViewController(), label: L("scriptsTab"))
    }

    private func addTab(_ vc: NSViewController, label: String) {
        let item = NSTabViewItem(viewController: vc)
        item.label = label
        vc.title = label
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
        self.title = L("generalTab")
        let settings = configManager.config.settings

        var y: CGFloat = 420

        let hideIconCheckbox = NSButton(checkboxWithTitle: L("hideStatusBarIcon"), target: self, action: #selector(toggleHideIcon(_:)))
        hideIconCheckbox.state = settings.hideStatusBarIcon ? .on : .off
        hideIconCheckbox.frame = NSRect(x: 20, y: y, width: 300, height: 22)
        view.addSubview(hideIconCheckbox)
        y -= 36

        let trashLabel = NSTextField(labelWithString: L("trashConfirmation"))
        trashLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(trashLabel)
        let trashCheckbox = NSButton(checkboxWithTitle: L("trashConfirmDesc"), target: self, action: #selector(toggleTrashConfirm(_:)))
        trashCheckbox.state = settings.trashConfirm ? .on : .off
        trashCheckbox.frame = NSRect(x: 160, y: y, width: 400, height: 22)
        view.addSubview(trashCheckbox)
        y -= 36

        let cutLabel = NSTextField(labelWithString: L("cutBehavior"))
        cutLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(cutLabel)
        let cutCheckbox = NSButton(checkboxWithTitle: L("cutHideDesc"), target: self, action: #selector(toggleCutHide(_:)))
        cutCheckbox.state = settings.cutHideFiles ? .on : .off
        cutCheckbox.frame = NSRect(x: 160, y: y, width: 400, height: 22)
        view.addSubview(cutCheckbox)
        y -= 36

        let terminalLabel = NSTextField(labelWithString: L("terminalOpenMode"))
        terminalLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(terminalLabel)
        let terminalPopup = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 180, height: 24))
        terminalPopup.addItems(withTitles: [L("newWindow"), L("newTab")])
        terminalPopup.selectItem(at: settings.terminalOpenMode == .newWindow ? 0 : 1)
        terminalPopup.target = self
        terminalPopup.action = #selector(terminalModeChanged(_:))
        view.addSubview(terminalPopup)
        y -= 44

        let editorLabel = NSTextField(labelWithString: L("defaultEditor"))
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
        y -= 44

        let langLabel = NSTextField(labelWithString: L("languageLabel"))
        langLabel.frame = NSRect(x: 20, y: y, width: 140, height: 20)
        view.addSubview(langLabel)
        let langPopup = NSPopUpButton(frame: NSRect(x: 160, y: y, width: 180, height: 24))
        langPopup.addItems(withTitles: ["中文", "English"])
        langPopup.selectItem(at: settings.language == .chinese ? 0 : 1)
        langPopup.target = self
        langPopup.action = #selector(languageChanged(_:))
        view.addSubview(langPopup)
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

    @objc private func languageChanged(_ sender: NSPopUpButton) {
        configManager.config.settings.language = sender.indexOfSelectedItem == 0 ? .chinese : .english
        configManager.save()
        let alert = NSAlert()
        alert.messageText = L("languageLabel")
        alert.informativeText = L("restartToApply")
        alert.alertStyle = .informational
        alert.runModal()
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
        self.title = L("actionsTab")
        let label = NSTextField(labelWithString: L("builtinActions"))
        label.font = NSFont.boldSystemFont(ofSize: 13)
        label.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(label)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 400))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        tableView = NSTableView()
        tableView.allowsMultipleSelection = false

        let enabledCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("enabled"))
        enabledCol.title = L("enabled")
        enabledCol.width = 60
        tableView.addTableColumn(enabledCol)

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = L("name")
        nameCol.width = 240
        tableView.addTableColumn(nameCol)

        let groupCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("group"))
        groupCol.title = L("group")
        groupCol.width = 100
        tableView.addTableColumn(groupCol)

        tableView.headerView = NSTableHeaderView()
        tableView.delegate = self
        tableView.dataSource = self

        scrollView.documentView = tableView
        view.addSubview(scrollView)
    }

    private func displayName(for actionID: String) -> String {
        return L(actionID)
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
            let text = NSTextField(labelWithString: L("group" + config.group))
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
        self.title = L("templatesTab")
        setupTable(label: L("templatesTab"), items: [
            (L("name"), 120), (L("extensionLabel"), 80), (L("content"), 380)
        ])
    }

    private func setupTable(label: String, items: [(String, CGFloat)]) {
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: L("add"), target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)

        let removeButton = NSButton(title: L("remove"), target: self, action: #selector(removeItem))
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
        for (label, field, w) in [(L("templateName"), nameField, 120), (L("templateExtension"), extField, 80)] {
            let lbl = NSTextField(labelWithString: label)
            lbl.frame = NSRect(x: 20, y: y, width: 80, height: 20)
            view.addSubview(lbl)
            field.frame = NSRect(x: 110, y: y - 2, width: CGFloat(w), height: 22)
            view.addSubview(field)
            y -= 34
        }
        nameField.stringValue = editing?.name ?? ""
        extField.stringValue = editing?.ext ?? ""

        let srcLabel = NSTextField(labelWithString: L("templateContent"))
        srcLabel.frame = NSRect(x: 20, y: y, width: 80, height: 20)
        view.addSubview(srcLabel)
        let scroll = NSScrollView(frame: NSRect(x: 110, y: 60, width: 270, height: y - 70))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        contentField.string = editing?.content ?? ""
        scroll.documentView = contentField
        view.addSubview(scroll)

        let saveBtn = NSButton(title: L("save"), target: self, action: #selector(save))
        saveBtn.frame = NSRect(x: 300, y: 20, width: 80, height: 28)
        view.addSubview(saveBtn)
        let cancelBtn = NSButton(title: L("cancel"), target: self, action: #selector(cancel))
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
        self.title = L("foldersTab")
        setupTable(label: L("favoriteFolders"), columns: [(L("name"), 150), (L("path"), 400)])
    }

    private func setupTable(label: String, columns: [(String, CGFloat)]) {
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: L("add"), target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)
        let removeButton = NSButton(title: L("remove"), target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, w) in columns {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(name.lowercased()))
            col.title = name
            col.width = w
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
        panel.message = L("chooseFolder")
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
        self.title = L("directoriesTab")
        let labelField = NSTextField(labelWithString: L("favoriteDirectories"))
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: L("add"), target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)
        let removeButton = NSButton(title: L("remove"), target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, w) in [(L("name"), 150), (L("path"), 400)] {
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
        panel.message = L("chooseDirectoryPanel")
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
        self.title = L("scriptsTab")
        let labelField = NSTextField(labelWithString: L("customScripts"))
        labelField.font = NSFont.boldSystemFont(ofSize: 13)
        labelField.frame = NSRect(x: 20, y: 430, width: 200, height: 20)
        view.addSubview(labelField)

        let addButton = NSButton(title: L("add"), target: self, action: #selector(addItem))
        addButton.frame = NSRect(x: 20, y: 400, width: 80, height: 28)
        view.addSubview(addButton)
        let removeButton = NSButton(title: L("remove"), target: self, action: #selector(removeItem))
        removeButton.frame = NSRect(x: 110, y: 400, width: 80, height: 28)
        view.addSubview(removeButton)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 20, width: 620, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        tableView = NSTableView()
        tableView.allowsMultipleSelection = false
        for (name, w) in [(L("name"), 150), (L("type"), 80), (L("source"), 340)] {
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

        let nameLabel = NSTextField(labelWithString: L("scriptName"))
        nameLabel.frame = NSRect(x: 20, y: 260, width: 60, height: 20)
        view.addSubview(nameLabel)

        nameField.frame = NSRect(x: 90, y: 258, width: 290, height: 22)
        nameField.stringValue = editingScript?.name ?? ""
        view.addSubview(nameField)

        let typeLabel = NSTextField(labelWithString: L("scriptType"))
        typeLabel.frame = NSRect(x: 20, y: 228, width: 60, height: 20)
        view.addSubview(typeLabel)

        typePopup.frame = NSRect(x: 90, y: 226, width: 120, height: 24)
        typePopup.addItems(withTitles: ["shell", "python", "appleScript"])
        if let script = editingScript {
            typePopup.selectItem(withTitle: script.type.rawValue)
        }
        view.addSubview(typePopup)

        let sourceLabel = NSTextField(labelWithString: L("scriptSource"))
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

        let saveButton = NSButton(title: L("save"), target: self, action: #selector(save))
        saveButton.frame = NSRect(x: 280, y: 20, width: 80, height: 28)
        view.addSubview(saveButton)

        let cancelButton = NSButton(title: L("cancel"), target: self, action: #selector(cancel))
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
