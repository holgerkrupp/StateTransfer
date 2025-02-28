//
//  ExampleView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 28.02.25.
//

import SwiftUI

struct ExampleView: View {
    
    struct ExampleFile: Identifiable {
        let id = UUID()
        let name: String
        let fileName: String
        let fileExtension: String
    }

    let exampleFiles = [
        ExampleFile(name: "Basic-Auth", fileName: "Example - Basic-Auth", fileExtension: "httprequest"),
        ExampleFile(name: "Countries", fileName: "Example Countries", fileExtension: "httprequest")
    ]
    
    var body: some View {
        Menu("Open Example") {
            ForEach(exampleFiles) { file in
                Button(file.name) {
                    openExampleFile(file)
                }
            }
        }
    }
    
    func openExampleFile(_ file: ExampleFile) {
        if let url = Bundle.main.url(forResource: file.fileName, withExtension: file.fileExtension) {
            openDocument(url: url)
        }
    }
    
    func openDocument(url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error = error {
                print("Error opening file: \(error)")
            }
        }
    }
}

#Preview {
    ExampleView()
}
