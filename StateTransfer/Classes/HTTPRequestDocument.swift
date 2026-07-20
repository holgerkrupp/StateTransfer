//
//  HTTPRequestDocument.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var statetransferRequest: UTType {
        UTType(exportedAs: "de.holgerkrupp.statetransfer-request", conformingTo: .json)
    }
    
    static var restED: UTType {
        UTType(filenameExtension: "request")!
    }
    
}

class HTTPRequestDocument: FileDocument, ObservableObject {
    static var readableContentTypes: [UTType] {
        [.statetransferRequest, .restED]
    }
    static var writableContentTypes: [UTType] {
        [.statetransferRequest]
    }

    //var request: HTTPRequest
    @Published var requests: [HTTPRequest] = []{
        didSet {
            attachObservers()
            markDirty()
        }
    }
    @Published var chains: [RequestChain] = [] {
        didSet {
            markDirty()
        }
    }
    
    var isImported: Bool = false // Track if it's an imported file
    @Published var isDirty = false
    @Published var autoSaveEnabled = true // User setting for auto-save
    private var hasBeenSaved = false


    init(request: HTTPRequest = HTTPRequest()) {
        let temp = request
        requests.append(temp)
        isDirty = true
        attachObservers()
        noteUnsavedChange()
    }
    
    init(copying document: HTTPRequestDocument) {
      //  let temp = document.request
        self.isImported = true // Ensure it's treated as an imported file
        
        requests = document.requests
        chains = document.chains
        hasBeenSaved = document.hasBeenSaved
        isDirty = document.isDirty
        attachObservers()
    }
    
    func attachObservers() {
         for request in requests {
             request.onChange = { [weak self] in
                 self?.markDirty()
             }
         }
     }

     private func markDirty() {
         isDirty = true

         saveDocumentIfPossible()
      }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Detect if the file is XML (Plist)
        if configuration.contentType == .restED {
            do {
                if let jsonData = convertPlistToJson(plistData: data) {
                    let temp = try JSONDecoder().decode(HTTPRequest.self, from: jsonData)
                    self.requests = [temp]
                } else {
                    if let singleRequest = try? JSONDecoder().decode(HTTPRequest.self, from: data) {
                        self.requests = [singleRequest] // Wrap it in an array
                    } else {
                        self.requests = try JSONDecoder().decode([HTTPRequest].self, from: data)
                    }
                }
            } catch {
                throw CocoaError(.fileReadCorruptFile)
            }
            
        } else {
            // Default to JSON parsing

            
            if let envelope = try? JSONDecoder().decode(HTTPRequestDocumentEnvelope.self, from: data) {
                requests = envelope.requests
                chains = envelope.chains
            } else if let singleRequest = try? JSONDecoder().decode(HTTPRequest.self, from: data) {
                self.requests = [singleRequest] // Wrap it in an array
            } else {
                self.requests = try JSONDecoder().decode([HTTPRequest].self, from: data)
            }
            
        }
        
        if configuration.contentType == .restED {
            self.isImported = true
        }
        hasBeenSaved = !isImported
        isDirty = false
        attachObservers()
        
    }
    
     func addRequest(_ request: HTTPRequest?) {
        let newRequest = request ?? HTTPRequest()
        if requests.contains(where: { $0.id == newRequest.id }) {
            newRequest.id = UUID()
        }
        newRequest.onChange = { [weak self] in
            self?.markDirty()
        }
        requests.append(newRequest)
    }

    func addChain(name: String = "New Chain") -> RequestChain {
        let chain = RequestChain(name: name)
        chains.append(chain)
        return chain
    }

    func removeRequest(_ requestID: UUID) {
        requests.removeAll { $0.id == requestID }
        chains = chains.map { chain in
            var updated = chain
            let removedNodeIDs = Set(
                updated.nodes
                    .filter { $0.requestID == requestID }
                    .map(\.id)
            )
            updated.nodes.removeAll { removedNodeIDs.contains($0.id) }
            updated.links.removeAll {
                removedNodeIDs.contains($0.sourceNodeID)
                    || removedNodeIDs.contains($0.destinationNodeID)
            }
            if updated.startNodeID.map(removedNodeIDs.contains) == true {
                updated.startNodeID = updated.nodes.first?.id
            }
            return updated
        }
    }

    func saveDocument() {
        objectWillChange.send()
        DispatchQueue.main.async {
            NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: nil)
        }

    }

    func saveDocumentIfPossible() {
        if autoSaveEnabled && hasBeenSaved {
            saveDocument()
        } else {
            noteUnsavedChange()
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let envelope = HTTPRequestDocumentEnvelope(
            requests: requests,
            chains: chains
        )
        let data = try JSONEncoder().encode(envelope)
        DispatchQueue.main.async { [weak self] in
            self?.hasBeenSaved = true
            self?.isDirty = false
            self?.currentAppKitDocument?.updateChangeCount(.changeCleared)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    private var currentAppKitDocument: NSDocument? {
        NSDocumentController.shared.currentDocument
            ?? NSApp.keyWindow?.windowController?.document as? NSDocument
            ?? NSApp.mainWindow?.windowController?.document as? NSDocument
    }

    private func noteUnsavedChange() {
        DispatchQueue.main.async { [weak self] in
            self?.currentAppKitDocument?.updateChangeCount(.changeDone)
        }
    }

    func convertPlistToJson(plistData: Data) -> Data? {

        // TO BE ABLE TO LOAD RESTed XML Files

        do {
            // Parse the plist data
            if let plistObject = try PropertyListSerialization.propertyList(
                from: plistData, options: [], format: nil) as? [String: Any]
            {

                // Transform to match StateTransfer.json structure
                let jsonDict: [String: Any] = [
                    "header": (plistObject["headers"] as? [[String: Any]])?.map
                    { header in
                        [
                            "key": header["header"] as? String ?? "",
                            "active": header["inUse"] as? Bool ?? false,
                            "value": header["value"] as? String ?? "",
                            "id": UUID().uuidString,  // Generate a unique ID
                        ]
                    } ?? [],
                    "url": plistObject["baseURL"] as? String ?? "",
                    "body": (plistObject["bodyString"] as? String ?? ""),
                    "follorRedirects": plistObject["followRedirect"] as? Bool
                        ?? true,
                    "parameterEncoding": "Form encoded",
                    "method": (plistObject["httpMethod"] as? String ?? "GET")
                        .lowercased(),
                    "parameters":
                        (plistObject["parameters"] as? [[String: Any]])?.map {
                            param in
                            [
                                "id": UUID().uuidString,
                                "value": param["value"] as? String ?? "",
                                "active": param["inUse"] as? Bool ?? false,
                                "key": param["parameter"] as? String ?? "",
                            ]
                        } ?? [],
                    "bodyEncoding": "UTF-8",
                ]

                // Convert to JSON
                return try JSONSerialization.data(
                    withJSONObject: jsonDict, options: .prettyPrinted)
            }
        } catch {
            print("Error converting plist to JSON: \(error)")
        }
        return nil
    }

}
