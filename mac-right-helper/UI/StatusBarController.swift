import Cocoa

class StatusBarController {
    var statusItem: NSStatusItem
    var preferencesWindowController: PreferencesWindowController?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupMenu()
    }

    var menu: NSMenu!

    private func setupMenu() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "list.bullet.rectangle", accessibilityDescription: L("appName"))

        menu = NSMenu()
        let preferencesItem = NSMenuItem(title: L("preferences"), action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        menu.addItem(NSMenuItem.separator())
        let reloadItem = NSMenuItem(title: L("reloadServices"), action: #selector(reloadServices), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        button.action = #selector(handleClick)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 2), in: sender)
        } else {
            (NSApp.delegate as? AppDelegate)?.showMainPanel()
        }
    }

    @objc func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func reloadServices() {
        (NSApp.delegate as? AppDelegate)?.syncActionsToExtension()
        (NSApp.delegate as? AppDelegate)?.mainPanelController?.refreshStatus()
    }
}
