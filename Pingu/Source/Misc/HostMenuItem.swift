//
//  HostMenuItem.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

class HostMenuItem: NSMenuItem {
    
    // MARK: - Public Properties
    
    public let host: Host
    
    // MARK: - Private Properties
    
    fileprivate var itemView: HostMenuItemView
    
    // MARK: - Lifecycle
    
    init(host: Host, action: Selector) {
        
        self.host = host
        self.itemView = HostMenuItemView(host: host)
        super.init(title: "", action: action, keyEquivalent: "")
        
        view = itemView
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
