//
//  Application.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Cocoa

class Pingu {
    
    // MARK: - Private Properties
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var preferencesPopover: NSPopover?
    private var eventMonitor: EventMonitor?
    private var savedHosts: SavedHosts
    private var pingService: PingService
    private var chartView: ChartView
    
    // MARK: - Lifecycle
    
    init() {
        
        self.chartView = ChartView()
        self.pingService = PingService()
        self.savedHosts = SavedHosts.load(fromStore: UserDefaults.standard)
        
        if let selectedHost = savedHosts.selectedHost {
            
            startPinging(host: selectedHost)
        
        } else {
            
            let defaultHost = Host(host: "www.google.com", interval: .seconds(1))
            
            savedHosts.add(defaultHost)
            savedHosts.save(toStore: UserDefaults.standard)
            
            startPinging(host: defaultHost)
            
        }
        
        configureMenu()
        
        statusItem.button?.addSubview(chartView)
        statusItem.length = chartView.desiredWidth
        
        eventMonitor = EventMonitor(mask: .leftMouseDown) { [weak self] event in

            if self?.preferencesPopover?.isShown ?? false {
                self?.hidePreferencesPopover()
            }
            
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
        
        let quitMenuItem = NSMenuItem(title: "Quit",
                                       action: #selector(didSelectQuitMenuItem),
                                       keyEquivalent: "")
        quitMenuItem.target = self
        
        menu.addItem(preferencesMenuItem)
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
    
    }
    
    // MARK: - Private methods
    
    fileprivate func showPreferencesPopover() {
        
        preferencesPopover = NSPopover()
        preferencesPopover?.contentViewController = PreferencesViewController(pingService: pingService, delegate: self)
        
        if let button = statusItem.button {
            preferencesPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        
        eventMonitor?.start()
        
    }
    
    fileprivate func hidePreferencesPopover() {
        
        preferencesPopover?.close()
        eventMonitor?.stop()
        
    }
    
    fileprivate func startPinging(host: Host) {
        
        pingService.startPinging(host: host.host,
                                 interval: host.interval.timeInterval)
        { [weak self] pingResult in
            
            DispatchQueue.main.sync {
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
        preferencesPopover?.isShown ?? false ? hidePreferencesPopover() : showPreferencesPopover()
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
        
        configureMenu()
        hidePreferencesPopover()
        
    }
    
}
