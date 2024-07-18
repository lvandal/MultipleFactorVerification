//
//  ViewController.swift
//  AppKitDemo
//
//  Created by Luc Vandal on 2024-07-16.
//

import Cocoa
import MultipleFactorVerification

class ViewController: NSViewController {
    private var verificationCodeView: AppKitVerificationCodeView!
    
    private var button: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button = NSButton(title: "Verify Code", target: self, action: #selector(didTap))
        button.bezelStyle = .inline
        view.addSubview(button)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc private func didTap() {
        let sheetViewController = VerificationCodeViewController()
        sheetViewController.email = "test@example.com"
        
        sheetViewController.onSuccess = { [weak self] in
            self?.dismiss(sheetViewController)
        }
        sheetViewController.onFailure = { [weak self] in
            
        }
        presentAsSheet(sheetViewController)
    }
}

