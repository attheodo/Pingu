//
//  Application.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Cocoa
import ServiceManagement

class Pingu: NSObject {
    
    // MARK: - Private Properties
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var preferencesPanel: NSPanel?
    private var preferencesPanelPending = false
    private weak var pendingMenu: NSMenu?
    private var panelPresentationScheduled = false
    private var menuTrackingEndObservation: NSObjectProtocol?
    private var savedHosts: SavedHosts
    private var pingService: PingService
    private var chartView: ChartView
    private let launchAtLoginService = SMAppService.loginItem(identifier: pinguLauncherBundleId)
    
    // MARK: - Lifecycle
    
    override init() {
        
        self.chartView = ChartView()
        self.pingService = PingService()
        self.savedHosts = SavedHosts.load(fromStore: UserDefaults.standard)

        super.init()

        if let selectedHost = savedHosts.selectedHost {
            
            startPinging(host: selectedHost)
        
        } else {
            
            let defaultHost = Host(host: "www.google.com", interval: .seconds(1))
            
            savedHosts.add(defaultHost)
            savedHosts.save(toStore: UserDefaults.standard)
            
            startPinging(host: defaultHost)
            
        }
        
        configureMenu()

        menuTrackingEndObservation = NotificationCenter.default.addObserver(
            forName: NSMenu.didEndTrackingNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let menu = notification.object as? NSMenu,
                  self.preferencesPanelPending,
                  menu === self.pendingMenu else { return }

            self.presentPendingPreferencesPanel()
        }
        
        if let button = statusItem.button {
            chartView.attach(to: button)
        }
        statusItem.length = chartView.desiredWidth
        
    }

    deinit {
        if let observation = menuTrackingEndObservation {
            NotificationCenter.default.removeObserver(observation)
        }
    }

    // MARK: - Private Properties
    
    fileprivate func configureMenu() {
        let menu = NSMenu()
        if !savedHosts.hosts.isEmpty {
            
            for host in savedHosts.hosts {
                
                let hostItem = HostMenuItem(host: host, action: #selector(self.didSelectHostItem(_:)))
                hostItem.target = self
                hostItem.state = host.selected ? .on : .off
                
                menu.addItem(hostItem)
                
            }
            
            menu.addItem(.separator())
            
        }
        
        if pingService.isPinging {
            
            let item = NSMenuItem(title: "Pause", action: #selector(self.didSelectStopPinging), keyEquivalent: "")
            item.target = self
            
            menu.addItem(item)
            menu.addItem(.separator())
        
        } else {
            
            if let _ = savedHosts.selectedHost {
                
                let item = NSMenuItem(title: "Resume", action: #selector(self.didSelectStartPinging), keyEquivalent: "")
                item.target = self
                
                menu.addItem(item)
                menu.addItem(.separator())
                
            }
            
        }
        
        let preferencesMenuItem = NSMenuItem(title: "Add host...",
                                             action: #selector(didSelectPrefencesMenuItem),
                                             keyEquivalent: "")
        preferencesMenuItem.target = self
        
        let launchAtLogin = NSMenuItem(title: "Launch at login",
                                             action: #selector(didSelectLaunchAtLogin),
                                             keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = launchAtLoginService.status == .enabled ? .on : .off
        
        let quitMenuItem = NSMenuItem(title: "Quit",
                                       action: #selector(didSelectQuitMenuItem),
                                       keyEquivalent: "")
        quitMenuItem.target = self
        
        menu.addItem(preferencesMenuItem)
        menu.addItem(launchAtLogin)
        menu.addItem(quitMenuItem)

        // Custom host views determine most of the menu width. Keep native
        // items wide enough for their titles, including the login option.
        let menuFont = NSFont.menuFont(ofSize: 0)
        let widestTitle = menu.items
            .map(\.title)
            .filter { !$0.isEmpty }
            .map { ($0 as NSString).size(withAttributes: [.font: menuFont]).width }
            .max() ?? 0
        menu.minimumWidth = ceil(widestTitle) + 64

        statusItem.button?.target = nil
        statusItem.button?.action = nil
        statusItem.menu = menu

    }
    
    // MARK: - Private methods
    
    fileprivate func showPreferencesPanel() {
        guard preferencesPanel == nil else { return }

        let controller = PreferencesViewController(pingService: pingService, delegate: self)
        // Load the view before the panel is ordered. This applies the text
        // service settings before AppKit can create a remote completion view
        // while the panel is entering the window hierarchy.
        _ = controller.view
        let panel = NSPanel(contentViewController: controller)
        panel.title = "Add Host"
        panel.styleMask = [.titled, .closable, .utilityWindow]
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.moveToActiveSpace, .transient]
        panel.delegate = self
        // The panel needs titled-window keyboard ownership, but a menu-bar
        // utility should not show standard window controls.
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        preferencesPanel = panel

        // The menu is detached while this panel is open. Let the same status
        // item dismiss the panel until normal menu behavior is restored.
        statusItem.button?.target = self
        statusItem.button?.action = #selector(didSelectStatusItemWithPreferencesPanelOpen)

        positionPreferencesPanel(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        controller.activateHostInput()
    }
    
    fileprivate func hidePreferencesPanel() {
        preferencesPanelPending = false
        pendingMenu = nil
        statusItem.button?.target = nil
        statusItem.button?.action = nil
        if let panel = preferencesPanel {
            // End field editing before closing so AppKit can detach its text
            // service views from the panel in the correct window lifecycle.
            panel.makeFirstResponder(nil)
            DispatchQueue.main.async {
                panel.close()
            }
            return
        }

        configureMenu()
    }

    private func requestPreferencesPanel() {
        preferencesPanelPending = true
        pendingMenu = nil

        if let panel = preferencesPanel {
            panel.makeKeyAndOrderFront(nil)
            if let controller = panel.contentViewController as? PreferencesViewController {
                controller.activateHostInput()
            }
            preferencesPanelPending = false
            return
        }

        if let menu = statusItem.menu {
            pendingMenu = menu
            // The menu must finish tracking before it is detached. The menu
            // tracking notification schedules panel presentation afterward.
            menu.cancelTrackingWithoutAnimation()

            // Keep a fallback for macOS versions that deliver the tracking
            // notification after the menu reference has changed. It runs only
            // if the same menu is still attached and no presentation started.
            DispatchQueue.main.async { [weak self, weak menu] in
                guard let self,
                      let menu,
                      self.preferencesPanelPending,
                      self.preferencesPanel == nil,
                      self.statusItem.menu === menu else { return }

                self.presentPendingPreferencesPanel()
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.presentPendingPreferencesPanel()
        }
    }

    private func presentPendingPreferencesPanel() {
        guard preferencesPanelPending,
              preferencesPanel == nil,
              !panelPresentationScheduled else { return }

        preferencesPanelPending = false
        pendingMenu = nil
        panelPresentationScheduled = true

        // Detach only after menu tracking has ended. Present the key panel on
        // the next run-loop turn so it does not compete with menu tracking for
        // keyboard events.
        statusItem.menu = nil

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.panelPresentationScheduled = false
            guard self.preferencesPanel == nil else { return }
            self.showPreferencesPanel()
        }
    }

    private func positionPreferencesPanel(_ panel: NSPanel) {
        guard let button = statusItem.button,
              let buttonWindow = button.window else {
            panel.center()
            return
        }

        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screenFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var origin = NSPoint(x: buttonRect.midX - panel.frame.width / 2,
                             y: buttonRect.minY - panel.frame.height - 8)
        origin.x = min(max(origin.x, screenFrame.minX), screenFrame.maxX - panel.frame.width)
        origin.y = max(origin.y, screenFrame.minY)
        panel.setFrameOrigin(origin)
    }
    
    fileprivate func startPinging(host: Host) {
        
        pingService.startPinging(host: host.host,
                                 interval: host.interval.timeInterval)
        { [weak self] pingResult in
            
            DispatchQueue.main.async {
                self?.chartView.addResult(pingResult)
                self?.statusItem.length = self?.chartView.desiredWidth ?? 0
            }
            
        }
        
    }
    
    fileprivate func stopPinging() {
        
        pingService.stopPinging()
        configureMenu()
        chartView.setPausedState(true)
        
    }
    
    // MARK: - Selectors
    
    @objc fileprivate func didSelectPrefencesMenuItem() {
        requestPreferencesPanel()
    }

    @objc private func didSelectStatusItemWithPreferencesPanelOpen() {
        hidePreferencesPanel()
    }
    
    @objc fileprivate func didSelectQuitMenuItem() {
        NSApp.terminate(self)
    }
    
    @objc fileprivate func didSelectHostItem(_ item: HostMenuItem) {
        
        savedHosts.setSelected(item.host)
        savedHosts.save(toStore: UserDefaults.standard)
        
        startPinging(host: item.host)
        chartView.reset()
        configureMenu()
        
    }
    
    @objc fileprivate func didSelectStopPinging() {
        stopPinging()
    }
    
    @objc fileprivate func didSelectStartPinging() {
        
        guard let selectedHost = savedHosts.selectedHost else { return }
        
        startPinging(host: selectedHost)
        configureMenu()
        
    }
    
    @objc fileprivate func didSelectLaunchAtLogin() {

        do {
            switch launchAtLoginService.status {
            case .enabled:
                try launchAtLoginService.unregister()
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
            case .notRegistered, .notFound:
                try launchAtLoginService.register()
            @unknown default:
                try launchAtLoginService.register()
            }
        } catch {
            NSLog("Could not update Launch at login: \(error.localizedDescription)")
        }

        configureMenu()

    }
    
}

// MARK: - PreferencesViewControllerDelegate

extension Pingu: PreferencesViewControllerDelegate {
    
    func preferencesViewController(_ ctrl: PreferencesViewController,
                                   didAddHost host: String, interval: PingInterval)
    {
        let h = Host(host: host, interval: interval)
        savedHosts.add(h)
        savedHosts.save(toStore: UserDefaults.standard)
        
        startPinging(host: h)
        
        hidePreferencesPanel()
        
    }

}

// MARK: - NSWindowDelegate

extension Pingu: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel,
              panel === preferencesPanel else { return }

        preferencesPanel = nil
        configureMenu()

        if preferencesPanelPending {
            DispatchQueue.main.async { [weak self] in
                self?.presentPendingPreferencesPanel()
            }
        }
    }

}
