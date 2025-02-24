//
//  ResponseView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI
import Combine
import Foundation


struct ResponseView: View {
    @State private var message: String?
    @State private var image: Image?
    @State private var displayOption: DisplayMode = .text
    
    @Binding var request: HTTPRequest
 
    
    private var requestTime: Double? {
        request.requestResponse?.elapsedTime
    }
    
    private var header: [HeaderEntry] {
        return transformHeaders(request.requestResponse?.response?.allHeaderFields ?? [:])
    }
    
    private var  messageEncoding: BodyEncoding {
        return extractEncodingAndContentType(
            from: request.requestResponse?.response
        ).0 ?? .utf8
    }
    
    private var  contentType: ContentType {
        return extractEncodingAndContentType(
            from: request.requestResponse?.response
        ).1 ?? ContentType.text(.plain)
    }
    
    
    private var errorMessage: String? {
        return request.requestResponse?.responseError?.localizedDescription
    }
    
    private var textRepresentation: String {
        let Stringheader = "Field\tValue"
        let rows = header.map { "\($0.key)\t\($0.value)" }
        return ([Stringheader] + rows).joined(separator: "\n")
    }
    
    @State private var sortOrder = [KeyPathComparator(\HeaderEntry.key)]
    
    private var prettyPrintedJSON: String {
        guard let data = message?.data(using: messageEncoding.encoding),
              let jsonObject = try? JSONSerialization.jsonObject(
                with: data,
                options: []
              ),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: jsonObject,
                options: .prettyPrinted
              ),
              let prettyString = String(data: prettyData, encoding: messageEncoding.encoding) else {
            return "Invalid JSON"
        }
        return prettyString
    }
    
    private var prettyPrintedXML: String {
        guard let data = message?.data(using: messageEncoding.encoding) else {
            return "Invalid XML"
        }
        do {
            let xmlDocument = try XMLDocument(
                data: data,
                options: .nodePrettyPrint
            )
            return xmlDocument
                .xmlString(
                    options: [.nodePrettyPrint, .nodeCompactEmptyElement]
                )
        } catch {
            return "Error formatting XML: \(error)"
        }
    }
    
    private var hexRepresentation: String {
        guard let data = message?.data(using: messageEncoding.encoding) else {
            return "Invalid String"
        }
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private var displayRepresentation: String {
        switch displayOption {
        case .text:
            return message ?? ""
        case .json:
            return prettyPrintedJSON
        case .xml:
            return prettyPrintedXML
        case .hex:
            return hexRepresentation
        }
    }
    private var colorForStatusCode: Color {
        switch request.requestResponse?.statusCode ?? 0{
        case 200..<300: // Success (Green)
            return Color.green.opacity(0.7) // Soft green
        case 300..<400: // Redirect (Blueish)
            return Color.blue.opacity(0.6) // Light blue
        case 400..<500: // Client Errors (Orange)
            return Color.orange.opacity(0.7) // Soft orange
        case 500..<600: // Server Errors (Red)
            return Color.red.opacity(0.7) // Soft red
        default: // Unknown (Gray)
            return Color.gray.opacity(0.5) // Neutral gray
        }
    }
    
    enum DisplayMode: String, CaseIterable {
        case text
        case json
        case xml
        case hex
        
    }
    
    private let response = NotificationCenter.default
        .publisher(for: NSNotification.Name("HTTPResponse"))
    
   
    
    var body: some View {
        VStack {
            if request.requestResponse?.statusCode != 0 {
                HStack{
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForStatusCode)
                        .frame(width: 50, height: 30)
                        .overlay{
                            Text(request.requestResponse?.statusCode.description ?? "")
                        }
                    VStack{
                        Text(
                            "\(HTTPURLResponse.localizedString(forStatusCode: request.requestResponse?.statusCode ?? 000))"
                        )
                        .font(.title)
                        .lineLimit(3)
                        .minimumScaleFactor(0.1)
                        Text(
                            requestTime
                                .map { "Response time: \($0.formatted(.number.precision(.fractionLength(0)))) ms"
                                } ?? "")
                    }
                }
            }
            Spacer()
            HStack{
                Text("Response Header")
                    .font(.headline)
                Spacer()
            }
            
            Table(
                header.sorted(by: { $0.key < $1.key }),
                sortOrder: $sortOrder
            ) {
                TableColumn("Field") { column in
                    Text(column.key)
                        .monospaced()
                }
                .width(min: 150, ideal: 200, max: 300)
                
                
                TableColumn("Value") { column in
                    Text(column.value)
                        .monospaced()
                }
                .width(min: 200, ideal: 400, max: 600)
            }
            if header != [] {
                Button("Copy"){
                    copyToClipboard(value: textRepresentation)
                }
            }
            
            
            
            
            
            Divider()
            if let errorMessage{
                ScrollView {
                    Text(errorMessage)
                    
                        .monospaced()
                        .lineLimit(nil)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 200,
                            alignment: .leading
                        )
                        .background(.thinMaterial)
                }
            }else{
                
                switch contentType {
                case .text:
                    HStack {
                        Text("Response Body")
                            .font(.headline)
                        
                        Spacer()
                        Picker("", selection: $displayOption, content: {
                            ForEach(DisplayMode.allCases, id: \.self) { display in
                                Text(display.rawValue).tag(display)
                            }
                        })
                        .frame(width: 100)
                    }
                    ScrollView {
                        Text(displayRepresentation)
                        
                            .monospaced()
                            .lineLimit(nil)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 200,
                                alignment: .leading
                            )
                            .background(.thinMaterial)
                    }
                case .image(_):
                    if let image{
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 200,
                                alignment: .leading
                            )
                    }else{
                        Text("Image not found for this Content-Type")
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 200,
                                alignment: .leading
                            )
                    }
                case .unknown(_):
                    Text("Unknown Content-Type")
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 200,
                            alignment: .leading
                        )
                }
                if let message {
                    Button("Copy"){
                        copyToClipboard(value: message)
                    }
                }
                
                Spacer()
            }
        }
        .textSelection(.enabled)
        .onAppear {
            self.loadHTTPResponse()
        }
        
      
    }
    
    private func copyToClipboard(value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
    

    
    private func loadHTTPResponse(){
        
        guard let data = request.requestResponse?.responseData else { return  }
        switch contentType {
        case .text:
            
            message = String(data: data, encoding: messageEncoding.encoding)
        case .image(_):
            if let nsImage = NSImage(data: data) {
                image = Image(nsImage: nsImage)
            }
        case .unknown(_):
            break
        }
       
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

#Preview {
    @Previewable @State var request: HTTPRequest = HTTPRequest.init()
    
    ResponseView(request: $request)
}
