//
//  RequestView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct RequestView: View {
    @Binding var request: HTTPRequest
    
    var body: some View {
        HStack{
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray)
                .frame(width: 50, height: 30)
                .overlay{
                    Text(request.method.rawValue.uppercased())
                }
            
            Text(request.url?.absoluteString ?? "No URL")
                .font(.title)
                .lineLimit(3)
                .minimumScaleFactor(0.1)
        }
    }
}

#Preview {
    @Previewable @State var request: HTTPRequest = .init()

    RequestView(request: $request)
}
