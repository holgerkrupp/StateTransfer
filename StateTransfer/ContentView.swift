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
                Divider()
                RequestHeaderView(header: $document.request.header)
                Divider()
                RequestParamterView(header: $document.request.parameters, parameterEncoding: $document.request.parameterEncoding)
                Divider()
                RequestBodyView(message: $document.request.body, bodyEncoding: $document.request.bodyEncoding)
            }
            .padding()
            .frame(maxWidth: 500)
            VStack{
              //  RequestView(request: $document.request)
              //  Spacer()
                ResponseView(request: $document.request)
                 
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
