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
        .sheet(isPresented: $isPresented, onDismiss: {
            print("cancelled?")
        }) {
            VerificationCodeView(email: "name@example.com",
                                 onValidate: { inputCode in
                // Simulate an asynchronous validation process
                await Task.sleep(2 * 1_000_000_000) // Sleep for 2 seconds
                return inputCode == "123456" // Replace with actual validation logic
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
