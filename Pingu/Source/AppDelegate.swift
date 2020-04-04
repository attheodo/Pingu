//
//  AppDelegate.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Private Properties
    
    fileprivate var pingu: Pingu?
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        pingu = Pingu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

