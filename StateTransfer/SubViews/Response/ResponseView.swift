//
//  ResponseView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI
import Foundation
import Highlightr
import UniformTypeIdentifiers


struct ResponseView: View {
    @ObservedObject var request: HTTPRequest
    @State private var statusCode: Int = 0
    @State private var message: String?
    @State private var image: Image?
    @State private var bodyData: Data?
    @State private var messageEncoding: BodyEncoding = .utf8
    @State private var contentType: ContentType = ContentType.text(.plain)
    @State private var header: [HeaderEntry] = []
    @State private var displayOption: DisplayMode = .text
    @State private var requestTime: Double?
    @State private var expectedContentLength: Int64?
    @State private var receivedBytes: Int64 = 0
    @State private var isLoading = false
    @State private var bodyWasSkipped = false
    @State private var bodyWasCancelled = false
    
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
        if displayRepresentation.count > 200_000 {
            return NSAttributedString(string: displayRepresentation)
        }

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

    private var progressValue: Double? {
        guard let expectedContentLength, expectedContentLength > 0 else {
            return nil
        }

        return min(Double(receivedBytes) / Double(expectedContentLength), 1)
    }

    private var progressDescription: String {
        let received = ByteCountFormatter.string(
            fromByteCount: receivedBytes,
            countStyle: .file
        )

        guard let expectedContentLength, expectedContentLength > 0 else {
            return "\(received) received"
        }

        let expected = ByteCountFormatter.string(
            fromByteCount: expectedContentLength,
            countStyle: .file
        )
        return "\(received) of \(expected)"
    }

    private var canExportBody: Bool {
        bodyData?.isEmpty == false
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
                        .lineLimit(nil)
                        .help(headerHelpText(for: column))
                }
                .width(min: 150, ideal: 200, max: 300)
                
                
                TableColumn("Value") { column in
                    Text(column.value)
                        .monospaced()
                        .lineLimit(nil)
                        .help(headerHelpText(for: column))
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
                        bodyActionButtons
                        Picker("", selection: $displayOption, content: {
                            ForEach(availableDisplayModes, id: \.self) { display in
                                Text(display.title).tag(display)
                            }
                        })
                        .frame(width: 220)
                        .pickerStyle(.segmented)
                    }
                    responseProgressView
                    if bodyWasSkipped || bodyWasCancelled {
                        stoppedBodyPlaceholder
                    } else if isLoading && message == nil {
                        loadingBodyPlaceholder
                    } else if displayOption == .html {
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
                    bodyHeader(title: "Response Body")
                    responseProgressView
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
                    bodyHeader(title: "Response Body")
                    responseProgressView
                    unsupportedBodyView
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

    private func headerHelpText(for header: HeaderEntry) -> String {
        "\(header.key): \(header.value)"
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
        bodyData = snapshot.bodyData
        image = snapshot.imageData
            .flatMap(NSImage.init(data:))
            .map(Image.init(nsImage:))
        header = snapshot.header
        requestTime = snapshot.requestTime
        expectedContentLength = snapshot.expectedContentLength
        receivedBytes = snapshot.receivedBytes
        isLoading = snapshot.isLoading
        bodyWasSkipped = snapshot.bodyWasSkipped
        bodyWasCancelled = snapshot.bodyWasCancelled
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
        bodyData = nil
        messageEncoding = .utf8
        contentType = .text(.plain)
        header = []
        displayOption = .text
        requestTime = nil
        expectedContentLength = nil
        receivedBytes = 0
        isLoading = false
        bodyWasSkipped = false
        bodyWasCancelled = false
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

    private func saveResponseBody() {
        guard let bodyData else { return }

        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = suggestedBodyFilename
        if let contentType = suggestedUTType {
            savePanel.allowedContentTypes = [contentType]
        }

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            do {
                try bodyData.write(to: url, options: .atomic)
            } catch {
                print("Error saving response body: \(error)")
            }
        }
    }

    private func openResponseBody() {
        openResponseBody(with: nil)
    }

    private func openResponseBody(with applicationURL: URL?) {
        guard let bodyData else { return }

        do {
            let tempURL = temporaryResponseBodyURL()
            try FileManager.default.createDirectory(
                at: tempURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try bodyData.write(to: tempURL, options: .atomic)

            guard let applicationURL else {
                NSWorkspace.shared.open(tempURL)
                return
            }

            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open(
                [tempURL],
                withApplicationAt: applicationURL,
                configuration: configuration
            ) { _, error in
                if let error {
                    print("Error opening response body: \(error)")
                }
            }
        } catch {
            print("Error opening response body: \(error)")
        }
    }

    private func chooseApplicationForResponseBody() {
        let panel = NSOpenPanel()
        panel.title = "Choose Application"
        panel.prompt = "Open"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle, .unixExecutable]

        panel.begin { response in
            guard response == .OK, let applicationURL = panel.url else { return }
            openResponseBody(with: applicationURL)
        }
    }

    private func temporaryResponseBodyURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("StateTransfer")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(sanitizedBodyFilename)
    }

    private var supportedApplications: [ApplicationChoice] {
        guard let contentType = suggestedUTType else {
            return []
        }

        return NSWorkspace.shared
            .urlsForApplications(toOpen: contentType)
            .map { url in
                ApplicationChoice(
                    url: url,
                    name: FileManager.default.displayName(atPath: url.path)
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var suggestedBodyFilename: String {
        if let dispositionFilename {
            return dispositionFilename
        }

        if let lastPathComponent = request.url?.lastPathComponent,
           !lastPathComponent.isEmpty,
           lastPathComponent != "/" {
            return lastPathComponent.contains(".")
                ? lastPathComponent
                : "\(lastPathComponent).\(suggestedPathExtension)"
        }

        return "response.\(suggestedPathExtension)"
    }

    private var sanitizedBodyFilename: String {
        let invalidCharacters = CharacterSet(charactersIn: "/:")
        return suggestedBodyFilename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
    }

    private var dispositionFilename: String? {
        guard let disposition = header.first(where: {
            $0.key.caseInsensitiveCompare("Content-Disposition") == .orderedSame
        })?.value else {
            return nil
        }

        let parts = disposition.split(separator: ";").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return parts
            .first(where: { $0.lowercased().hasPrefix("filename=") })
            .map {
                $0.replacingOccurrences(of: "filename=", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
    }

    private var suggestedPathExtension: String {
        suggestedUTType?.preferredFilenameExtension ?? fallbackPathExtension
    }

    private var suggestedUTType: UTType? {
        UTType(mimeType: contentType.mimeType)
            ?? UTType(filenameExtension: (suggestedBodyFilename as NSString).pathExtension)
    }

    private var fallbackPathExtension: String {
        switch contentType {
        case .text(let subtype):
            switch subtype {
            case .plain: return "txt"
            case .html: return "html"
            case .xml: return "xml"
            case .json: return "json"
            case .yaml: return "yaml"
            case .markdown: return "md"
            case .csv: return "csv"
            case .css: return "css"
            case .javascript: return "js"
            case .rtf: return "rtf"
            }
        case .image(let subtype):
            switch subtype {
            case .jpeg, .jpg: return "jpg"
            case .png: return "png"
            case .gif: return "gif"
            case .svg: return "svg"
            case .webp: return "webp"
            case .bmp: return "bmp"
            case .tiff: return "tiff"
            case .ico: return "ico"
            case .avif: return "avif"
            }
        case .unknown:
            return "bin"
        }
    }
}

private extension ContentType {
    var mimeType: String {
        switch self {
        case .text(let subtype):
            return subtype.rawValue
        case .image(let subtype):
            return subtype.rawValue
        case .unknown(let rawValue):
            return rawValue
        }
    }

}

private struct ApplicationChoice: Identifiable {
    let url: URL
    let name: String

    var id: URL { url }
    var icon: NSImage {
        let image = NSWorkspace.shared.icon(forFile: url.path)
        image.size = NSSize(width: 16, height: 16)
        return image
    }
}

private extension ResponseView {
    @ViewBuilder
    var bodyActionButtons: some View {
        Menu {
            Button {
                openResponseBody()
            } label: {
                Label("Default App", systemImage: "arrow.up.forward.app")
            }

            let applications = supportedApplications
            if applications.isEmpty {
                Button("No matching apps found") { }
                    .disabled(true)
            } else {
                Divider()

                ForEach(applications) { application in
                    Button {
                        openResponseBody(with: application.url)
                    } label: {
                        Label {
                            Text(application.name)
                        } icon: {
                            Image(nsImage: application.icon)
                        }
                    }
                }
            }

            Divider()

            Button {
                chooseApplicationForResponseBody()
            } label: {
                Label("Other...", systemImage: "ellipsis.circle")
            }
        } label: {
            Label("Open In...", systemImage: "arrow.up.forward.app")
        }
        .disabled(!canExportBody)

        Button {
            saveResponseBody()
        } label: {
            Label("Save File", systemImage: "square.and.arrow.down")
        }
        .disabled(!canExportBody)
    }

    @ViewBuilder
    var responseProgressView: some View {
        if isLoading {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    if let progressValue {
                        ProgressView(value: progressValue)
                    } else {
                        ProgressView()
                    }

                    Text(progressDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    request.cancelBodyDownload()
                } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
            }
            .padding(.vertical, 6)
        }
    }

    var loadingBodyPlaceholder: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Receiving response body")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    var stoppedBodyPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: bodyWasCancelled ? "xmark.circle" : "list.bullet.rectangle")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text(bodyWasCancelled ? "Body download cancelled" : "Body download skipped")
                .font(.headline)

            Text(progressDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    func bodyHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()
            bodyActionButtons
        }
    }

    var unsupportedBodyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("This response body cannot be displayed as text.")
                .font(.headline)

            Text("\(contentType.mimeType) · \(progressDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

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
