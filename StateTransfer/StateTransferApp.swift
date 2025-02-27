//
//  StateTransferApp.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

@main
struct StateTransferApp: App {
    
    var windowRef: NSWindow?
    
    var body: some Scene {
        DocumentGroup(newDocument: HTTPRequestDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
                   CommandGroup(replacing: .help) {
                       Button("Help") {
                           openHelpWindow()
                       }
                       .keyboardShortcut("?", modifiers: .command) // ⌘?
                       
                       Button("Rate on the App Store") {
                                           openAppStoreReviewPage()
                                       }
                   }
               }
        
        Window("StateTransfer", id: "welcome") {
                    AppLaunchView()
                }
        .defaultLaunchBehavior(.presented)
    }
    
    func openHelpWindow() {
        
        guard windowRef == nil else { return }
        
          let windowRef = NSWindow(
              contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
              styleMask: [.titled, .closable, .resizable],
              backing: .buffered,
              defer: false
          )
        windowRef.center()
        windowRef.setFrameAutosaveName("Help")
        windowRef.contentView = NSHostingView(rootView: HelpView())
        windowRef.isReleasedWhenClosed = false

        windowRef.makeKeyAndOrderFront(nil)
      }
    
    func openAppStoreReviewPage() {
        if let url = URL(string: "macappstore://apps.apple.com/app/6742325165?action=write-review") {
            NSWorkspace.shared.open(url)
        }
    }
}
