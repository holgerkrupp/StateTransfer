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
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Picker("Method", selection: $method) {
                ForEach(HTTPMethod.allCases, id: \.self) { method in
                    Text(method.description).tag(method)
                }
            }
            .labelsHidden()
            .frame(width: 105)

            TextField("https://api.example.com/resource", text: Binding(
                get: { endpoint?.absoluteString ?? ""},
                set: { endpoint = URL(string: $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .onSubmit(onSubmit)
            .help("Enter a complete HTTP or HTTPS URL")
        }
    }
}

#Preview {
    @Previewable @State var endpoint = URL(string: "http://localhost:3000/")
    @Previewable @State var method: HTTPMethod = .get

    EndPointView(endpoint: $endpoint, method: $method) {}
}
