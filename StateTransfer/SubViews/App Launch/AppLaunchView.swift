//
//  AppLaunchView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AppLaunchView: View {
    @StateObject private var recentManager = RecentDocumentsManager()
    @State private var dragOver = false

    var body: some View {
        ZStack {
            VStack{
                HStack {
                    Image("NetworkTerminal")
                        .resizable()
                        .scaledToFill()
                    
                    VStack{
                    
                        RecentFilesView()
                            .environmentObject(recentManager)
                        
                    }
                }
                OpenOrNewDocumentView()
                    .environmentObject(recentManager)
            }
            .blur(radius: dragOver ? 3 : 0) // Dim the background when dragging
            .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                handleFileDrop(providers: providers)
            }
            // Drag Overlay (Only visible when dragging)
            if dragOver {
                Color.black.opacity(0.4) // Darken background
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                VStack {
                    Image(systemName: "arrow.down.doc.fill") // Drop icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                    
                    Text("Drop file to open")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                }
                .transition(AnyTransition.scale)
                .animation(.easeInOut(duration: 0.5), value: dragOver)
                
            }
            
            
        }
        
    }
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    if let urlData = item as? Data,
                       let urlString = String(data: urlData, encoding: .utf8),
                       let fileURL = URL(string: urlString) {
                        
                        DispatchQueue.main.async {
                            openDroppedFile(fileURL)
                        }
                    }
                }
                return true
            }
        }
        return false
    }

    /// Opens the dropped file in the app
    private func openDroppedFile(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
            recentManager.loadRecentDocuments() // Update the recent list
        }
    }
    
}

#Preview {
    AppLaunchView()
}
