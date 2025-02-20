//
//  StatusBarView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct StatusBarView: View {
    @Binding var request: HTTPRequest
    
    var body: some View {
        HStack {
            
            Button {
                Task{
                    await request.run()
                }
            } label: {
                Text("Send Request")
            }
            Spacer()

        }
    }
}
