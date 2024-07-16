//
//  AppKitVerificationCodeView.swift
//  MultipleFactorVerification
//
//  Created by Luc Vandal on 2024-07-16.
//

import Cocoa

public class AppKitVerificationCodeView: NSView {
    public var code: String
    public var email: String
    
    public var onSuccess: ((String) -> Void)
    public var onResendCode: (() -> Void)?
    public var onContactSupport: (() -> Void)?
    
    private var input: String = ""
    private let numberOfCharacters = 6
    private var shake: Bool = false
    
    private var stackView: NSStackView!
    private var codeStackView: NSStackView!
    private var noCodeButton: NSButton!
    
    public init(code: String, email: String, onSuccess: @escaping (String) -> Void, onResendCode: @escaping () -> Void, onContactSupport: @escaping () -> Void) {
        self.code = code
        self.email = email
        self.onSuccess = onSuccess
        self.onResendCode = onResendCode
        self.onContactSupport = onContactSupport
        
        super.init(frame: .zero)
        
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.alignment = .centerX
        addSubview(stackView)
        
        let titleLabel = NSTextField(labelWithString: "Two-factor authentication")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center
        stackView.addArrangedSubview(titleLabel)
        
        codeStackView = NSStackView()
        codeStackView.orientation = .horizontal
        codeStackView.spacing = 10
        for _ in 0..<numberOfCharacters {
            let characterView = NSTextField()
            characterView.font = NSFont.systemFont(ofSize: 24)
            characterView.alignment = .center
            characterView.wantsLayer = true
            characterView.layer?.borderColor = NSColor.blue.cgColor
            characterView.layer?.borderWidth = 2
            characterView.layer?.cornerRadius = 5
            characterView.isBezeled = false
            characterView.isEditable = false
            characterView.drawsBackground = false
            characterView.translatesAutoresizingMaskIntoConstraints = false
            characterView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            characterView.heightAnchor.constraint(equalToConstant: 30).isActive = true
            characterView.cell?.usesSingleLineMode = true
            characterView.cell?.wraps = false
            characterView.cell?.isScrollable = false
            codeStackView.addArrangedSubview(characterView)
        }
        stackView.addArrangedSubview(codeStackView)
        
        let instructionLabel = NSTextField(labelWithString: "A message with a verification code has been sent to \(email). Please enter the code to continue.")
        instructionLabel.textColor = .secondaryLabelColor
        instructionLabel.alignment = .center
        instructionLabel.lineBreakMode = .byWordWrapping
        instructionLabel.maximumNumberOfLines = 0
        instructionLabel.preferredMaxLayoutWidth = 400
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(instructionLabel)

        // Set minimum width constraint
        instructionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 400).isActive = true
        
        noCodeButton = NSButton(title: "Did not get a verification code?", target: self, action: #selector(didTapNoCode))
        noCodeButton.bezelStyle = .inline
        noCodeButton.contentTintColor = .blue
        stackView.addArrangedSubview(noCodeButton)
        
        // Set the view to be the first responder to capture key events
        DispatchQueue.main.async {
            self.window?.makeFirstResponder(self)
        }
    }
    
    private func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8)
        ])
    }
    
    @objc private func didTapNoCode() {
        let alert = NSAlert()
        alert.messageText = "Verification Code Options"
        alert.informativeText = "Choose an option"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Resend Code")
        alert.addButton(withTitle: "Contact Support")
        alert.addButton(withTitle: "Cancel")
        
        if let window {
            alert.beginSheetModal(for: window) { [weak self] response in
                switch response {
                case .alertFirstButtonReturn:
                    self?.onResendCode?()
                case .alertSecondButtonReturn:
                    self?.onContactSupport?()
                default:
                    break
                }
            }
        } else {
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                onResendCode?()
            case .alertSecondButtonReturn:
                onContactSupport?()
            default:
                break
            }
        }
    }
    
    
    @objc private func didTapResend() {
        onResendCode?()
    }
    
    
    @objc private func didTapContactSupport() {
        onContactSupport?()
    }
    
    
    private func updateCharacterViews() {
        for (index, view) in codeStackView.arrangedSubviews.enumerated() {
            if let characterView = view as? NSTextField {
                if index < input.count {
                    let charIndex = input.index(input.startIndex, offsetBy: index)
                    characterView.stringValue = String(input[charIndex])
                } else {
                    characterView.stringValue = ""
                }
            }
        }
    }
    
    
    private func validate() {
        guard input.count == numberOfCharacters else {
            return
        }
        
        if code != input {
            shakeView()
            input = ""
            updateCharacterViews()
        } else {
            onSuccess(input)
        }
    }
    
    
    private func shakeView() {
        let numberOfShakes = 3
        let shakeDuration = 0.25 / Double(numberOfShakes)
        let shakeDistance: CGFloat = 10

        var currentShake = 0

        func performShake() {
            guard currentShake < numberOfShakes else {
                DispatchQueue.main.async {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = shakeDuration
                        for case let characterView as NSTextField in self.codeStackView.arrangedSubviews {
                            characterView.layer?.borderColor = NSColor.blue.cgColor
                        }
                        self.codeStackView.animator().frame.origin.x = 0
                    }, completionHandler: nil)
                }
                return
            }

            DispatchQueue.main.async {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = shakeDuration
                    for case let characterView as NSTextField in self.codeStackView.arrangedSubviews {
                        characterView.layer?.borderColor = NSColor.red.cgColor
                    }
                    let translation = (currentShake % 2 == 0) ? shakeDistance : -shakeDistance
                    self.codeStackView.animator().frame.origin.x += translation
                }, completionHandler: {
                    currentShake += 1
                    performShake()
                })
            }
        }
        performShake()
    }
    
    
    override public func keyDown(with event: NSEvent) {
        guard let characters = event.charactersIgnoringModifiers, characters.count == 1 else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 51 { // Delete key
            if !input.isEmpty {
                input.removeLast()
                updateCharacterViews()
            }
        } else if let character = characters.first, character.isNumber {
            input.append(character)
            if input.count > numberOfCharacters {
                input = String(input.prefix(numberOfCharacters))
            }
            updateCharacterViews()
            validate()
        }
    }
}


private extension Character {
    var isNumber: Bool {
        return self >= "0" && self <= "9"
    }
}
