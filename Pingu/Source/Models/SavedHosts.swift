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
        // Re-adding the same host and interval moves it to the front of the
        // recent-host list instead of creating a duplicate entry. The same
        // host with a different interval remains a separate entry.
        hosts.removeAll {
            $0.host.caseInsensitiveCompare(newHost.host) == .orderedSame &&
            $0.interval == newHost.interval
        }

        hosts.insert(newHost, at: 0)
        if hosts.count > 5 {
            hosts.removeLast()
        }
        setSelected(newHost)
        
    }
    
    public func setSelected(_ selectedHost: Host) {

        for host in hosts {
            host.selected = host === selectedHost
        }
        
    }
    
}
