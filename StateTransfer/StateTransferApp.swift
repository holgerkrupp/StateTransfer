//
//  StateTransferApp.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import SwiftUI

@main
struct StateTransferApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: HTTPRequestDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
