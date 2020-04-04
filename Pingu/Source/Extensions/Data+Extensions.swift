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
        return self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> sockaddr in
            let raw = UnsafeRawPointer(pointer)
            let address = raw.assumingMemoryBound(to: sockaddr.self).pointee
            return address
        }
    }
    
    public var socketAddressInternet: sockaddr_in {
        return self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> sockaddr_in in
            let raw = UnsafeRawPointer(pointer)
            let address = raw.assumingMemoryBound(to: sockaddr_in.self).pointee
            return address
        }
    }
    
}
