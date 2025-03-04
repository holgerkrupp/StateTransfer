//
//  ContentView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @Binding var document: HTTPRequestDocument
    @State private var selectedRequestID: UUID?

    @State private var showSaveDialog = false
    @State private var showExportDialog = false

    @State private var showUnsavedChangesAlert = false

 
    

    var body: some View {
        
        
       //  RequestView(request: $selectedRequest ?? $document.request)
        
        
        
        RequestsTabView(selectedRequestID: $selectedRequestID, document: document)
            .onAppear {
                if document.requests.isEmpty {
                    document.requests.append(.init())
              }
            }
        
        Divider()
        /*
        if let index = document.requests.firstIndex(where: { $0.id == selectedRequestID }) {
            RequestView(request: document.requests[index])
        }
       */
        if let request = document.requests.first(where: { $0.id == selectedRequestID }) {
            
            RequestView(request: request)
                .onAppear {
                    // If this document was imported, trigger "Save As"
                    if document.isImported {
                        document.isImported = false  // Reset flag
                        showExportDialog = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    if !document.autoSaveEnabled && document.isDirty {
                        showUnsavedChangesAlert = true
                    }
                }
                .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
                    Button("Save", action: document.saveDocument)
                    Button("Discard", role: .destructive) { }
                } message: {
                    Text("You have unsaved changes. Do you want to save before closing?")
                }
                .fileExporter(
                    isPresented: $showExportDialog,
                    document: document,
                    contentType: UTType(filenameExtension: "httprequest")!,
                    defaultFilename: "RESTed Import"
                ) { result in
                    // Handle save result if needed
                }
                
            
        }
       
         
           


            
        
    }

}

#Preview {
    ContentView( document: .constant(HTTPRequestDocument()))
}
