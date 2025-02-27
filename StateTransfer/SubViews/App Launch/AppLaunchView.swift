//
//  AppLaunchView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 25.02.25.
//

import SwiftUI

struct AppLaunchView: View {
    @StateObject private var recentManager = RecentDocumentsManager()

    var body: some View {
        HStack {
            Image("NetworkTerminal")
                .resizable()
                .scaledToFill()
           
              
                RecentFilesView()
                .environmentObject(recentManager)
            
        }
        OpenOrNewDocumentView()
            .environmentObject(recentManager)
    }
    
}

#Preview {
    AppLaunchView()
}
