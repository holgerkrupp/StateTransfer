//
//  RecentDocumentsManager.swift
//  StateTransfer
//
//  Created by Holger Krupp on 27.02.25.
//

import SwiftUI
import AppKit

class RecentDocumentsManager: ObservableObject {
    @Published var recentDocs: [RecentDocument] = []


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

    init() {
        loadRecentDocuments()
        
        // Listen for when the app becomes active (good moment to refresh)
        NotificationCenter.default.addObserver(self, selector: #selector(updateRecentDocuments), name: NSApplication.didBecomeActiveNotification, object: nil)
        
        
    }

    @objc func updateRecentDocuments() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Small delay to allow system updates
            self.loadRecentDocuments()
        }
    }

    func loadRecentDocuments() {
        let urls = NSDocumentController.shared.recentDocumentURLs.prefix(10)

        recentDocs = urls.compactMap { url in
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: url.path) || fileManager.isUbiquitousItem(at: url) else {
                return nil // Skip missing files
            }

            let isInICloud = fileManager.isUbiquitousItem(at: url)
            let isDownloaded = fileManager.fileExists(atPath: url.path)
            
            let name = url.lastPathComponent
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let modifiedDate = attributes?[.modificationDate] as? Date
            return RecentDocument(url: url, name: name, lastModified: modifiedDate, isInICloud: isInICloud, isDownloaded: isDownloaded)
        }
       
    }


    func newDocument() {
        NSDocumentController.shared.newDocument(nil)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadRecentDocuments()
        }
    }

    func openOtherFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let selectedURL = panel.url {
            NSDocumentController.shared.openDocument(withContentsOf: selectedURL, display: true) { document, _, _ in
                if document != nil {
                    NSDocumentController.shared.noteNewRecentDocumentURL(selectedURL) 
                }
                DispatchQueue.main.async {
                    self.loadRecentDocuments()
                }
            }
        }
    }
}
