//
//  ResponseView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI
import Foundation
import Highlightr


struct ResponseView: View {
    @ObservedObject var request: HTTPRequest
    @State private var statusCode: Int = 0
    @State private var message: String?
    @State private var image: Image?
    @State private var messageEncoding: BodyEncoding = .utf8
    @State private var contentType: ContentType = ContentType.text(.plain)
    @State private var header: [HeaderEntry] = []
    @State private var displayOption: DisplayMode = .text
    @State private var requestTime: Double?
    
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
        case .html:
            return message ?? ""
        }
    }

    private var availableDisplayModes: [DisplayMode] {
        guard case let .text(subtype) = contentType else {
            return []
        }

        switch subtype {
        case .json:
            return [.json, .text, .hex]
        case .xml:
            return [.xml, .text, .hex]
        case .html:
            return [.html, .text, .hex]
        default:
            return [.text, .hex]
        }
    }
    
    private var highlightedText: NSAttributedString {
        let highlightr = Highlightr()!
        highlightr.setTheme(to: "atom-one-dark") // Choose a theme

        let language: String
        switch displayOption {
        case .json: language = "json"
        case .xml: language = "xml"
        case .text: language = "plaintext"
        case .hex: language = "plaintext"
        case .html: language = "html"
        }

        return highlightr.highlight(displayRepresentation, as: language) ?? NSAttributedString(string: displayRepresentation)
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
        case xml
        case hex
        case html
        
        var title: String {
            switch self {
            case .html:
                return "Preview"
            default:
                return rawValue.uppercased()
            }
        }
    }
    
    var body: some View {
        VStack {
            if statusCode != 0 {
                HStack{
                    statusCodeBadge
                    VStack{
                        Text(
                            "\(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
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
            
                
                switch contentType {
                case .text:
                    HStack {
                        Text("Response Body")
                            .font(.headline)
                        
                        Spacer()
                        Picker("", selection: $displayOption, content: {
                            ForEach(availableDisplayModes, id: \.self) { display in
                                Text(display.title).tag(display)
                            }
                        })
                        .frame(width: 220)
                        .pickerStyle(.segmented)
                    }
                    if displayOption == .html {
                        WebView(htmlString: message ?? "")
                            .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
                    } else {
                        ScrollView {
                            Text(AttributedString(highlightedText))
                                .frame(maxWidth: .infinity, minHeight: 200, alignment: .leading)
                                .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.92))
                        )
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
            
            
        }
        .textSelection(.enabled)
        .onAppear {
            applyStoredResponse(request.responseSnapshot)
        }
        .onChange(of: request.responseSnapshot) { _, snapshot in
            applyStoredResponse(snapshot)
        }
    }
    
    private func copyToClipboard(value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
    
    private func applyStoredResponse(_ snapshot: HTTPResponseSnapshot?) {
        guard let snapshot else {
            resetResponse()
            return
        }

        statusCode = snapshot.statusCode
        messageEncoding = snapshot.messageEncoding
        contentType = snapshot.contentType
        message = snapshot.message
        image = snapshot.imageData
            .flatMap(NSImage.init(data:))
            .map(Image.init(nsImage:))
        header = snapshot.header
        requestTime = snapshot.requestTime
        displayOption = preferredDisplayMode(for: snapshot)
    }

    private func preferredDisplayMode(for snapshot: HTTPResponseSnapshot) -> DisplayMode {
        switch snapshot.contentType {
        case .text(let subtype):
            switch subtype {
            case .json:
                guard let data = snapshot.message?.data(using: snapshot.messageEncoding.encoding) else {
                    return .text
                }
                return isValidJSON(data) ? .json : .text

            case .xml:
                guard let data = snapshot.message?.data(using: snapshot.messageEncoding.encoding) else {
                    return .text
                }
                return isValidXML(data) ? .xml : .text

            case .html:
                return .html

            default:
                return .text
            }

        case .image, .unknown:
            return .text
        }
    }

    private func resetResponse() {
        statusCode = 0
        message = nil
        image = nil
        messageEncoding = .utf8
        contentType = .text(.plain)
        header = []
        displayOption = .text
        requestTime = nil
    }
    
    private func isValidJSON(_ data: Data) -> Bool {
        return (try? JSONSerialization.jsonObject(with: data, options: [])) != nil
    }

    private func isValidXML(_ data: Data) -> Bool {
        do {
            _ = try XMLDocument(data: data, options: .documentTidyXML)
            return true
        } catch {
            return false
        }
    }

    
}

private extension ResponseView {
    @ViewBuilder
    var statusCodeBadge: some View {
        let badgeLabel = Text(statusCode.description)
            .font(.headline)
            .frame(minWidth: 52, minHeight: 32)

        if #available(macOS 26.0, *) {
            badgeLabel
                .glassEffect(.regular.tint(colorForStatusCode), in: Capsule())
        } else {
            badgeLabel
                .background(colorForStatusCode, in: Capsule())
        }
    }
}

#Preview {
    let request = HTTPRequest()
    
    ResponseView(request: request)
}
