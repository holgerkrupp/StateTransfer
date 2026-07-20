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
        HStack(spacing: 12) {
            ExampleView()
            Spacer()
            openOtherButton
            newRequestButton
        }
        .controlSize(.large)
        .padding(16)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    @ViewBuilder
    private var openOtherButton: some View {
        let button = Button(action: recentManager.openOtherFile) {
            Label("Open…", systemImage: "folder")
        }

        if #available(macOS 26.0, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var newRequestButton: some View {
        let button = Button(action: recentManager.newDocument) {
            Label("New Request", systemImage: "doc.badge.plus")
        }

        if #available(macOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
    
}

#Preview {
    @Previewable @StateObject var recentManager = RecentDocumentsManager()
    OpenOrNewDocumentView()
        .environmentObject(recentManager)
}
