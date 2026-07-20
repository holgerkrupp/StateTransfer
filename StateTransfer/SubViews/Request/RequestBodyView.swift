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
        VStack(spacing: 8) {
            TextEditor(text: $message)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(
                    .background.secondary,
                    in: RoundedRectangle(cornerRadius: 6)
                )

            HStack {
                Picker("Encoding", selection: $bodyEncoding) {
                    ForEach(BodyEncoding.allCases, id: \.self) { encoding in
                        Text(encoding.rawValue).tag(encoding)
                    }
                }
                .labelsHidden()
                .frame(width: 200)

                Spacer()
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    @Previewable @State var message = "Super Text hier"
    @Previewable @State var encoding: BodyEncoding = .utf8
    RequestBodyView(message: $message, bodyEncoding: $encoding)
}
