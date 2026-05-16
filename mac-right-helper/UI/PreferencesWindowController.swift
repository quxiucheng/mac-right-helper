import Cocoa

class PreferencesWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 600, height: 450)
        window.title = L("preferences")
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        window.tabbingMode = .disallowed
        self.init(window: window)
        window.contentViewController = PreferencesTabViewController()
    }
}

class PreferencesTabViewController: NSTabViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        addTab(GeneralPreferencesViewController(), label: L("generalTab"), symbolName: "gearshape")
        addTab(ActionsPreferencesViewController(), label: L("actionsTab"), symbolName: "checklist")
        addTab(TemplatesPreferencesViewController(), label: L("templatesTab"), symbolName: "doc.text")
        addTab(FoldersPreferencesViewController(), label: L("foldersTab"), symbolName: "folder")
        addTab(DirectoriesPreferencesViewController(), label: L("directoriesTab"), symbolName: "externaldrive")
        addTab(ScriptsPreferencesViewController(), label: L("scriptsTab"), symbolName: "terminal")
    }

    private func addTab(_ vc: NSViewController, label: String, symbolName: String) {
        let item = NSTabViewItem(viewController: vc)
        item.label = label
        item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
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

        let hideIconCheckbox = NSButton(checkboxWithTitle: L("hideStatusBarIcon"), target: self, action: #selector(toggleHideIcon(_:)))
        hideIconCheckbox.state = settings.hideStatusBarIcon ? .on : .off

        let trashCheckbox = NSButton(checkboxWithTitle: L("trashConfirmDesc"), target: self, action: #selector(toggleTrashConfirm(_:)))
        trashCheckbox.state = settings.trashConfirm ? .on : .off

        let cutCheckbox = NSButton(checkboxWithTitle: L("cutHideDesc"), target: self, action: #selector(toggleCutHide(_:)))
        cutCheckbox.state = settings.cutHideFiles ? .on : .off

        let terminalPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        terminalPopup.addItems(withTitles: [L("newWindow"), L("newTab")])
        terminalPopup.selectItem(at: settings.terminalOpenMode == .newWindow ? 0 : 1)
        terminalPopup.target = self
        terminalPopup.action = #selector(terminalModeChanged(_:))

        let editorPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        for editor in EditorConfig.allEditors {
            editorPopup.addItem(withTitle: editor.name)
        }
        if let idx = EditorConfig.allEditors.firstIndex(where: { $0.bundleID == settings.defaultEditor }) {
            editorPopup.selectItem(at: idx)
        }
        editorPopup.target = self
        editorPopup.action = #selector(defaultEditorChanged(_:))

        let langPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        langPopup.addItems(withTitles: ["中文", "English"])
        langPopup.selectItem(at: settings.language == .chinese ? 0 : 1)
        langPopup.target = self
        langPopup.action = #selector(languageChanged(_:))

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.spacing = 24
        contentStack.alignment = .leading
        contentStack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        contentStack.addArrangedSubview(Self.sectionHeader(L("appearanceSection")))
        contentStack.addArrangedSubview(Self.checkboxRow(hideIconCheckbox))

        contentStack.addArrangedSubview(Self.sectionHeader(L("fileOperationsSection")))
        contentStack.addArrangedSubview(Self.labeledRow(L("trashConfirmation"), trashCheckbox))
        contentStack.addArrangedSubview(Self.labeledRow(L("cutBehavior"), cutCheckbox))

        contentStack.addArrangedSubview(Self.sectionHeader(L("terminalEditorSection")))
        contentStack.addArrangedSubview(Self.labeledRow(L("terminalOpenMode"), terminalPopup))
        contentStack.addArrangedSubview(Self.labeledRow(L("defaultEditor"), editorPopup))

        contentStack.addArrangedSubview(Self.sectionHeader(L("languageSection")))
        contentStack.addArrangedSubview(Self.labeledRow(L("languageLabel"), langPopup))
    }

    private static func sectionHeader(_ title: String) -> NSTextField {
        let header = NSTextField(labelWithString: title)
        header.font = NSFont.boldSystemFont(ofSize: 11)
        header.textColor = .secondaryLabelColor
        return header
    }

    private static func labeledRow(_ labelText: String, _ control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: labelText)
        label.alignment = .right
        label.widthAnchor.constraint(equalToConstant: 140).isActive = true
        let row = NSStackView(views: [label, control])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }

    private static func checkboxRow(_ checkbox: NSButton) -> NSStackView {
        let spacer = NSView()
        spacer.widthAnchor.constraint(equalToConstant: 148).isActive = true
        let row = NSStackView(views: [spacer, checkbox])
        row.orientation = .horizontal
        row.alignment = .centerY
        return row
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
        let cell = PaddedTableCellView()
        switch tableColumn?.identifier.rawValue {
        case "enabled":
            cell.configureCheckbox(state: config.enabled ? .on : .off, tag: row, target: self, action: #selector(toggleEnabled(_:)))
        case "name":
            cell.configure(with: displayName(for: key))
        case "group":
            cell.configure(with: L("group" + config.group))
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
        let cell = PaddedTableCellView()
        switch tableColumn?.identifier.rawValue {
        case "name": cell.configure(with: template.name)
        case "extension": cell.configure(with: template.ext)
        case "content": cell.configure(with: template.content)
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
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 340))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.stringValue = editing?.name ?? ""
        extField.stringValue = editing?.ext ?? ""

        let nameRow = Self.fieldRow(label: L("templateName"), field: nameField, fieldWidth: 200)
        let extRow = Self.fieldRow(label: L("templateExtension"), field: extField, fieldWidth: 100)

        let contentLabel = NSTextField(labelWithString: L("templateContent"))
        contentLabel.alignment = .right
        contentLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let contentScroll = NSScrollView()
        contentScroll.hasVerticalScroller = true
        contentScroll.borderType = .bezelBorder
        contentField.string = editing?.content ?? ""
        contentField.isEditable = true
        contentField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        contentScroll.documentView = contentField
        contentScroll.heightAnchor.constraint(equalToConstant: 150).isActive = true
        let contentRow = NSStackView(views: [contentLabel, contentScroll])
        contentRow.orientation = .horizontal
        contentRow.spacing = 8
        contentRow.alignment = .top

        let saveBtn = NSButton(title: L("save"), target: self, action: #selector(save))
        saveBtn.keyEquivalent = "\r"
        let cancelBtn = NSButton(title: L("cancel"), target: self, action: #selector(cancel))
        let buttonRow = NSStackView(views: [cancelBtn, saveBtn])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 12
        buttonRow.alignment = .centerY
        buttonRow.distribution = .fill

        let stack = NSStackView(views: [nameRow, extRow, contentRow, buttonRow])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ])
    }

    private static func fieldRow(label: String, field: NSControl, fieldWidth: CGFloat) -> NSStackView {
        let lbl = NSTextField(labelWithString: label)
        lbl.alignment = .right
        lbl.widthAnchor.constraint(equalToConstant: 80).isActive = true
        field.widthAnchor.constraint(equalToConstant: fieldWidth).isActive = true
        let row = NSStackView(views: [lbl, field])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
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
        let cell = PaddedTableCellView()
        cell.configure(with: tableColumn?.identifier.rawValue == "name" ? folder.name : folder.path)
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
        let cell = PaddedTableCellView()
        cell.configure(with: tableColumn?.identifier.rawValue == "name" ? dir.name : dir.path)
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
        let cell = PaddedTableCellView()
        switch tableColumn?.identifier.rawValue {
        case "name": cell.configure(with: script.name)
        case "type": cell.configure(with: script.type.rawValue)
        case "source": cell.configure(with: script.source)
        default: break
        }
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
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 440, height: 340))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.stringValue = editingScript?.name ?? ""

        let nameRow = Self.fieldRow(label: L("scriptName"), field: nameField, fieldWidth: 290)

        let typeLabel = NSTextField(labelWithString: L("scriptType"))
        typeLabel.alignment = .right
        typeLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        typePopup.addItems(withTitles: ["shell", "python", "appleScript"])
        if let script = editingScript {
            typePopup.selectItem(withTitle: script.type.rawValue)
        }
        let typeRow = NSStackView(views: [typeLabel, typePopup])
        typeRow.orientation = .horizontal
        typeRow.spacing = 8
        typeRow.alignment = .centerY

        let sourceLabel = NSTextField(labelWithString: L("scriptSource"))
        sourceLabel.alignment = .right
        sourceLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        sourceField.isEditable = true
        sourceField.isSelectable = true
        sourceField.string = editingScript?.source ?? ""
        sourceField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        scrollView.documentView = sourceField
        scrollView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        let sourceRow = NSStackView(views: [sourceLabel, scrollView])
        sourceRow.orientation = .horizontal
        sourceRow.spacing = 8
        sourceRow.alignment = .top

        let saveButton = NSButton(title: L("save"), target: self, action: #selector(save))
        saveButton.keyEquivalent = "\r"
        let cancelButton = NSButton(title: L("cancel"), target: self, action: #selector(cancel))
        let buttonRow = NSStackView(views: [cancelButton, saveButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 12
        buttonRow.alignment = .centerY
        buttonRow.distribution = .fill

        let stack = NSStackView(views: [nameRow, typeRow, sourceRow, buttonRow])
        stack.orientation = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor),
        ])
    }

    private static func fieldRow(label: String, field: NSControl, fieldWidth: CGFloat) -> NSStackView {
        let lbl = NSTextField(labelWithString: label)
        lbl.alignment = .right
        lbl.widthAnchor.constraint(equalToConstant: 80).isActive = true
        field.widthAnchor.constraint(equalToConstant: fieldWidth).isActive = true
        let row = NSStackView(views: [lbl, field])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
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
