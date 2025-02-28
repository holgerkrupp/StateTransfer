//
//  StatusBarView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import SwiftUI

struct StatusBarView: View {
    @Binding var request: HTTPRequest
    
    var body: some View {
        HStack {
            
            
           
            /*
            Button("Run in Terminal") {
                runCurlCommand()
            }
            .padding()
            */
            Button("Copy curl command to Clipboard") {
                copyCurlToClipboard()
            }
            .padding()
            Button("Copy Swift code to Clipboard") {
                copySwiftToClipboard()
            }
            .padding()
            Spacer()
            Button {
                Task{
                    await request.run()
                }
            } label: {
                Text("Send Request")
            }
            .buttonStyle(.borderedProminent)
            .padding()

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
}
