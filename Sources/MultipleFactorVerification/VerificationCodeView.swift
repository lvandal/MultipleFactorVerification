//
//  VerificationCodeView.swift
//  MultipleFactorVerification
//
//  Created by Luc Vandal on 2024-07-16.
//

import SwiftUI

@available(iOS 17.0, macOS 12.0, *)
public struct VerificationCodeView: View {
    @Environment(\.dismiss) var dismiss
    
    public var email: String
    
    public var onValidate: ((String) async -> Bool)?
    public var onResendCode: (() -> Void)?
    public var onContactSupport: (() -> Void)?
    
    @State private var input: String = ""
    @State private var shake: Bool = false
    @State private var showingOptions = false
    @State private var isValidating = false
    
    @FocusState private var isFocused: Bool
    
    private let numberOfCharacters = 6
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack {
                        Text(NSLocalizedString("STR_2FA_CODE_VERIFICATION_TITLE", bundle: Bundle.module, comment: ""))
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
                        
                        Text(String.localizedStringWithFormat(NSLocalizedString("STR_2FA_CODE_VERIFICATION_INSTRUCTION_FMT", bundle: .module, comment: ""), email))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                        
                        Button(NSLocalizedString("STR_2FA_CODE_VERIFICATION_NO_CODE_BTN", bundle: Bundle.module, comment: "")) {
                            showingOptions.toggle()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        .confirmationDialog("", isPresented: $showingOptions) {
                            Button(NSLocalizedString("STR_RESEND_CODE", bundle: Bundle.module, comment: "")) {
                                onResendCode?()
                            }
                            
                            Button(NSLocalizedString("STR_CONTACT_SUPPORT", bundle: Bundle.module, comment: "")) {
                                onContactSupport?()
                            }
                            
                            Button(NSLocalizedString("STR_CANCEL", bundle: Bundle.module, comment: ""), role: .cancel) {}
                        }
                        
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .opacity(isValidating ? 1 : 0)
                        
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
                    .padding(40)
                    .frame(minHeight: geometry.size.height)
                    .onAppear() {
                        isFocused = true
                    }
                }
                .frame(width: geometry.size.width)
            }
            
            SheetCloseButton()
#if !os(macOS)
                .padding(24)
#else
                .padding()
#endif
        }
#if os(macOS)
        .frame(height: 260)
#elseif os(visionOS)
        .frame(height: 300)
#endif
    }
    
    
    public init(email: String, onValidate: @escaping (String) async -> Bool, onResendCode: @escaping () -> Void, onContactSupport: @escaping () -> Void) {
        self.email = email
        self.onValidate = onValidate
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
        
        isValidating = true
        
        Task {
            let i = input
            let valid = await onValidate?(i) ?? false
            DispatchQueue.main.async {
                isValidating = false
                
                if !valid {
                    shake = true
                } else {
                    dismiss()
                }
            }
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


@available(iOS 17.0, macOS 12.0, *)
fileprivate struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var buttonSize: CGFloat = 24
    let renderShadow = true
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: buttonSize, height: buttonSize)
                .symbolRenderingMode(.hierarchical)
        }
        .foregroundStyle(colorScheme == .light ? Color.accentColor : Color.white)
        .buttonStyle(.borderless)
#if !os(macOS)
        .frame(width: buttonSize, height: buttonSize)
        .hoverEffect()
#endif
        .modifier(SheetCloseButtonModifier(renderShadow: renderShadow))
    }
}


@available(iOS 17.0, macOS 12.0, *)
fileprivate struct SheetCloseButtonModifier: ViewModifier {
    var renderShadow: Bool
    
    func body(content: Content) -> some View {
        if renderShadow {
            content
                .shadow(radius: 2)
        }
        else {
            content
        }
    }
}
