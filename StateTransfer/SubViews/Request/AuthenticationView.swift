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
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Use Authorization", isOn: $credentials.active)
                .onChange(of: credentials.active) { _, isActive in
                    if isActive {
                        if credentials.username.isEmpty || credentials.password.isEmpty {
                            if let storedCredentials = KeychainManager.getCredentials(for: url) {
                                credentials = storedCredentials
                            }
                        }
                    }
                }
            HStack(spacing: 8) {
                TextField("Username", text: $credentials.username)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!credentials.active)

                SecureField("Password", text: $credentials.password)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!credentials.active)
            }
        }
        .onAppear {
            if credentials.active {
                if credentials.username.isEmpty || credentials.password.isEmpty {
                    if let storedCredentials = KeychainManager.getCredentials(for: url) {
                        credentials = storedCredentials
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var credentials: Authentication = .init()
    AuthenticationView(credentials: $credentials, url: "")
}
