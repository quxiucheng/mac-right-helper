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
