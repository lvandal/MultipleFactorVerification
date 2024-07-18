//
//  VerificationCodeViewController.swift
//  DemoProject
//
//  Created by Luc Vandal on 2024-07-18.
//


import Cocoa
import MultipleFactorVerification

class VerificationCodeViewController: NSViewController {
    private var verificationCodeView: AppKitVerificationCodeView!
    
    var email: String = ""
    
    public var onSuccess: (() -> Void)?
    public var onFailure: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        verificationCodeView = AppKitVerificationCodeView(email: email,
                                                          onValidate: { inputCode, completion in
            // Your validation logic here
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let isValid = inputCode == "123456" // Example condition
                completion(isValid)
            }
        },
                                                          onResendCode: {
            print("Resend code logic")
        },
                                                          onContactSupport: {
            print("Contact support logic")
        })
        
        self.view.addSubview(verificationCodeView)
        
        // Set up Auto Layout constraints for `verificationCodeView`
        verificationCodeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verificationCodeView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            verificationCodeView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            verificationCodeView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0),
            verificationCodeView.heightAnchor.constraint(equalToConstant: 200) // Adjust height as needed
        ])
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.preferredContentSize = NSSize(width: 400, height: 200)
    }
}
