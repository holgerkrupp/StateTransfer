//
//  RecentDocumentsManager.swift
//  StateTransfer
//
//  Created by Holger Krupp on 27.02.25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

class RecentDocumentsManager: ObservableObject {
    @Published var recentDocs: [RecentDocument] = []

    private let bookmarkDefaultsKey = "RecentDocumentSecurityScopedBookmarks"
    private var activeSecurityScopedURLs: Set<URL> = []

    struct RecentDocument: Identifiable {
        let id = UUID()
        let url: URL
        let name: String
        let lastModified: Date?
        let isInICloud: Bool
        let isDownloaded: Bool
        
        var fileIcon: NSImage {
            let icon: NSImage

            if FileManager.default.fileExists(atPath: url.path) {
                icon = NSWorkspace.shared.icon(forFile: url.path)
            } else if let contentType = UTType(filenameExtension: url.pathExtension) {
                icon = NSWorkspace.shared.icon(for: contentType)
            } else {
                icon = NSWorkspace.shared.icon(for: .data)
            }

            let result = icon.copy() as? NSImage ?? icon
            result.size = NSSize(width: 40, height: 40)
            return result
        }
    }

    init() {
        loadRecentDocuments()
        
        // Listen for when the app becomes active (good moment to refresh)
        NotificationCenter.default.addObserver(self, selector: #selector(updateRecentDocuments), name: NSApplication.didBecomeActiveNotification, object: nil)
        
        
    }

    deinit {
        for url in activeSecurityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }

    @objc func updateRecentDocuments() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Small delay to allow system updates
            self.loadRecentDocuments()
        }
    }

    func loadRecentDocuments() {
        let urls = NSDocumentController.shared.recentDocumentURLs.prefix(10)

        recentDocs = urls.compactMap { recentURL in
            persistBookmarkIfPossible(for: recentURL)

            let url = resolveBookmarkedURL(for: recentURL) ?? recentURL
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

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

    func openRecentDocument(_ recentDocument: RecentDocument) {
        let originalURL = recentDocument.url
        let resolvedURL = resolveBookmarkedURL(for: originalURL) ?? originalURL
        let alreadyAccessing = activeSecurityScopedURLs.contains(resolvedURL)
        let startedAccessing = alreadyAccessing
            || resolvedURL.startAccessingSecurityScopedResource()

        NSDocumentController.shared.openDocument(withContentsOf: resolvedURL, display: true) {
            [weak self] document, _, error in
            if document != nil {
                if startedAccessing && !alreadyAccessing {
                    self?.activeSecurityScopedURLs.insert(resolvedURL)
                }
                self?.persistBookmarkIfPossible(for: resolvedURL)
                NSDocumentController.shared.noteNewRecentDocumentURL(resolvedURL)
            } else {
                if startedAccessing && !alreadyAccessing {
                    resolvedURL.stopAccessingSecurityScopedResource()
                }
                if let error {
                    NSApp.presentError(error)
                }
            }

            self?.loadRecentDocuments()
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
            persistBookmarkIfPossible(for: selectedURL)
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

    func noteUserSelectedDocument(at url: URL) {
        persistBookmarkIfPossible(for: url)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        loadRecentDocuments()
    }

    private func persistBookmarkIfPossible(for url: URL) {
        guard url.isFileURL,
              let bookmark = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
              )
        else {
            return
        }

        var bookmarks = storedBookmarks
        bookmarks[bookmarkKey(for: url)] = bookmark
        storedBookmarks = bookmarks
    }

    private func resolveBookmarkedURL(for url: URL) -> URL? {
        guard let bookmark = storedBookmarks[bookmarkKey(for: url)] else {
            return nil
        }

        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale {
            persistBookmarkIfPossible(for: resolvedURL)
        }
        return resolvedURL
    }

    private func bookmarkKey(for url: URL) -> String {
        url.standardizedFileURL.path
    }

    private var storedBookmarks: [String: Data] {
        get {
            UserDefaults.standard.dictionary(forKey: bookmarkDefaultsKey) as? [String: Data] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: bookmarkDefaultsKey)
        }
    }
}
