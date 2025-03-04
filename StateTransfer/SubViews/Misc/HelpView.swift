//
//  HelpView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 26.02.25.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        VStack(spacing: 20) {
                Text("Help & Support")
                    .font(.largeTitle)
                    .bold()
                
                Text("For documentation, issues, and updates, visit my GitHub page:")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)

                Link("Open GitHub Repository", destination: URL(string: "https://github.com/holgerkrupp/StateTransfer")!)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding()
            Text("This app has been created by Holger Krupp.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            VStack{
                Text("StateTransfer uses following open source package:")
                Link("Highlightr", destination: URL(string: "https://github.com/raspu/Highlightr")!)
                    .font(.body)
                    .foregroundColor(.blue)
                    
            }
          
            
            }
            .frame(width: 400, height: 300)
            .padding()
    }
}

#Preview {
    HelpView()
}
