//
//  AppDelegate.swift
//  PinguLauncher
//
//  Created by Thanos Theodoridis on 5/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        startPinguIfNeeded()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Private Methods
    
    fileprivate func startPinguIfNeeded() {
        
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == pinguBundleId }.isEmpty
        
        if !isRunning {
            
            DistributedNotificationCenter.default().addObserver(self,
                                                                selector: #selector(self.terminate),
                                                                name: .killPinguLauncher,
                                                                object: pinguBundleId)
            
            var applicationURL = Bundle.main.bundleURL
            
            for _ in 1...4 {
                applicationURL.deleteLastPathComponent()
            }
            
            NSWorkspace.shared.openApplication(at: applicationURL,
                                                configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error {
                    NSLog("Failed to launch Pingu: \(error.localizedDescription)")
                }
            }
            
        } else {
            self.terminate()
        }
    }
    
    // MARK: - Selectors
    
    @objc fileprivate func terminate() {
        NSApp.terminate(nil)
    }

}
