//
//  PingInterval.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

public enum PingInterval: Equatable {
    
    case minutes(Double)
    case seconds(Double)
    case milliseconds(Double)
    
    var title: String {
        switch self {
        case .milliseconds(let v):
            return "\(Int(v))ms"
        case .seconds(let v):
            return "\(Int(v))s"
        case .minutes(let v):
            return "\(Int(v))m"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .milliseconds(let v):
            return v / 1000
        case .seconds(let v):
            return v
        case .minutes(let v):
            return v * 60
        }
    }
    
}

extension PingInterval: Codable {
    
    enum CodingKeys: String, CodingKey {
        case milliseconds, seconds, minutes
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let v = try container.decodeIfPresent(Double.self, forKey: .milliseconds) {
            self = .milliseconds(v)
        } else if let v = try container.decodeIfPresent(Double.self, forKey: .seconds) {
            self = .seconds(v)
        } else if let v = try container.decodeIfPresent(Double.self, forKey: .minutes) {
            self = .minutes(v)
        } else {
            self = .seconds(1)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .milliseconds(let v):
            try container.encode(v, forKey: .milliseconds)
        case .seconds(let v):
            try container.encode(v, forKey: .seconds)
        case .minutes(let v):
            try container.encode(v, forKey: .minutes)
        
        }
        
    }
    
}
