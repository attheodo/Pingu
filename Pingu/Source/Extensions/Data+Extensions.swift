//
//  Data+Extensions.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 4/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation

extension Data {
    
    public var socketAddress: sockaddr {
        return self.withUnsafeBytes { buffer in
            buffer.load(as: sockaddr.self)
        }
    }
    
    public var socketAddressInternet: sockaddr_in {
        return self.withUnsafeBytes { buffer in
            buffer.load(as: sockaddr_in.self)
        }
    }
    
}
