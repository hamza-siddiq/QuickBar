import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var state: QuickMacState!
    var passwordCompletion: ((String?) -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        state = QuickMacState()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "QuickMac")
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: QuickMacView(state: state, delegate: self))
    }

    @objc private func appDidActivate(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier,
           app.activationPolicy == .regular {
            state.frontmostAppBundleID = app.bundleIdentifier
        }
    }

    @objc func handleStatusItemClick(_ sender: AnyObject?) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit QuickMac", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    func showPasswordPrompt(completion: @escaping (String?) -> Void) {
        passwordCompletion = completion

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 280, height: 220),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: PasswordPromptView(
            onConfirm: { [weak self, weak window] password in
                self?.passwordCompletion?(password)
                self?.passwordCompletion = nil
                window?.close()
            },
            onCancel: { [weak self, weak window] in
                self?.passwordCompletion?(nil)
                self?.passwordCompletion = nil
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showKillFrozenAppDialog() {
        let apps = QuickMacServices.shared.getRunningApps()

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 400),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: KillAppPickerView(
            apps: apps,
            onQuit: { [weak window] app in
                QuickMacServices.shared.forceQuitApp(app)
                window?.close()
            },
            onCancel: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showLargeFilesDialog(files: [LargeFile]) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 450),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: LargeFilesView(
            files: files,
            onDismiss: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showForceEjectDialog(volumes: [String]) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 300),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: ForceEjectView(
            volumes: volumes,
            onEject: { [weak window] volume in
                _ = QuickMacServices.shared.forceEjectVolume(volume)
                window?.close()
            },
            onDismiss: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showQuarantineDialog() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 280, height: 260),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: QuarantinePickerView(
            onPick: { [weak window] url in
                _ = QuickMacServices.shared.removeQuarantine(from: url)
                window?.close()
            },
            onDismiss: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showScheduledShutdownDialog() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 280, height: 380),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: ScheduledShutdownView(
            onSchedule: { [weak self, weak window] date in
                self?.handleScheduledShutdown(date: date)
                window?.close()
            },
            onDismiss: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showCancelShutdownDialog() {
        guard let scheduledTime = state.scheduledShutdownTime else { return }

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 280, height: 260),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: CancelShutdownView(
            scheduledTime: scheduledTime,
            onCancel: { [weak self, weak window] in
                self?.handleCancelShutdown()
                window?.close()
            },
            onDismiss: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showProcessMonitorDialog() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = ""
        window.level = .floating
        window.center()
        window.isReleasedWhenClosed = false

        let hostingView = NSHostingView(rootView: ProcessMonitorView(
            onDismiss: { [weak window] in
                window?.close()
            }
        ))
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleScheduledShutdown(date: Date) {
        guard let password = state.adminPassword else {
            showPasswordPrompt { [weak self] password in
                guard let password, let self else { return }
                state.adminPassword = password
                executeScheduledShutdown(date: date, password: password)
            }
            return
        }
        executeScheduledShutdown(date: date, password: password)
    }

    private func executeScheduledShutdown(date: Date, password: String) {
        DispatchQueue.main.async {
            self.state.lastActionStatus = .inProgress
            self.state.lastAction = "Scheduling shutdown..."
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = QuickMacServices.shared.scheduledShutdown(date: date, adminPassword: password)

            DispatchQueue.main.async {
                switch result {
                case .success(let pid):
                    let formatter = DateFormatter()
                    formatter.dateFormat = "h:mm a"
                    self.state.isShutdownScheduled = true
                    self.state.scheduledShutdownTime = date
                    self.state.shutdownPID = pid
                    self.state.lastActionStatus = .success
                    self.state.lastAction = "Shutdown scheduled for \(formatter.string(from: date))"
                case .failure(let error):
                    self.state.adminPassword = nil
                    self.state.lastActionStatus = .failure
                    self.state.lastAction = error.localizedDescription
                }
            }
        }
    }

    private func handleCancelShutdown() {
        guard let password = state.adminPassword else {
            showPasswordPrompt { [weak self] password in
                guard let password, let self else { return }
                state.adminPassword = password
                executeCancelShutdown(password: password)
            }
            return
        }
        executeCancelShutdown(password: password)
    }

    private func executeCancelShutdown(password: String) {
        guard let pid = state.shutdownPID else {
            state.isShutdownScheduled = false
            state.scheduledShutdownTime = nil
            state.shutdownPID = nil
            state.lastActionStatus = .success
            state.lastAction = "Scheduled shutdown canceled"
            return
        }

        DispatchQueue.main.async {
            self.state.lastActionStatus = .inProgress
            self.state.lastAction = "Canceling shutdown..."
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = QuickMacServices.shared.cancelScheduledShutdown(pid: pid, adminPassword: password)

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.state.isShutdownScheduled = false
                    self.state.scheduledShutdownTime = nil
                    self.state.shutdownPID = nil
                    self.state.lastActionStatus = .success
                    self.state.lastAction = "Scheduled shutdown canceled"
                case .failure(let error):
                    self.state.adminPassword = nil
                    self.state.lastActionStatus = .failure
                    self.state.lastAction = error.localizedDescription
                }
            }
        }
    }
}
