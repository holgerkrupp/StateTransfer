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
            HStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Image("NetworkTerminal")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 320)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.76)],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("StateTransfer")
                            .font(.largeTitle.bold())
                        Text("Build, inspect, and chain HTTP requests.")
                            .foregroundStyle(.white.opacity(0.82))
                    }
                    .foregroundStyle(.white)
                    .padding(24)
                }
                .frame(width: 320)

                VStack(spacing: 0) {
                    RecentFilesView()
                        .environmentObject(recentManager)

                    OpenOrNewDocumentView()
                        .environmentObject(recentManager)
                }
            }
            .blur(radius: dragOver ? 3 : 0)
            .onDrop(of: [.fileURL], isTargeted: $dragOver) { providers in
                handleFileDrop(providers: providers)
            }

            if dragOver {
                VStack(spacing: 14) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.tint)

                    Text("Drop file to open")
                        .font(.title2.bold())
                }
                .padding(38)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.tint, style: StrokeStyle(lineWidth: 2, dash: [8]))
                }
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minWidth: 720, minHeight: 460)
        .animation(.snappy, value: dragOver)
    }

    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(
                    forTypeIdentifier: UTType.fileURL.identifier,
                    options: nil
                ) { item, _ in
                    let fileURL: URL?
                    if let url = item as? URL {
                        fileURL = url
                    } else if let url = item as? NSURL {
                        fileURL = url as URL
                    } else if let data = item as? Data,
                              let string = String(data: data, encoding: .utf8) {
                        fileURL = URL(string: string)
                    } else {
                        fileURL = nil
                    }

                    if let fileURL {
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

    private func openDroppedFile(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { document, _, error in
            if document != nil {
                recentManager.noteUserSelectedDocument(at: url)
            } else if let error {
                NSApp.presentError(error)
            }
        }
    }
    
}

#Preview {
    AppLaunchView()
}
