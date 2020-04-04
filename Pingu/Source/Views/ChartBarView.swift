//
//  ChartBarView.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

import SnapKit

class ChartBarView: NSView {
    
    // MARK: - Lifecycle
    
    init() {
        
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.labelColor.cgColor
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func updateLayer() {
        
        super.updateLayer()
        layer?.backgroundColor = NSColor.labelColor.cgColor
        
    }
    
    // MARK: - Public Methods
    
    public func configure(with result: PingResult, avgResponseTime: Float) {
        
        switch result {
        
        case .responseInMilliseconds(let value):
        
            let scaledValue = Rescale(from: (0, Float(avgResponseTime * 2)), to: (1, 12)).rescale(Float(value))
            
            snp.updateConstraints { m in
                m.height.equalTo(min(scaledValue, 12))
            }
            
            switch value {
            case 0..<80:
                layer?.backgroundColor = NSColor.labelColor.cgColor
            case 80..<150:
                layer?.backgroundColor = NSColor(named: NSColor.Name("highPingColor"))?.cgColor
            default :
                layer?.backgroundColor = NSColor(named: NSColor.Name("veryHighPingColor"))?.cgColor
            }
            
        
        case .timeout:
            
            snp.updateConstraints { m in
                m.height.equalTo(0)
            }
        
        default:
            layer?.backgroundColor = .clear
            
        }
        
    }
    
    public func reset() {
        
        snp.updateConstraints { m in
            m.height.equalTo(0)
        }
        
        layer?.backgroundColor = .white
        
    }
    
}
