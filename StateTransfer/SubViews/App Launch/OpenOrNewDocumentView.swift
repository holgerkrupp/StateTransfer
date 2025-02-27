//
//  OpenOrNewDocumentView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI

struct OpenOrNewDocumentView: View {
    
    @EnvironmentObject var recentManager: RecentDocumentsManager

    var body: some View {
        HStack {
            Spacer()
            
            Button(action: recentManager.openOtherFile) {
                Label("Open Other...", systemImage: "folder")
            }
            .buttonStyle(.bordered)
            .padding()
            Spacer()
            Button(action: recentManager.newDocument) {
                Label("New Request", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .padding()
            Spacer()
        }
    }
    
}

#Preview {
    OpenOrNewDocumentView()
}
