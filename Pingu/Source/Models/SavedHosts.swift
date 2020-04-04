//
//  SavedHosts.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

class SavedHosts: Codable {
    
    // MARK: - Static Properties
    
    static let storeKey = "com.pingu.save-hosts"
    
    // MARK: - Public Properties
    
    public private(set) var hosts: [Host] = []
    public var selectedHost: Host? {
        return hosts.filter({ $0.selected == true }).first
    }
    
    // MARK: - Static Methods
    
    static func load(fromStore store: UserDefaults) -> SavedHosts {
        
        if let hosts = store.object(forKey: SavedHosts.storeKey) as? Data {
        
            let decoder = JSONDecoder()
            
            if let savedHosts = try? decoder.decode(SavedHosts.self, from: hosts) {
                return savedHosts
            } else {
                return SavedHosts()
            }
            
        } else {
            return SavedHosts()
        }
        
    }
    
    // MARK: - Public Methods

    public func save(toStore store: UserDefaults) {
        
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(self) {
            store.set(encoded, forKey: SavedHosts.storeKey)
        }
        
    }
    
    public func add(_ newHost: Host) {
        
        if hosts.count >= 5 {
            hosts = hosts.dropLast()
        }
        
        hosts.insert(newHost, at: 0)
        setSelected(newHost)
        
    }
    
    public func setSelected(_ selectedHost: Host) {
        
        let _ = hosts.map({ $0.selected = false })
        let _ = hosts.filter({ $0 == selectedHost }).first?.selected = true
        
    }
    
}
