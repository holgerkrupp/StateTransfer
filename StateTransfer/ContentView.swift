//
//  ContentView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

struct ContentView: View {
    
    @Binding var document: HTTPRequestDocument
    var body: some View {
        HSplitView {
            VStack{
                EndPointView(endpoint: $document.request.url, method: $document.request.method)
                Toggle("Follow Redirects", isOn: $document.request.follorRedirects)
                
                AuthenticationView(credentials: $document.request.authorizationCredentials, url: document.request.url?.host ?? "")
                
                Divider()
                RequestHeaderView(header: $document.request.header)
                Divider()
                RequestParamterView(header: $document.request.parameters, parameterEncoding: $document.request.parameterEncoding)
                Divider()
                RequestBodyView(message: $document.request.body, bodyEncoding: $document.request.bodyEncoding)
                  //  .disabled(document.request.method == .get)
            }
            .padding()
            .frame(maxWidth: 500)
            VStack{
              //  RequestView(request: $document.request)
              //  Spacer()
                ResponseView(requestid: $document.request.id)
                 
            }
            .frame(minWidth: 200)
            .padding()
        }
        StatusBarView(request: $document.request)
            .padding([.leading, .bottom])
            
        
    }

}

#Preview {
    ContentView( document: .constant(HTTPRequestDocument()))
}
