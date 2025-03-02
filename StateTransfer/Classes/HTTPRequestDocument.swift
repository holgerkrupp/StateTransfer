import SwiftUI
//
//  HTTPRequestDocument.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//
import UniformTypeIdentifiers

class HTTPRequestDocument: FileDocument, ObservableObject {
    static var readableContentTypes: [UTType] {
        [UTType(filenameExtension: "httprequest") ?? .json, UTType(filenameExtension: "request")!]
    }
    static var writableContentTypes: [UTType] {
        [UTType(filenameExtension: "httprequest") ?? .json]
    }

    //var request: HTTPRequest
    @Published var requests: [HTTPRequest] = []
    
    var isImported: Bool = false // Track if it's an imported file


    init(request: HTTPRequest = HTTPRequest()) {
        let temp = request
        requests.append(temp)
    }
    
    init(copying document: HTTPRequestDocument) {
      //  let temp = document.request
        self.isImported = true // Ensure it's treated as an imported file
        
        requests = document.requests
    }

    required init(configuration: ReadConfiguration) throws {
        print("configuration")
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Detect if the file is XML (Plist)
        if configuration.contentType == UTType(filenameExtension: "request") {
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

            
            if let singleRequest = try? JSONDecoder().decode(HTTPRequest.self, from: data) {
                self.requests = [singleRequest] // Wrap it in an array
            } else {
                self.requests = try JSONDecoder().decode([HTTPRequest].self, from: data)
            }
            
        }
        
        if configuration.contentType == UTType(filenameExtension: "request") {
            self.isImported = true
        }
        
    }
    
     func addRequest(_ request: HTTPRequest?) {
        print("addRequest")
        requests.append(request ?? HTTPRequest())
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(requests)
        return FileWrapper(regularFileWithContents: data)
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
