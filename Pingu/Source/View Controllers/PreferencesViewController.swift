//
//  PreferencesViewController.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

protocol PreferencesViewControllerDelegate: class {
    func preferencesViewController(_ ctrl: PreferencesViewController, didAddHost host: String, interval: PingInterval)
}

class PreferencesViewController: NSViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var hostTextField: NSTextField!
    @IBOutlet weak var intervalPopupButton: NSPopUpButton!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    
    // MARK: - IBActions
    
    @IBAction func didTapDoneButton(_ sender: AnyObject) {
        
        let host = hostTextField.stringValue
        
        guard !host.isEmpty else { return }
        
        addButton.isHidden = true
        
        let (_, error) = pingService.getAddress(forHost: host)
        
        if let _ = error {
            
            errorLabel.stringValue = "Error resolving host"
            errorLabel.isHidden = false
            addButton.isHidden = false
            
        } else {
            delegate?.preferencesViewController(self, didAddHost: hostTextField.stringValue, interval: selectedInterval)
        }
        
    }
    
    // MARK: - Public Properties
    
    public weak var delegate: PreferencesViewControllerDelegate?
    
    // MARK: - Private Properties
    
    fileprivate var pingService: PingService
    fileprivate let availableIntervals: [PingInterval] = [
        .milliseconds(500),
        .seconds(1),
        .seconds(5),
        .seconds(30),
        .minutes(1)
    ]
    fileprivate var selectedInterval: PingInterval = .seconds(1)
    
    // MARK: - Lifecycle
    
    init(pingService: PingService, delegate: PreferencesViewControllerDelegate) {
        
        self.pingService = pingService
        self.delegate = delegate
        
        super.init(nibName: "PreferencesViewController", bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        configureView()
        hostTextField.delegate = self
        
    }
    
    // MARK: - Private Methods
    
    fileprivate func configureView() {
        
        intervalPopupButton.addItems(withTitles: availableIntervals.map({ $0.title }))
        intervalPopupButton.action = #selector(self.didSelectInterval(_:))
        
        if let index = availableIntervals.firstIndex(of: selectedInterval) {
            intervalPopupButton.selectItem(at: index)
        }
        
        errorLabel.isHidden = true
        
    }
    
    // MARK: - Selectors
    
    @objc fileprivate func didSelectInterval(_ sender: Any) {
        selectedInterval = availableIntervals[intervalPopupButton.indexOfSelectedItem]
    }
    
}

// MARK: - NSTextFieldDelegate

extension PreferencesViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        errorLabel.isHidden = true
    }
    
}
