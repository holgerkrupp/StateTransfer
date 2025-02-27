//
//  RecentFilesView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI
import AppKit

struct RecentFilesView: View {
    @EnvironmentObject var recentManager: RecentDocumentsManager


    var body: some View {
        VStack{
            Text("Recents")
                .font(.title)
                .padding()
            List(recentManager.recentDocs) { doc in
                HStack {
                    Image(nsImage: doc.fileIcon)
                    VStack(alignment: .leading) {
                        Text(doc.name)
                            .font(.headline)
                        if let date = doc.lastModified {
                            Text("Last modified: \(date.formatted())")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Button("Open") {
                        let fileManager = FileManager.default
                        
                        if doc.isDownloaded {
                            // File is ready, open it
                            NSDocumentController.shared.openDocument(withContentsOf: doc.url, display: true) { _, _, _ in }

                        } else if doc.isInICloud {
                            // File is in iCloud but not downloaded, start the download
                            do {
                                try fileManager.startDownloadingUbiquitousItem(at: doc.url)
                                print("Downloading \(doc.name) from iCloud...")
                            } catch {
                                print("Failed to start iCloud download: \(error)")
                            }
                        } else {
                            print("File is missing and not in iCloud: \(doc.name)")
                        }
                    }
                    /*
                    Button(role: .destructive) {
                        removeRecentFile(doc)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                     */
                }
                
                .padding(4)
            }

        }
    }
    

    



}

#Preview {
    RecentFilesView()
}
