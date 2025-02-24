//
//  Response.swift
//  StateTransfer
//
//  Created by Holger Krupp on 24.02.25.
//

import Foundation


class Response: ObservableObject {
    @Published var elapsedTime: Double = 0
    @Published var responseData: Data?
    @Published var response: HTTPURLResponse?
    @Published var responseError: Error?
    
     var statusCode: Int {
        return response?.statusCode ?? 0
    }
    

    
    private var header: [HeaderEntry] {
        return transformHeaders(response?.allHeaderFields ?? [:])
    }
    
    private var  messageEncoding: BodyEncoding {
        return extractEncodingAndContentType(
            from: response
        ).0 ?? .utf8
    }
    
    private var  contentType: ContentType {
        return extractEncodingAndContentType(
            from: response
        ).1 ?? ContentType.text(.plain)
    }
    
    
    private var errorMessage: String? {
        return responseError?.localizedDescription
    }
    
    private var textRepresentation: String {
        let Stringheader = "Field\tValue"
        let rows = header.map { "\($0.key)\t\($0.value)" }
        return ([Stringheader] + rows).joined(separator: "\n")
    }
    
    private func transformHeaders(_ allHeaderFields: [AnyHashable: Any]) -> [HeaderEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z" // Common HTTP date format
        
        return allHeaderFields.reduce(into: [HeaderEntry]()) {
 result,
            entry in
            guard let key = entry.key as? String else {
                return
            } // Ensure key is String
            
            let value: String
            switch entry.value {
            case let string as String:
                value = string
            case let int as Int:
                value = String(int)
            case let number as NSNumber:
                value = number.stringValue
            case let date as Date:
                value = formatter.string(from: date)
            default:
                value = "\(entry.value)" // Fallback for unknown types
            }
            
            result.append(HeaderEntry(active: false, key: key, value: value))
        }
    }
    
    func extractEncodingAndContentType(from response: URLResponse?) -> (
        BodyEncoding?,
        ContentType?
    ) {
        guard let httpResponse = response as? HTTPURLResponse else {
            return (nil, nil)
        }
        
        // Read "Content-Type" header
        if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
            // Extract charset from Content-Type (e.g., "application/json; charset=utf-8")
            let components = contentType.lowercased().components(
                separatedBy: ";"
            )
            let mimeType = components.first?.trimmingCharacters(
                in: .whitespaces
            )
            
            let cType: ContentType? = .from(mimeType ?? "")
            
            var encoding: BodyEncoding?
            if let charsetComponent = components.first(
                where: { $0.contains("charset=")
                }) {
                let charset = charsetComponent.replacingOccurrences(of: "charset=", with: "").trimmingCharacters(
                    in: .whitespaces
                )
                
                // Match against your BodyEncoding enum
                encoding = BodyEncoding.allCases
                    .first { $0.value.contains(charset) }
            }
            
            return (encoding, cType)
        }
        
        return (nil, nil)
    }
}
