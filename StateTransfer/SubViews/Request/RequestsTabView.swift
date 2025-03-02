//
//  RequestsTabView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 01.03.25.
//

import SwiftUI

struct RequestsTabView: View {
    
    @Binding var selectedRequestID: UUID?
    @ObservedObject  var document: HTTPRequestDocument
    var body: some View {
        HStack {
            Button(action: {
                document.addRequest(nil)
            }) {
                Image(systemName: "plus.square")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.clear)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack {
                    ForEach($document.requests, id: \.self) { req in
                        Button(action: { selectedRequestID = req.id.wrappedValue }) {
                            Text(req.name.wrappedValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedRequestID == req.id.wrappedValue ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Close") {
                                //  closeDocument(doc)
                            }
                        }
                    }
                }
            }
            
        }
        .onAppear {
            if selectedRequestID == nil, !$document.requests.isEmpty {
                selectedRequestID = $document.requests.first?.id.wrappedValue
            }
        }


    }
}

#Preview {
    @Previewable @State var uuid: UUID? = UUID()
    RequestsTabView(selectedRequestID: $uuid, document: HTTPRequestDocument())
}
