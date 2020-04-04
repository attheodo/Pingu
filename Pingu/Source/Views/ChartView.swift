//
//  ChartView.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 3/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

import SnapKit

class ChartView: NSView {
    
    // MAKR: - Public Properties
    
    public var desiredWidth: CGFloat {
        return baseLineViewWidth + baseLineViewMargin + label.frame.width
    }
    
    // MARK: - Private Properties
    
    fileprivate var label: NSTextField
    fileprivate var baselineView: NSView
    fileprivate var chartBarViews: [ChartBarView] = []
    fileprivate var results: [PingResult] = Array(repeating: .responseInMilliseconds(0), count: 6)
    fileprivate let baseLineViewMargin: CGFloat = 6
    fileprivate let baseLineViewWidth: CGFloat = 22
    fileprivate var avgResponseTime: Float {
        
        var values: [Int] = []
        
        results.forEach { r in
            if case .responseInMilliseconds(let v) = r {
                values.append(v)
            }
        }
        
        return values.isEmpty ? 0 : Float(values.reduce(0, +) / values.count)
        
    }
    
    // MARK: - Lifecycle
    
    init() {
        
        label = NSTextField()
        baselineView = NSView()
        
        super.init(frame: NSRect(x: 0, y: 0, width: 60, height: 22))
        
        configureViews()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func updateLayer() {
        
        super.updateLayer()
        baselineView.layer?.backgroundColor = NSColor.secondaryLabelColor.cgColor
        
    }
    
    // MARK: - Public Methods
    
    public func addResult(_ pingResult: PingResult) {
        
        results.append(pingResult)
        
        if results.count > 6 {
            results = Array(results.dropFirst())
        }
        
        updateLabel(forPingResult: pingResult)
        updateBarViews()
        
    }
    
    public func setPausedState(_ paused: Bool) {
        
        if paused {
        
            label.stringValue = "n/a"
            resetBarViews()
            
        }
        
    }
    
    // MARK: - Private Methods
    
    fileprivate func configureViews() {
        
        label.isBezeled = false
        label.isBordered = false
        label.isSelectable = false
        label.isEditable = false
        label.backgroundColor = .clear
    
        addSubview(label)
        
        baselineView.wantsLayer = true
        
        addSubview(baselineView)
        
        baselineView.snp.makeConstraints { m in
            m.height.equalTo(1)
            m.width.equalTo(baseLineViewWidth)
            m.bottom.equalTo(self).offset(-4)
            m.left.equalTo(self)
        }
        
        label.snp.makeConstraints { m in
            m.height.equalTo(16)
            m.centerY.equalTo(self).offset(1.5)
            m.left.equalTo(baselineView.snp.right).offset(baseLineViewMargin)
        }
        
        for i in 0..<6 {
            
            let v = ChartBarView()
            addSubview(v)
            
            if i == 0 {
               
                v.snp.makeConstraints { m in
                    m.left.equalTo(baselineView)
                    m.bottom.equalTo(baselineView).offset(-2)
                    m.width.equalTo(2)
                    m.height.equalTo(1)
                }
                
            } else {
                
                v.snp.makeConstraints { m in
                    m.left.equalTo(chartBarViews[i-1].snp.right).offset(2)
                    m.bottom.equalTo(chartBarViews[i-1])
                    m.width.equalTo(2)
                    m.height.equalTo(1)
                }
                
            }
            
            chartBarViews.append(v)
            
        }
        
    }
    
    fileprivate func updateLabel(forPingResult pingResult: PingResult) {
        
        switch pingResult {
            
        case .responseInMilliseconds(let v):
            label.stringValue = "\(v)ms"
            
        case .timeout:
            label.stringValue = "t/o"
            
        default:
            label.stringValue = "n/a"
        }
        
        label.sizeToFit()
        
    }
    
    fileprivate func updateBarViews() {
        
        for (i, result) in results.enumerated() {
            chartBarViews[i].configure(with: result, avgResponseTime: avgResponseTime)
        }
        
    }
    
    fileprivate func resetBarViews() {
        let _ = chartBarViews.map({ $0.reset() })
    }
    
}
