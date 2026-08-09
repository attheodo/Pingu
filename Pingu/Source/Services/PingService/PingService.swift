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
    private var sessionID = UUID()
    
    // MARK: - Public Methods
    
    public func startPinging(host: String, interval: TimeInterval, observer: @escaping (PingResult) -> Void) {
        
        stopPinging()

        let sessionID = UUID()
        self.sessionID = sessionID
        isPinging = true

        NSLog("Starting pings - Host: \(host) - Interval: \(interval)")

        let task = Process()
        let pipe = Pipe()
        let outputHandle = pipe.fileHandleForReading
        var pendingOutput = ""

        task.executableURL = URL(fileURLWithPath: pingPath)
        task.arguments = ["-i", "\(interval)", host]
        task.standardOutput = pipe

        outputHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData

            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }

            guard let output = String(data: data, encoding: .utf8) else { return }

            pendingOutput += output
            let lines = pendingOutput.components(separatedBy: "\n")
            pendingOutput = lines.last ?? ""

            let results = lines.dropLast().map { line in
                self?.parse(line: line.trimmingCharacters(in: .whitespacesAndNewlines)) ?? .unknownResult
            }

            guard !results.isEmpty else { return }

            DispatchQueue.main.async { [weak self] in
                guard let self,
                      self.sessionID == sessionID,
                      self.isPinging else { return }

                results.forEach(observer)
            }
        }

        task.terminationHandler = { [weak self, weak task] _ in
            DispatchQueue.main.async {
                guard let self, self.task === task else { return }

                outputHandle.readabilityHandler = nil
                self.isPinging = false
                self.task = nil
                self.pipe = nil
                self.outputHandle = nil
            }
        }

        self.task = task
        self.pipe = pipe
        self.outputHandle = outputHandle

        do {
            try task.run()
        } catch {
            NSLog("Failed to start ping: \(error.localizedDescription)")
            stopPinging()
        }
        
    }
    
    public func stopPinging() {
        
        NSLog("Stopping pings")

        sessionID = UUID()
        isPinging = false

        task?.terminationHandler = nil
        outputHandle?.readabilityHandler = nil
        outputHandle?.closeFile()

        if task?.isRunning == true {
            task?.terminate()
        }
        
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
