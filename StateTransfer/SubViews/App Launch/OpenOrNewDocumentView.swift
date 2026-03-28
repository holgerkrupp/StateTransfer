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
            ExampleView()
                .padding()
                .frame(width: 150)
            Spacer()
            
            openOtherButton
            Spacer()
            newRequestButton
        }
    }

    @ViewBuilder
    private var openOtherButton: some View {
        let button = Button(action: recentManager.openOtherFile) {
            Label("Open Other...", systemImage: "folder")
        }

        if #available(macOS 26.0, *) {
            button
                .buttonStyle(.glass)
                .padding()
        } else {
            button
                .buttonStyle(.bordered)
                .padding()
        }
    }

    @ViewBuilder
    private var newRequestButton: some View {
        let button = Button(action: recentManager.newDocument) {
            Label("New Request", systemImage: "doc.badge.plus")
        }

        if #available(macOS 26.0, *) {
            button
                .buttonStyle(.glassProminent)
                .padding()
        } else {
            button
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }
    
}

#Preview {
    @Previewable @StateObject var recentManager = RecentDocumentsManager()
    OpenOrNewDocumentView()
        .environmentObject(recentManager)
}
