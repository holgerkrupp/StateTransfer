//
//  ContentView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

struct ContentView: View {
    
    @State var request: HTTPRequest
    
    var body: some View {
        HSplitView {
            VStack{
                EndPointView(endpoint: $request.url, method: $request.method)
                RequestHeaderView(header: $request.header)
            }
        }
    }
}

#Preview {
    ContentView(request: HTTPRequest())
}
