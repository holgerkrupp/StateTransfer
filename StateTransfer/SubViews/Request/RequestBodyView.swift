//
//  RequestBodyView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct RequestBodyView: View {
    @Binding var message: String
    @Binding var bodyEncoding: BodyEncoding


    var body: some View {
        TextEditor(text: $message)
            .monospaced(true)
        HStack{
            Picker("", selection: $bodyEncoding, content: {
                ForEach(BodyEncoding.allCases, id: \.self) { encoding in
                    Text(encoding.rawValue).tag(encoding)
                }
            })
            .frame(width: 200)
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var message = "Super Text hier"
    @Previewable @State var encoding: BodyEncoding = .utf8
    RequestBodyView(message: $message, bodyEncoding: $encoding)
}
