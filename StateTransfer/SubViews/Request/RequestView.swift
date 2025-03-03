//
//  RequestView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct RequestView: View {
    @ObservedObject var request: HTTPRequest
    
    var body: some View {
        HSplitView {
            VStack{
                EndPointView(endpoint: $request.url, method: $request.method)
                Toggle("Follow Redirects", isOn: $request.follorRedirects)
                
                AuthenticationView(credentials: $request.authorizationCredentials, url: request.url?.host ?? "")
                
                Divider()
                RequestHeaderView(header: $request.header)
                Divider()
                RequestParamterView(header: $request.parameters, parameterEncoding: $request.parameterEncoding)
                Divider()
                RequestBodyView(message: $request.body, bodyEncoding: $request.bodyEncoding)
                  //  .disabled(document.request.method == .get)
            }
            .padding()
            .frame(maxWidth: 500)
            VStack{
              
                ResponseView(requestid: $request.id)
                 
            }
            .frame(minWidth: 200)
            .padding()
        }
        StatusBarView(request: request)
            .padding([.leading, .bottom])
    }
}

#Preview {
    @Previewable @State var request: HTTPRequest = .init()

    RequestView(request: request)
}
