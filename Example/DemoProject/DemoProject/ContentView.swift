//
//  ContentView.swift
//  DemoProject
//
//  Created by Luc Vandal on 2024-07-16.
//

import SwiftUI
import MultipleFactorVerification

struct ContentView: View {
    @State private var isPresented = false
    
    var body: some View {
        VStack {
            Button("Present Modal") {
                isPresented.toggle()
            }
        }
        .sheet(isPresented: $isPresented) {
            VerificationCodeView(code: "123456",
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
        }
        .padding()
    }
}
