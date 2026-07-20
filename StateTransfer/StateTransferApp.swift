//
//  StateTransferApp.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

@main
struct StateTransferApp: App {

    @State private var helpWindow: NSWindow?
    @StateObject private var historyStore = RequestHistoryStore()

    var body: some Scene {
        DocumentGroup(newDocument: HTTPRequestDocument()) { file in
            ContentView(
                document: file.$document,
                historyStore: historyStore
            )
        }
        .defaultSize(width: 1000, height: 800)
        .commands {
            CommandGroup(replacing: .help) {
                Button("StateTransfer Help") {
                    openHelpWindow()
                }
                .keyboardShortcut("?", modifiers: .command)

                Button("Rate on the App Store") {
                    openAppStoreReviewPage()
                }
            }
            CommandGroup(after: .newItem) {
                ExampleView()
            }
            RequestHistoryCommands(historyStore: historyStore)
            CommandGroup(replacing: .importExport) { }
            CommandGroup(replacing: .printItem) { }
            CommandGroup(replacing: .systemServices) { }
            CommandGroup(replacing: .textFormatting) { }
        }

        Window("StateTransfer", id: "welcome") {
            AppLaunchView()
        }
        .defaultSize(width: 820, height: 520)
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.presented)
    }
    


    func openHelpWindow() {
        if let helpWindow {
            helpWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("Help")
        window.contentView = NSHostingView(rootView: HelpView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        helpWindow = window
      }
    
    func openAppStoreReviewPage() {
        if let url = URL(string: "macappstore://apps.apple.com/app/6742325165?action=write-review") {
            NSWorkspace.shared.open(url)
        }
    }
}
