//
//  ContentView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    private enum WorkspaceMode: String, CaseIterable {
        case requests = "Requests"
        case chains = "Chains"
    }

    @Binding var document: HTTPRequestDocument
    @ObservedObject var historyStore: RequestHistoryStore
    @StateObject private var chainRunner = RequestChainRunner()
    @State private var selectedRequestID: UUID?
    @State private var workspaceMode: WorkspaceMode = .requests
    @State private var showExportDialog = false
    @State private var showUnsavedChangesAlert = false

    var body: some View {
        ZStack {
            requestWorkspace
                .opacity(workspaceMode == .requests ? 1 : 0)
                .allowsHitTesting(workspaceMode == .requests)
                .accessibilityHidden(workspaceMode != .requests)

            RequestChainEditorView(
                document: document,
                historyStore: historyStore,
                runner: chainRunner
            )
            .opacity(workspaceMode == .chains ? 1 : 0)
            .allowsHitTesting(workspaceMode == .chains)
            .accessibilityHidden(workspaceMode != .chains)
        }
        .frame(
            minWidth: 820,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Workspace", selection: $workspaceMode) {
                    ForEach(WorkspaceMode.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 220)
                .help("Switch between individual requests and request chains")
            }
        }
        .onAppear {
            ensureSelectedRequest()
        }
        .focusedSceneValue(\.restoreHistoryRequest) { entry in
            guard let request = entry.restoredRequest() else { return }
            document.addRequest(request)
            selectedRequestID = request.id
            workspaceMode = .requests
        }
    }

    @ViewBuilder
    private var requestWorkspace: some View {
        VStack(spacing: 0) {
            RequestsTabView(
                selectedRequestID: $selectedRequestID,
                document: document
            )

            if let request = document.requests.first(where: {
                $0.id == selectedRequestID
            }) {
                RequestView(request: request, historyStore: historyStore)
                    .onAppear {
                        if document.isImported {
                            document.isImported = false
                            showExportDialog = true
                        }
                    }
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: NSApplication.willTerminateNotification
                        )
                    ) { _ in
                        if !document.autoSaveEnabled && document.isDirty {
                            showUnsavedChangesAlert = true
                        }
                    }
                    .alert(
                        "Unsaved Changes",
                        isPresented: $showUnsavedChangesAlert
                    ) {
                        Button("Save", action: document.saveDocument)
                        Button("Discard", role: .destructive) { }
                    } message: {
                        Text("You have unsaved changes. Do you want to save before closing?")
                    }
                    .fileExporter(
                        isPresented: $showExportDialog,
                        document: document,
                        contentType: .statetransferRequest,
                        defaultFilename: "RESTed Import"
                    ) { _ in
                    }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    private func ensureSelectedRequest() {
        if document.requests.isEmpty {
            let request = HTTPRequest()
            document.addRequest(request)
            selectedRequestID = request.id
        } else if selectedRequestID == nil {
            selectedRequestID = document.requests.first?.id
        }
    }
}

#Preview {
    ContentView(
        document: .constant(HTTPRequestDocument()),
        historyStore: RequestHistoryStore()
    )
}
