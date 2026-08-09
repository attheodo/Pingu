//
//  PreferencesViewController.swift
//  Pingu
//
//  Created by Thanos Theodoridis on 2/4/20.
//  Copyright © 2020 Thanos Theodoridis. All rights reserved.
//

import Foundation
import Cocoa

protocol PreferencesViewControllerDelegate: AnyObject {
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
        hostTextField.validateEditing()
        let host = hostTextField.stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !host.isEmpty, !isSubmitting else { return }

        isSubmitting = true
        hostTextField.isEnabled = false
        intervalPopupButton.isEnabled = false
        addButton.isEnabled = false
        errorLabel.textColor = .secondaryLabelColor
        errorLabel.stringValue = "Resolving host…"
        errorLabel.isHidden = false

        let pingService = self.pingService
        let interval = selectedInterval
        let submissionID = UUID()
        self.submissionID = submissionID

        DispatchQueue.global(qos: .userInitiated).async {
            let (_, error) = pingService.getAddress(forHost: host)

            DispatchQueue.main.async { [weak self] in
                self?.finishHostResolution(id: submissionID,
                                           host: host,
                                           interval: interval,
                                           errorMessage: error == nil ? nil : "Error resolving host")
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + hostResolutionTimeout) { [weak self] in
            guard let self else { return }

            self.finishHostResolution(id: submissionID,
                                      host: host,
                                      interval: interval,
                                      errorMessage: "Host resolution timed out")
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
    private var isSubmitting = false
    private var submissionID: UUID?
    private let hostResolutionTimeout: TimeInterval = 5

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
        hostTextField.target = self
        hostTextField.action = #selector(didTapDoneButton(_:))
        // Send the text-field action for Return, not for ordinary focus loss.
        hostTextField.cell?.sendsActionOnEndEditing = false
        // Hostnames and IP addresses must not use AppKit's predictive text
        // service. Besides being irrelevant here, its remote completion view
        // can outlive this short-lived panel on current macOS releases.
        hostTextField.isAutomaticTextCompletionEnabled = false
        hostTextField.allowsCharacterPickerTouchBarItem = false
        // The panel owns Return, while the button remains the default action
        // when focus is on another control.
        addButton.keyEquivalent = "\r"
        addButton.keyEquivalentModifierMask = []
        addButton.isEnabled = false
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        activateHostInput()
    }

    override func cancelOperation(_ sender: Any?) {
        submissionID = nil
        isSubmitting = false

        guard let window = view.window else { return }

        // End field editing first so AppKit can detach any text-service views
        // before the panel leaves the screen.
        window.makeFirstResponder(nil)
        DispatchQueue.main.async {
            window.close()
        }
    }
    
    // MARK: - Private Methods
    
    fileprivate func configureView() {

        intervalPopupButton.addItems(withTitles: availableIntervals.map({ $0.title }))
        intervalPopupButton.action = #selector(self.didSelectInterval(_:))
        
        if let index = availableIntervals.firstIndex(of: selectedInterval) {
            intervalPopupButton.selectItem(at: index)
        }
        
        errorLabel.isHidden = true
        errorLabel.textColor = .systemRed
        
    }

    private func updateSubmitAvailability() {
        let hasHost = !(hostTextField.currentEditor()?.string ?? hostTextField.stringValue)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        addButton.isEnabled = hasHost && !isSubmitting
    }

    private func finishHostResolution(id: UUID,
                                      host: String,
                                      interval: PingInterval,
                                      errorMessage: String?) {
        guard isSubmitting, submissionID == id else { return }

        submissionID = nil

        if let errorMessage {
            isSubmitting = false
            hostTextField.isEnabled = true
            intervalPopupButton.isEnabled = true
            updateSubmitAvailability()
            errorLabel.textColor = .systemRed
            errorLabel.stringValue = errorMessage
            errorLabel.isHidden = false
        } else {
            delegate?.preferencesViewController(self,
                                                didAddHost: host,
                                                interval: interval)
        }
    }

    func activateHostInput() {
        guard let window = view.window else { return }

        window.makeKey()
        window.makeFirstResponder(hostTextField)
        if let editor = hostTextField.currentEditor() as? NSTextView {
            editor.isAutomaticTextCompletionEnabled = false
            editor.isAutomaticSpellingCorrectionEnabled = false
            editor.isAutomaticTextReplacementEnabled = false
        }
        updateSubmitAvailability()
    }

    // MARK: - Selectors
    
    @objc fileprivate func didSelectInterval(_ sender: Any) {
        selectedInterval = availableIntervals[intervalPopupButton.indexOfSelectedItem]
    }
    
}

// MARK: - NSTextFieldDelegate

extension PreferencesViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        updateSubmitAvailability()
        errorLabel.isHidden = true
        errorLabel.textColor = .systemRed
    }

}
