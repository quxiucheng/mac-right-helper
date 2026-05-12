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
