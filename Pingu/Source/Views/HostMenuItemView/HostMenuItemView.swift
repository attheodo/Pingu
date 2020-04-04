//
//  HostMenuItemView.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 4/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

import SnapKit

class HostMenuItemView: NSView {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var effectView: NSVisualEffectView!
    @IBOutlet weak var hostLabel: NSTextField!
    @IBOutlet weak var intervalLabel: NSTextField!
    @IBOutlet weak var checkmarkImageView: NSImageView!
    
    // MARK: - Lifecycle
    
    init(host: Host) {
       
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
       
        setupNib()
        
        hostLabel.stringValue = host.host
        intervalLabel.stringValue = "Every \(host.interval.title)"
    
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func draw(_ dirtyRect: NSRect) {
        
        if (enclosingMenuItem?.isHighlighted ?? false) {
            
            hostLabel.textColor = NSColor.selectedMenuItemTextColor
            intervalLabel.textColor = NSColor.selectedMenuItemTextColor
            
            effectView.state = .active
            effectView.material = .selection
            
        } else {
            
            hostLabel.textColor = NSColor.labelColor
            intervalLabel.textColor = NSColor.secondaryLabelColor
            
            effectView.state = .inactive
            effectView.material = .windowBackground
            
        }
        
        checkmarkImageView.isHidden = enclosingMenuItem?.state != .on
        
    }
    
    override func mouseUp(with event: NSEvent) {
        
        guard
            let menuItem = enclosingMenuItem,
            let menu = menuItem.menu
        else {
            return
        }
        
        menu.cancelTracking()
        menu.performActionForItem(at: menu.index(of: menuItem))
        
    }
    
    // MARK: - Private Methods
    
    fileprivate func setupNib() {
        
        let bundle = Bundle(for: type(of: self))
        let nib = NSNib(nibNamed: .init(String(describing: type(of: self))), bundle: bundle)!
        nib.instantiate(withOwner: self, topLevelObjects: nil)
        
        addSubview(contentView)
        
        contentView.snp.makeConstraints { m in
            m.left.equalTo(self)
            m.right.equalTo(self)
            m.top.equalTo(self)
            m.bottom.equalTo(self)
        }
        
    }
    
}
