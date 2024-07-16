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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        verificationCodeView = AppKitVerificationCodeView(code: "123456",
                                                          email: "joe@blow.com",
                                                          onSuccess: { input in
            print("Verification code: \(input)")
        },
                                                          onResendCode: {
            print("Resending code...")
        },
                                                          onContactSupport: {
            print("Contacting support...")
        })
        
        self.view.addSubview(verificationCodeView)
        
        // Set up Auto Layout constraints for `verificationCodeView`
        verificationCodeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verificationCodeView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            verificationCodeView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            verificationCodeView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0),
            verificationCodeView.heightAnchor.constraint(equalToConstant: 300) // Adjust height as needed
        ])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

