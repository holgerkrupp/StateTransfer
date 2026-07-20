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
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent Requests")
                    .font(.title2.bold())
                Text("Continue where you left off")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            if recentManager.recentDocs.isEmpty {
                ContentUnavailableView(
                    "No Recent Requests",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Open a request file or create a new one to get started.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(recentManager.recentDocs) { doc in
                    Button {
                        if doc.isDownloaded {
                            recentManager.openRecentDocument(doc)
                        } else if doc.isInICloud {
                            do {
                                try FileManager.default.startDownloadingUbiquitousItem(
                                    at: doc.url
                                )
                                recentManager.updateRecentDocuments()
                            } catch {
                                NSApp.presentError(error)
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(nsImage: doc.fileIcon)
                                .resizable()
                                .interpolation(.high)
                                .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(doc.name)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                if let date = doc.lastModified {
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: doc.isDownloaded ? "chevron.right" : "icloud.and.arrow.down")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RecentFilesView()
}
