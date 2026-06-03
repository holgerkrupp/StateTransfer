//
//  StatusBarView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct StatusBarView: View {
    @ObservedObject var request: HTTPRequest
    
    var body: some View {
        HStack {
            secondaryActionButton(
                title: "Copy curl",
                systemImage: "terminal"
            ) {
                copyCurlToClipboard()
            }
            secondaryActionButton(
                title: "Copy Swift",
                systemImage: "swift"
            ) {
                copySwiftToClipboard()
            }
            secondaryActionButton(
                title: "Export .http",
                systemImage: "square.and.arrow.up"
            ) {
                exportHttpFile()
            }
            Spacer()
            secondaryActionButton(
                title: "Request Header",
                systemImage: "list.bullet.rectangle",
                isDisabled: request.isRequestRunning
            ) {
                Task {
                    await request.requestHeadersOnly()
                }
            }
            primaryActionButton {
                Task{
                    await request.run()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            if #available(macOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: Capsule())
            } else {
                Capsule()
                    .fill(.thinMaterial)
            }
        }
    }
    
    private func runCurlCommand() {
        
        // Somehow not working / Terminal is not opening.
        
        guard !request.curlCommand.isEmpty else {
            print("curlEmpty")
            return
        }
        
        let curlCmd = request.curlCommand.replacingOccurrences(of: "\"", with: "\\\"") // Escape quotes
        
        let script = """
        tell application "Terminal"
            do script "\(curlCmd)"
            activate
        end tell
        """
        
        DispatchQueue.global().async {
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", script]
            process.launch()
        }
    }
    
    private func exportHttpFile() {
    
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: "http") ?? .plainText]
        savePanel.nameFieldStringValue = "request.http"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let correctedURL = url.pathExtension == "http" ? url : url.deletingPathExtension().appendingPathExtension("http")
                
                do {
                    try request.httpFile.write(to: correctedURL, atomically: true, encoding: .utf8)
                } catch {
                    print("Error saving .http file: \(error)")
                }
            }
        }
    }
    
    private func copyCurlToClipboard() {
        guard !request.curlCommand.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(request.curlCommand, forType: .string)
    }
    
    private func copySwiftToClipboard() {
        guard !request.swiftCode.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(request.swiftCode, forType: .string)
    }

    @ViewBuilder
    private func secondaryActionButton(
        title: String,
        systemImage: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .disabled(isDisabled)

        if #available(macOS 26.0, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func primaryActionButton(action: @escaping () -> Void) -> some View {
        let button = Button(action: action) {
            Label("Send Request", systemImage: "paperplane.fill")
        }
        .disabled(request.isRequestRunning)

        if #available(macOS 26.0, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent)
        }
    }
}
