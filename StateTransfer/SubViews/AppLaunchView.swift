//
//  AppLaunchView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI

struct AppLaunchView: View {
    var body: some View {
        HStack {
            Image("NetworkTerminal")
                .resizable()
                .scaledToFill()
            RecentFilesView()
        }
        OpenOrNewDocumentView()
    }
}

#Preview {
    AppLaunchView()
}
