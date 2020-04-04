//
//  PingService.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Darwin

public enum PingResult {
    case timeout
    case responseInMilliseconds(Int)
    case unknownResult
    case unknownHost
    case paused
}

public class PingService {
    
    // MARK: - Public Properties
    
    public private(set) var isPinging: Bool = false
    
    // MARK: - Private Properties
    
    fileprivate let pingPath = "/sbin/ping"
    fileprivate var task: Process?
    fileprivate var pipe: Pipe?
    fileprivate var outputHandle: FileHandle?
    fileprivate var newDataObserver: NSObjectProtocol?
    
    // MARK: - Public Methods
    
    public func startPinging(host: String, interval: TimeInterval, observer: @escaping (PingResult) -> Void) {
        
        stopPinging()
        
        isPinging = true
        
        DispatchQueue.global(qos: .userInteractive).async {
        
            NSLog("Starting pings - Host: \(host) - Interval: \(interval)")
            
            self.task = Process()
            self.task?.launchPath = self.pingPath
            self.task?.arguments = ["-i \(interval)", host]
            
            self.pipe = Pipe()
            self.task?.standardOutput = self.pipe
            
            self.outputHandle = self.pipe?.fileHandleForReading
            self.outputHandle?.readabilityHandler = { pipe in
                if let line = String(data: pipe.availableData, encoding: .utf8) {
                    observer(self.parse(line: line))
                }
            }
            
            self.task?.launch()
            self.task?.waitUntilExit()
            
        }
        
    }
    
    public func stopPinging() {
        
        NSLog("Stopping pings")
        
        isPinging = false
        outputHandle?.closeFile()
        task?.terminate()
        
        task = nil
        pipe = nil
        outputHandle = nil
        
    }
    
    public func getAddress(forHost host: String) -> (data: Data?, error: NSError?) {
        
        var streamError = CFStreamError()
        let cfhost = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        let status = CFHostStartInfoResolution(cfhost, .addresses, &streamError)
        
        var data: Data?
        
        if !status {
            
            if Int32(streamError.domain)  == kCFStreamErrorDomainNetDB {
                return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                                     code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue),
                                     userInfo: nil))
            } else {
                return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                                     code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue),
                                     userInfo: nil))
            }
            
        } else {
            
            var success: DarwinBoolean = false
            
            guard let addresses = CFHostGetAddressing(cfhost, &success)?.takeUnretainedValue() as? [Data] else {
                return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                                     code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue) ,
                                     userInfo: nil))
            }
            
            for address in addresses {
                
                let addrin = address.socketAddress
                
                if address.count >= MemoryLayout<sockaddr>.size && addrin.sa_family == UInt8(AF_INET) {
                    data = address
                    break
                }
                
            }
            
            if data?.count == 0 || data == nil {
                return (nil, NSError(domain: kCFErrorDomainCFNetwork as String,
                                     code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue) ,
                                     userInfo: nil))
            }
            
        }
        
        return (data, nil)
        
    }
    
    // MARK: - Private Methods
    
    fileprivate func parse(line: String) -> PingResult {
        
        if line.hasSuffix("Unknown host") {
            return .unknownHost
        }
        else if line.hasPrefix("Request timeout") {
            
            return .timeout
        
        } else {
            
            let components = line.components(separatedBy: "time=")
            
            guard
                components.count == 2,
                let timeComponent = components.last
            else {
                return .unknownResult
            }
            
            if let milliseconds = Double(timeComponent.filter("0123456789.".contains)) {
                return .responseInMilliseconds(Int(milliseconds))
            } else {
                return .unknownResult
            }
            
        }
        
    }
    
}
