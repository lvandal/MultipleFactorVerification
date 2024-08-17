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
                await Task.sleep(1 * 1_000_000_000) // Sleep for 1 seconds
//                return (false, .expired)
//                return (true, nil)
                return (false, .invalid)
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
