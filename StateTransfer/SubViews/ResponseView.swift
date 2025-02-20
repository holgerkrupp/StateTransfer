//
//  ResponseView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI
import Combine


struct ResponseView: View {
    @State private var statusCode: Int?
    @State private var message: String?
    @State private var header: [HeaderEntry] = []
    @State private var displayOption: DisplayMode = .text
    @State private var requestTime: Double?
    
    private var textRepresentation: String {
        let Stringheader = "Field\tValue"
        let rows = header.map { "\($0.field)\t\($0.value)" }
        return ([Stringheader] + rows).joined(separator: "\n")
    }
    
    
    private var prettyPrintedJSON: String {
        guard let data = message?.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return "Invalid JSON"
        }
        return prettyString
    }
    
    private var hexRepresentation: String {
        guard let data = message?.data(using: .utf8) else {
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
     //   case .xmlhtml:
       //     return prettyPrintedJSON
        case .hex:
            return hexRepresentation
        }
    }

    enum DisplayMode: String, CaseIterable {
        case text
        case json
    //    case xmlhtml = "XML / HTML"
        case hex
        
    }
    
    private let response = NotificationCenter.default
        .publisher(for: NSNotification.Name("HTTPResponse"))
    
    var body: some View {
        VStack {
            if statusCode != nil {
    
            Text("Statuscode: \(statusCode ?? 0) - \(HTTPURLResponse.localizedString(forStatusCode: statusCode ?? 0))")
                Text(requestTime.map { "Response time: \($0.formatted()) ms" } ?? "")
            }
            Spacer()
            HStack{
                Text("Response Header")
                    .font(.headline)
                Spacer()
            }
           
            Table(header) {
                TableColumn("Field") { column in
                    Text(column.field)
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
                
                Text(displayRepresentation)
                    .monospaced()
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
                    .background(.thinMaterial)
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
    }
    
    private func copyToClipboard(value: String) {
          let pasteboard = NSPasteboard.general
          pasteboard.clearContents()
          pasteboard.setString(value, forType: .string)
      }
    
    private func loadHTTPResponse(output: NotificationCenter.Publisher.Output)  {
        guard let (data, response, elapsedTime) = output.object as? (Data, HTTPURLResponse, Double) else { return  }
        statusCode = response.statusCode
        message = String(decoding: data, as: UTF8.self)
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

            result.append(HeaderEntry(active: false, field: key, value: value))
        }
    }
 
}

#Preview {
    ResponseView()
}
