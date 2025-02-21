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
    @State private var statusCode: Int = 0
    @State private var message: String?
    @State private var messageEncoding: BodyEncoding = .utf8
    @State private var contentType: String = "text/plain"
    @State private var header: [HeaderEntry] = []
    @State private var displayOption: DisplayMode = .text
    @State private var requestTime: Double?
    
    @Binding var requestid: UUID
    
    private var textRepresentation: String {
        let Stringheader = "Field\tValue"
        let rows = header.map { "\($0.key)\t\($0.value)" }
        return ([Stringheader] + rows).joined(separator: "\n")
    }
    
    @State private var sortOrder = [KeyPathComparator(\HeaderEntry.key)]
    
    private var prettyPrintedJSON: String {
        guard let data = message?.data(using: messageEncoding.encoding),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: messageEncoding.encoding) else {
            return "Invalid JSON"
        }
        return prettyString
    }
    
    private var prettyPrintedXML: String {
        guard let data = message?.data(using: messageEncoding.encoding) else { return "Invalid XML" }
        do {
            let xmlDocument = try XMLDocument(data: data, options: .nodePrettyPrint)
            return xmlDocument.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
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
        case .xmlhtml:
            return prettyPrintedXML
        case .hex:
            return hexRepresentation
        }
    }
    private var colorForStatusCode: Color {
        switch statusCode {
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
        case xmlhtml = "XML / HTML"
        case hex
        
    }
    
    private let response = NotificationCenter.default
        .publisher(for: NSNotification.Name("HTTPResponse"))
    
    private let error = NotificationCenter.default
        .publisher(for: NSNotification.Name("HTTPError"))
    
    var body: some View {
        VStack {
            if statusCode != 0 {
                HStack{
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForStatusCode)
                        .frame(width: 50, height: 30)
                        .overlay{
                            Text(statusCode.description)
                        }
                    VStack{
                        Text("\(HTTPURLResponse.localizedString(forStatusCode: statusCode))")
                            .font(.title)
                            .lineLimit(3)
                            .minimumScaleFactor(0.1)
                        Text(requestTime.map { "Response time: \($0.formatted(.number.precision(.fractionLength(0)))) ms" } ?? "")
                    }
                }
            }
            Spacer()
            HStack{
                Text("Response Header")
                    .font(.headline)
                Spacer()
            }
           
            Table(header.sorted(by: { $0.key < $1.key }),sortOrder: $sortOrder) {
                TableColumn("Field") { column in
                    Text(column.key)
                    }
                            .width(min: 150, ideal: 200, max: 300)
                            
                        
                        TableColumn("Value") { column in Text(column.value) }
                            .width(min: 200, ideal: 400, max: 600)
                    }
            if header != [] {
                Button("Copy"){
                    copyToClipboard(value: textRepresentation)
                    }
            }

          
            
           
            
            Divider()
            if message != nil {
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
                        .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
                        .background(.thinMaterial)
                }
                if let message {
                    Button("Copy"){
                        copyToClipboard(value: message)
                    }
                }
            }
            Spacer()
        }
        .textSelection(.enabled)
        .onReceive(response) { (output) in
            self.loadHTTPResponse(output: output)
        }
        .onReceive(error) { (output) in
            self.loadHTTPError(output: output)
        }
    }
    
    private func copyToClipboard(value: String) {
          let pasteboard = NSPasteboard.general
          pasteboard.clearContents()
          pasteboard.setString(value, forType: .string)
      }
    
    private func loadHTTPError(output: NotificationCenter.Publisher.Output)  {
        guard let (id, error) = output.object as? (UUID, Error), id == requestid else { return  }
        
        statusCode = 0
        
        message = error.localizedDescription
        header = []
        requestTime = 0
        
        
    }
    
    private func loadHTTPResponse(output: NotificationCenter.Publisher.Output)  {
        guard let (id, data, response, elapsedTime) = output.object as? (UUID, Data, HTTPURLResponse, Double), id == requestid else { return  }
        statusCode = response.statusCode
        messageEncoding = extractEncodingAndContentType(from: response).0 ?? .utf8
        contentType = extractEncodingAndContentType(from: response).1 ?? "text/plain"
        message = String(data: data, encoding: messageEncoding.encoding)
        header = transformHeaders(response.allHeaderFields)
        requestTime = elapsedTime
    }
    
    private func transformHeaders(_ allHeaderFields: [AnyHashable: Any]) -> [HeaderEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z" // Common HTTP date format

        return allHeaderFields.reduce(into: [HeaderEntry]()) { result, entry in
            guard let key = entry.key as? String else { return } // Ensure key is String
            
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
    
    func extractEncodingAndContentType(from response: URLResponse?) -> (BodyEncoding?, String?) {
        guard let httpResponse = response as? HTTPURLResponse else { return (nil, nil) }

        // Read "Content-Type" header
        if let contentType = httpResponse.allHeaderFields["Content-Type"] as? String {
            // Extract charset from Content-Type (e.g., "application/json; charset=utf-8")
            let components = contentType.lowercased().components(separatedBy: ";")
            let mimeType = components.first?.trimmingCharacters(in: .whitespaces)

            var encoding: BodyEncoding?
            if let charsetComponent = components.first(where: { $0.contains("charset=") }) {
                let charset = charsetComponent.replacingOccurrences(of: "charset=", with: "").trimmingCharacters(in: .whitespaces)

                // Match against your BodyEncoding enum
                encoding = BodyEncoding.allCases.first { $0.value.contains(charset) }
            }

            return (encoding, mimeType)
        }

        return (nil, nil)
    }




}

#Preview {
    @Previewable @State var id: UUID = UUID()

    ResponseView(requestid: $id)
}
