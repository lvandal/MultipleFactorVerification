//
//  AppKitVerificationCodeView.swift
//  MultipleFactorVerification
//
//  Created by Luc Vandal on 2024-07-16.
//

#if os(macOS)
import Cocoa

public class AppKitVerificationCodeView: NSView {
    public var email: String
    
    public var onValidate: ((String, @escaping (Bool) -> Void) -> Void)?
    public var onResendCode: (() -> Void)?
    public var onContactSupport: (() -> Void)?
    public var onCancel: (() -> Void)?
    
    private var input: String = ""
    private let numberOfCharacters = 6
    private var shake: Bool = false
    
    private var stackView: NSStackView!
    private var codeStackView: NSStackView!
    private var noCodeButton: NSButton!
    private var cancelButton: NSButton!
    private var progressIndicator: NSProgressIndicator!
    
    public init(email: String, onValidate: @escaping (String, @escaping (Bool) -> Void) -> Void, onResendCode: @escaping () -> Void, onContactSupport: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.email = email
        self.onValidate = onValidate
        self.onResendCode = onResendCode
        self.onContactSupport = onContactSupport
        self.onCancel = onCancel
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
        
        let titleLabel = NSTextField(labelWithString: NSLocalizedString("STR_2FA_CODE_VERIFICATION_TITLE", bundle: .module, comment: ""))
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
        
        let instructionLabel = NSTextField(labelWithString: String.localizedStringWithFormat(NSLocalizedString("STR_2FA_CODE_VERIFICATION_INSTRUCTION_FMT", bundle: .module, comment: ""), email))
        instructionLabel.textColor = .secondaryLabelColor
        instructionLabel.alignment = .center
        instructionLabel.lineBreakMode = .byWordWrapping
        instructionLabel.maximumNumberOfLines = 0
        instructionLabel.preferredMaxLayoutWidth = 400
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(instructionLabel)

        // Set minimum width constraint
        instructionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 400).isActive = true
        
        noCodeButton = NSButton(title: NSLocalizedString("STR_2FA_CODE_VERIFICATION_NO_CODE_BTN", bundle: Bundle.module, comment: ""), target: self, action: #selector(didTapNoCode))
        noCodeButton.bezelStyle = .inline
        stackView.addArrangedSubview(noCodeButton)
        
        // Progress Indicator
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .small
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(progressIndicator)
        
        // Cancel Button
        cancelButton = NSButton(title: NSLocalizedString("STR_CANCEL", bundle: Bundle.module, comment: ""), target: self, action: #selector(didTapCancel))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cancelButton)
        
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
            stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.95),
            
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
    
    @objc private func didTapCancel() {
        onCancel?()
    }
    
    @objc private func didTapNoCode() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("STR_CODE_OPTIONS_TITLE", bundle: Bundle.module, comment: "")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("STR_RESEND_CODE", bundle: Bundle.module, comment: ""))
        alert.addButton(withTitle: NSLocalizedString("STR_CONTACT_SUPPORT", bundle: Bundle.module, comment: ""))
        alert.addButton(withTitle: NSLocalizedString("STR_CANCEL", bundle: Bundle.module, comment: ""))
        
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
        
        progressIndicator.startAnimation(self)
        
        onValidate?(input) {valid in
            DispatchQueue.main.async { [weak self]  in
                guard let self else { return }
                
                progressIndicator.stopAnimation(self)
                
                if !valid {
                    shakeView()
                    input = ""
                    updateCharacterViews()
                } else {
                    // Close
                }
            }
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
        } else if event.keyCode == 53 { // Esc key
            onCancel?()
        } else if let character = characters.first, character.isNumber {
            input.append(character)
            if input.count > numberOfCharacters {
                input = String(input.prefix(numberOfCharacters))
            }
            updateCharacterViews()
            validate()
        }
    }
    
    @IBAction func paste(_ sender: Any) {
        handlePaste()
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if event.modifierFlags.contains(.command) {
                guard let characters = event.charactersIgnoringModifiers else {
                    return super.performKeyEquivalent(with: event)
                }
                switch characters {
                case "v", ".": // DVORAK uses .
                    handlePaste()
                    return true
                    
                default:
                    break
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    private func handlePaste() {
        if let string = NSPasteboard.general.string(forType: .string), string.count == numberOfCharacters, let _ = Int(string) {
            input = string
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
#endif
