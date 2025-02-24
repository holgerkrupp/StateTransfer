//
//  Authentication.swift
//  StateTransfer
//
//  Created by Holger Krupp on 24.02.25.
//

import SwiftUI
struct AuthenticationView: View {
    @Binding var credentials: Authentication
    let url: String
    
    var body: some View {
        Form {
            Toggle("Use Authorization", isOn: $credentials.active)
                .onChange(of: credentials.active) { _, isActive in
                    if isActive {
                        if let storedCredentials = KeychainManager.getCredentials(for: url) {
                            credentials = storedCredentials
                        }
                    }
                }
            
            TextField("Name", text: $credentials.username)
                .disabled(!credentials.active)
            
            SecureField("Password", text: $credentials.password)
                .disabled(!credentials.active)
        }
        .onAppear {
            if let storedCredentials = KeychainManager.getCredentials(for: url) {
                credentials = storedCredentials
            }
        }
        /*
         ONLY UPDATE KEYCHAIN WHEN REQUEST WORKS - THIS IS DONE IN HTTPREQUES.RUN
        .onChange(of: credentials) { oldCredentials, newCredentials in
            if !newCredentials.username.isEmpty, !newCredentials.password.isEmpty {
                           KeychainManager.saveCredentials(newCredentials, server: url)
                       }
            
            
        }
         */
    }
}

#Preview {
    @Previewable @State var credentials: Authentication = .init()
    AuthenticationView(credentials: $credentials, url: "")
}
