//
//  RequestBodyView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct RequestBodyView: View {
    @Binding var message: String

    var body: some View {
        TextEditor(text: $message)
            .monospaced(true)
    }
}

#Preview {
    @Previewable @State var message = "Super Text hier"
    RequestBodyView(message: $message)
}
