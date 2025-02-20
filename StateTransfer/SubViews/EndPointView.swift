//
//  EndPointView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI


struct EndPointView: View {
    @Binding var endpoint: URL?
    @Binding var method: HTTPMethod

    var body: some View {
        HStack{
            TextField("Link URL", text: Binding(
                get: { endpoint?.absoluteString ?? ""},
                set: { endpoint = URL(string: $0) }
                    ))
            Spacer()
            Picker("", selection: $method, content: {
                ForEach(HTTPMethod.allCases, id: \.self) { method in
                    Text(method.description).tag(method)
                }
            })
            .frame(width: 100)
            }
        .padding()
    }
}

#Preview {
    @Previewable @State var endpoint = URL(string: "http://localhost:3000/")
    @Previewable @State var method: HTTPMethod = .get

    EndPointView(endpoint: $endpoint, method: $method)
}
