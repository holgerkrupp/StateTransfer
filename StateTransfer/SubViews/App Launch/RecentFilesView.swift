//
//  RecentFilesView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI
import AppKit

struct RecentFilesView: View {
    @State var recentDocs:[RecentDocument] = []

    var body: some View {
        VStack{
            Text("Recents")
                .font(.title)
                .padding()
            List(recentDocs) { doc in
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
                }
                
                .padding(4)
            }
            .onAppear(){
                recentDocs = getRecentDocuments()
            }

        }
    }
    
    struct RecentDocument: Identifiable {
        let id = UUID()
        let url: URL
        let name: String
        let lastModified: Date?
        let isInICloud: Bool
        let isDownloaded: Bool
        
        var fileIcon: NSImage {
           
                return NSWorkspace.shared.icon(forFile: url.absoluteString)
            
        }
    }
    


    func getRecentDocuments() -> [RecentDocument] {
        let urls = NSDocumentController.shared.recentDocumentURLs.prefix(10)
        
        return urls.compactMap { url in
            let fileManager = FileManager.default
            let isInICloud = fileManager.isUbiquitousItem(at: url)
            let isDownloaded = fileManager.fileExists(atPath: url.path)
            
            let name = url.lastPathComponent
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let modifiedDate = attributes?[.modificationDate] as? Date
            return RecentDocument(url: url, name: name, lastModified: modifiedDate, isInICloud: isInICloud, isDownloaded: isDownloaded)
        }
    }
}

#Preview {
    RecentFilesView()
}
