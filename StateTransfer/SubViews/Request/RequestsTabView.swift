//
//  RequestsTabView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 01.03.25.
//


import SwiftUI

struct RequestsTabView: View {
    @Binding var selectedRequestID: UUID?
    @ObservedObject var document: HTTPRequestDocument

    var body: some View {
        HStack {
            Button(action: {
                document.addRequest(nil)
            }) {
                Image(systemName: "plus.square")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .padding(.horizontal)

            HStack {
                ForEach($document.requests, id: \.id) { req in
                    TabItemView(
                                            request: req,
                                            selectedRequestID: $selectedRequestID,
                                            document: document,
                                            onClose: { closeRequest(req.wrappedValue) } // Pass close handler
                                        )
                        .background(selectedRequestID == req.id.wrappedValue ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.clear))
                        
                        .cornerRadius(8)
                        .onTapGesture {
                            if selectedRequestID != req.id.wrappedValue {
                                selectedRequestID = req.id.wrappedValue
                            }
                        }

                }
                Spacer()
            }
        }
        .onAppear {
            if selectedRequestID == nil, !$document.requests.isEmpty {
                selectedRequestID = $document.requests.first?.id.wrappedValue
            }
        }
    }
    
    private func closeRequest(_ request: HTTPRequest) {
        if let index = document.requests.firstIndex(where: { $0.id == request.id }) {
            document.requests.remove(at: index)

            // If the deleted tab was selected, pick another
            if selectedRequestID == request.id {
                selectedRequestID = document.requests.first?.id // Select next available tab
            }
            document.saveDocument() // Auto-save when renaming

        }
    }
}

struct TabItemView: View {
    @Binding var request: HTTPRequest
    @Binding var selectedRequestID: UUID?
    @ObservedObject var document: HTTPRequestDocument // Add document reference
    @State private var isEditing: Bool = false
    @State private var tempName: String = ""
    let onClose: () -> Void // Closure to close tab

    var body: some View {
        HStack {
            if isEditing {
                TextField("", text: $tempName, onCommit: {
                    if !tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        request.name = tempName
                        document.saveDocument() // Auto-save when renaming
                    }
                    isEditing = false
                })
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
                .onAppear { tempName = request.name }
            } else {
                Text(request.name)
                    .onTapGesture(count: 2) { isEditing = true }
                    .foregroundColor(selectedRequestID == request.id ? Color.white : Color.primary)
            }
            Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .opacity(0.7)
                        }
                        .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minWidth: 100, maxWidth: 200)
    }
}

#Preview {
    @Previewable @State var uuid: UUID? = UUID()
    RequestsTabView(selectedRequestID: $uuid, document: HTTPRequestDocument())
}
