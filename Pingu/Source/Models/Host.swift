//
//  Host.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

class Host: Codable {
    
    // MARK: - Public Properties
    
    public let host: String
    public let interval: PingInterval
    public var selected: Bool = true
    
    // MARK: - Lifecycle
    
    init(host: String, interval: PingInterval) {
        
        self.host = host
        self.interval = interval
        
    }
    
}

// MARK: - Equatable

extension Host: Equatable {
    
    static public func ==(lhs: Host, rhs: Host) -> Bool {
        return lhs.host == rhs.host && lhs.interval == rhs.interval
    }
    
}
