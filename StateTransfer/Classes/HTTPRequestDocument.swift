//
//  HTTPRequestDocument.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//
import UniformTypeIdentifiers
import SwiftUI

struct HTTPRequestDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var request: HTTPRequest
    
    init(request: HTTPRequest = HTTPRequest()) {
        self.request = request
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.request = try JSONDecoder().decode(HTTPRequest.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(request)
        return FileWrapper(regularFileWithContents: data)
    }
}
