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

    var body: some View {
        
        
       //  RequestView(request: $selectedRequest ?? $document.request)

        RequestsTabView(selectedRequestID: $selectedRequestID, document: document)
        Divider()
        RequestView(request: $document.requests.first(where: { $0.id.wrappedValue == selectedRequestID }) ?? $document.request)
       
         
            .onAppear {
                // If this document was imported, trigger "Save As"
                if document.isImported {
                    document.isImported = false  // Reset flag
                    showSaveDialog = true
                }
            }
            .fileExporter(
                isPresented: $showSaveDialog,
                document: document,
                contentType: UTType(filenameExtension: "httprequest")!,
                defaultFilename: "RESTed Import"
            ) { result in
                // Handle save result if needed
            }

            
        
    }

}

#Preview {
    ContentView( document: .constant(HTTPRequestDocument()))
}
