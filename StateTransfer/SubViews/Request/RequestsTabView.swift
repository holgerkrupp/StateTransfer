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
        HStack(spacing: 12) {
            addRequestButton

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach($document.requests, id: \.id) { req in
                        TabItemView(
                            request: req,
                            selectedRequestID: $selectedRequestID,
                            document: document,
                            onClose: { closeRequest(req.wrappedValue) }
                        )
                        .onTapGesture {
                            if selectedRequestID != req.id.wrappedValue {
                                selectedRequestID = req.id.wrappedValue
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .onAppear {
            if selectedRequestID == nil, !$document.requests.isEmpty {
                selectedRequestID = $document.requests.first?.id.wrappedValue
            }
        }
    }
    
    private func closeRequest(_ request: HTTPRequest) {
        if let index = document.requests.firstIndex(where: { $0.id == request.id }) {
            document.requests.remove(at: index)
            if document.requests.isEmpty {
                document.addRequest(nil)
                
            }
            // If the deleted tab was selected, pick another
            if selectedRequestID == request.id {
                selectedRequestID = document.requests.first?.id // Select next available tab
            }

            document.saveDocument() // Auto-save when renaming

        }
    }

    @ViewBuilder
    private var addRequestButton: some View {
        let button = Button {
            let request = HTTPRequest()
            document.addRequest(request)
            selectedRequestID = request.id
        } label: {
            Label("New", systemImage: "plus")
                .labelStyle(.iconOnly)
        }

        if #available(macOS 26.0, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.bordered)
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

    private var isSelected: Bool {
        selectedRequestID == request.id
    }

    private var foregroundColor: Color {
        if #available(macOS 26.0, *) {
            return isSelected ? .primary : .secondary
        }

        return isSelected ? .white : .primary
    }

    var body: some View {
        HStack(spacing: 8) {
            Spacer()
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
                    .foregroundStyle(foregroundColor)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(foregroundColor)
                    .opacity(0.7)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minWidth: 100, maxWidth: 200)
        .background {
            if isSelected {
                if #available(macOS 26.0, *) {
                    Color.clear
                        .glassEffect(.regular.tint(.accentColor), in: Capsule())
                } else {
                    Capsule()
                        .fill(.tint)
                }
            } else {
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
            }
        }
    }
}

#Preview {
    @Previewable @State var uuid: UUID? = UUID()
    RequestsTabView(selectedRequestID: $uuid, document: HTTPRequestDocument())
}
