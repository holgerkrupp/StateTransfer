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
        VStack(spacing: 0) {
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
                }
                .padding()
                .frame(maxWidth: 500)
                VStack{
                  
                    ResponseView(request: request)
                     
                }
                .frame(minWidth: 200)
                .padding()
            }
            Divider()
            StatusBarView(request: request)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
    }
}

#Preview {
    @Previewable @State var request: HTTPRequest = .init()

    RequestView(request: request)
}
