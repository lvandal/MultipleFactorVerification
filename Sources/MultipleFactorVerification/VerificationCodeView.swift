//
//  VerificationCodeView.swift
//  MultipleFactorVerification
//
//  Created by Luc Vandal on 2024-07-16.
//

import SwiftUI

@available(iOS 17.0, macOS 12.0, *)
public struct VerificationCodeView: View {
    public var code: String
    public var email: String
    
    public var onSuccess: ((String) -> Void)
    public var onResendCode: (() -> Void)?
    public var onContactSupport: (() -> Void)?
    
    @State private var input: String = ""
    @State private var shake: Bool = false
    @State private var showingOptions = false
    
    @FocusState private var isFocused: Bool
    
    private let numberOfCharacters = 6
    
    public var body: some View {
        VStack {
            Text("Two-factor authentication")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 10) {
                ForEach(0..<numberOfCharacters, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(shake ? .red : .blue, lineWidth: 2)
                        .frame(width: 40, height: 46)
                        .overlay(
                            Text(character(at: index))
                                .font(.title)
                        )
                }
            }
            .padding()
            .onTapGesture {
                isFocused = true
            }
            .shake($shake, duration: 0.5) {
                input = ""
            }
            
            Text("A message with a verification code has been sent to **\(email)**. Please enter the code to continue.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            Button("Did not get a verification code?") {
                showingOptions.toggle()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.blue)
            .confirmationDialog("", isPresented: $showingOptions) {
                Button("Resend Code") {
                    onResendCode?()
                }
                
                Button("Contact Support") {
                    onContactSupport?()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            
            // Hidden text field
            if #available(iOS 17.0, macOS 14.0, *) {
                TextField("", text: $input)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                    .focused($isFocused)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .onChange(of: input) { _, _ in
                        input = input.filter { $0.isNumber }
                        if input.count > numberOfCharacters {
                            input = String(input.prefix(numberOfCharacters))
                        }
                        validate()
                    }
            } else {
                TextField("", text: $input)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                    .focused($isFocused)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .onChange(of: input) { _ in
                        input = input.filter { $0.isNumber }
                        if input.count > numberOfCharacters {
                            input = String(input.prefix(numberOfCharacters))
                        }
                        validate()
                    }
            }
        }
        .padding()
        .onAppear() {
            isFocused = true
        }
    }
    
    
    public init(code: String, email: String, onSuccess: @escaping (String) -> Void, onResendCode: @escaping () -> Void, onContactSupport: @escaping () -> Void) {
        self.code = code
        self.email = email
        self.onSuccess = onSuccess
        self.onResendCode = onResendCode
        self.onContactSupport = onContactSupport
    }
    
    
    private func character(at index: Int) -> String {
        if index < input.count {
            let start = input.index(input.startIndex, offsetBy: index)
            let end = input.index(start, offsetBy: 1)
            return String(input[start..<end])
        } else {
            return ""
        }
    }
    
    
    private func validate() {
        guard input.count == numberOfCharacters else {
            return
        }
        
        if code != input {
            shake = true
        } else {
            onSuccess(input)
        }
    }
}


@available(iOS 17.0, macOS 12.0, *)
fileprivate struct Shake<Content: View>: View {
    /// Set to true in order to animate
    @Binding var shake: Bool
    /// How many times the content will animate back and forth
    var repeatCount = 3
    /// Duration in seconds
    var duration = 0.8
    /// Range in pixels to go back and forth
    var offsetRange = 10.0

    @ViewBuilder let content: Content
    var onCompletion: (() -> Void)?

    @State private var xOffset = 0.0

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            content
                .offset(x: xOffset)
                .onChange(of: shake) { _, shouldShake in
                    guard shouldShake else { return }
                    Task {
                        await animate()
                        shake = false
                        onCompletion?()
                    }
                }
        } else {
            content
                .offset(x: xOffset)
                .onChange(of: shake) { shouldShake in
                    guard shouldShake else { return }
                    Task {
                        await animate()
                        shake = false
                        onCompletion?()
                    }
                }
        }
    }

    // Obs: some of factors must be 1.0.
    private func animate() async {
        let factor1 = 0.9
        let eachDuration = duration * factor1 / CGFloat(repeatCount)
        for _ in 0..<repeatCount {
            await backAndForthAnimation(duration: eachDuration, offset: offsetRange)
        }

        let factor2 = 0.1
        await animate(duration: duration * factor2) {
            xOffset = 0.0
        }
    }

    private func backAndForthAnimation(duration: CGFloat, offset: CGFloat) async {
        let halfDuration = duration / 2
        await animate(duration: halfDuration) {
            self.xOffset = offset
        }

        await animate(duration: halfDuration) {
            self.xOffset = -offset
        }
    }
}


@available(iOS 17.0, macOS 12.0, *)
fileprivate extension View {
    func shake(_ shake: Binding<Bool>,
               repeatCount: Int = 3,
               duration: CGFloat = 0.8,
               offsetRange: CGFloat = 10,
               onCompletion: (() -> Void)? = nil) -> some View {
        Shake(shake: shake,
              repeatCount: repeatCount,
              duration: duration,
              offsetRange: offsetRange) {
            self
        } onCompletion: {
            onCompletion?()
        }
    }

    func animate(duration: CGFloat, _ execute: @escaping () -> Void) async {
        await withCheckedContinuation { continuation in
            withAnimation(.linear(duration: duration)) {
                execute()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                continuation.resume()
            }
        }
    }
}
