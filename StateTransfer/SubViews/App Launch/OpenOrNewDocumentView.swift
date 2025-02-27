//
//  OpenOrNewDocumentView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI

struct OpenOrNewDocumentView: View {
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: openOtherFile) {
                Label("Open Other...", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .padding()
            Spacer()
            Button(action: newDocument) {
                Label("New Request", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .padding()
            Spacer()
        }
    }
    
    func newDocument() {
        NSDocumentController.shared.newDocument(nil)
    }
    
    func openOtherFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            NSDocumentController.shared.openDocument(withContentsOf: selectedURL, display: true) { _, _, _ in }
        }
    }
}

#Preview {
    OpenOrNewDocumentView()
}
