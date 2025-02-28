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
        

            Toggle("Use Authorization", isOn: $credentials.active)
                .onChange(of: credentials.active) { _, isActive in
                    if isActive {
                        if let storedCredentials = KeychainManager.getCredentials(for: url) {
                            credentials = storedCredentials
                        }
                    }
                }
  
                
        VStack(alignment: .leading) {
           
                Form {
                    HStack{
                        TextField("Name", text: $credentials.username)
                            .disabled(!credentials.active)
                        
                        SecureField("Password", text: $credentials.password)
                            .disabled(!credentials.active)
                    }}
                
            }


        
        .onAppear {
            if credentials.active {
                if let storedCredentials = KeychainManager.getCredentials(for: url) {
                    credentials = storedCredentials
                }
            }
        }
  
    }
}

#Preview {
    @Previewable @State var credentials: Authentication = .init()
    AuthenticationView(credentials: $credentials, url: "")
}
