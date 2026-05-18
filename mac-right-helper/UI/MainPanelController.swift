import Cocoa

class MainPanelController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = L("appName")
        window.center()
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        self.init(window: window)
        window.contentViewController = MainPanelViewController()
    }

    func refreshStatus() {
        (window?.contentViewController as? MainPanelViewController)?.refresh()
    }
}

class MainPanelViewController: NSViewController {
    private let permissionManager = PermissionManager()
    private let fdStatus = NSTextField(labelWithString: "")
    private let axStatus = NSTextField(labelWithString: "")
    private let extStatus = NSTextField(labelWithString: "")
    private let actionCount = NSTextField(labelWithString: "")
    private let extWarningLabel = NSTextField(labelWithString: "")
    private var extEnableBtn: NSButton?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let iconView = NSImageView(image: NSImage(systemSymbolName: "list.bullet.rectangle", accessibilityDescription: L("appName")) ?? NSImage())
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let titleLabel = NSTextField(labelWithString: L("appName"))
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)

        let subtitleLabel = NSTextField(labelWithString: L("mainPanelSubtitle"))
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor

        let headerStack = NSStackView(views: [iconView, titleLabel])
        headerStack.orientation = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .centerY

        let headerSection = NSStackView(views: [headerStack, subtitleLabel])
        headerSection.orientation = .vertical
        headerSection.spacing = 4
        headerSection.alignment = .leading

        let separator = NSBox()
        separator.boxType = .separator

        // Status section
        let statusTitle = Self.sectionHeader(L("statusSection"))

        let fdRow = Self.statusRow(label: L("fullDiskAccessStatus"), statusField: fdStatus)
        let axRow = Self.statusRow(label: L("accessibilityStatus"), statusField: axStatus)
        let extRow = Self.statusRow(label: L("finderExtensionStatus"), statusField: extStatus)

        let statusStack = NSStackView(views: [statusTitle, fdRow, axRow, extRow])
        statusStack.orientation = .vertical
        statusStack.spacing = 8
        statusStack.alignment = .leading

        let separator2 = NSBox()
        separator2.boxType = .separator

        // Info + actions
        let countRow = NSStackView(views: [
            NSTextField(labelWithString: L("enabledActionsCount")),
            actionCount
        ])
        countRow.orientation = .horizontal
        countRow.spacing = 8
        countRow.alignment = .centerY
        actionCount.font = NSFont.boldSystemFont(ofSize: 13)

        // Extension warning section (shown when extension is not enabled)
        extWarningLabel.font = NSFont.systemFont(ofSize: 11)
        extWarningLabel.textColor = .systemOrange
        extWarningLabel.isHidden = true

        let extBtn = NSButton(title: L("openExtensionSettings"), target: self, action: #selector(openExtensionSettings))
        extBtn.isHidden = true
        self.extEnableBtn = extBtn

        let extWarningStack = NSStackView(views: [extWarningLabel, extBtn])
        extWarningStack.orientation = .vertical
        extWarningStack.spacing = 4
        extWarningStack.alignment = .leading

        let reloadBtn = NSButton(title: L("reloadServices"), target: self, action: #selector(reloadServices))
        let axBtn = NSButton(title: L("requestAccessibility"), target: self, action: #selector(requestAccessibility))
        let prefsBtn = NSButton(title: L("preferences"), target: self, action: #selector(openPreferences))
        let buttonRow = NSStackView(views: [reloadBtn, axBtn, prefsBtn])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 12
        buttonRow.alignment = .centerY

        let contentStack = NSStackView(views: [
            headerSection,
            separator,
            statusStack,
            separator2,
            countRow,
            extWarningStack,
            buttonRow
        ])
        contentStack.orientation = .vertical
        contentStack.spacing = 16
        contentStack.alignment = .leading
        contentStack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -48),
            separator2.widthAnchor.constraint(equalTo: contentStack.widthAnchor, constant: -48),
        ])

        refresh()
    }

    func refresh() {
        let fdGranted = permissionManager.fullDiskAccessStatus == .granted
        fdStatus.stringValue = fdGranted ? L("granted") : L("notGranted")
        fdStatus.textColor = fdGranted ? .systemGreen : .systemRed

        let axGranted = permissionManager.accessibilityStatus == .granted
        axStatus.stringValue = axGranted ? L("granted") : L("notGranted")
        axStatus.textColor = axGranted ? .systemGreen : .systemRed

        let extRunning = (NSApp.delegate as? AppDelegate)?.extensionRunning ?? false
        let extEnabled = ExtensionManager.isExtensionEnabled()
        if extEnabled {
            extStatus.stringValue = extRunning ? L("connected") : L("disconnected")
            extStatus.textColor = extRunning ? .systemGreen : .secondaryLabelColor
        } else {
            extStatus.stringValue = L("notEnabled")
            extStatus.textColor = .systemOrange
        }

        extWarningLabel.stringValue = L("extensionNotEnabledHint")
        extWarningLabel.isHidden = extEnabled
        extEnableBtn?.isHidden = extEnabled

        let count = ConfigManager.shared.config.builtinItems.filter { $0.value.enabled }.count
        actionCount.stringValue = String(count)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        refresh()
    }

    @objc private func reloadServices() {
        (NSApp.delegate as? AppDelegate)?.syncActionsToExtension()
        refresh()
    }

    @objc private func requestAccessibility() {
        (NSApp.delegate as? AppDelegate)?.requestAccessibilityPermission()
    }

    @objc private func openPreferences() {
        (NSApp.delegate as? AppDelegate)?.showPreferences()
    }

    @objc private func openExtensionSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions?Finder")!
        NSWorkspace.shared.open(url)
    }

    private static func sectionHeader(_ title: String) -> NSTextField {
        let header = NSTextField(labelWithString: title)
        header.font = NSFont.boldSystemFont(ofSize: 11)
        header.textColor = .secondaryLabelColor
        return header
    }

    private static func statusRow(label: String, statusField: NSTextField) -> NSStackView {
        let lbl = NSTextField(labelWithString: label)
        lbl.alignment = .right
        lbl.widthAnchor.constraint(equalToConstant: 140).isActive = true
        statusField.font = NSFont.boldSystemFont(ofSize: 13)
        let row = NSStackView(views: [lbl, statusField])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        return row
    }
}
