//
//  WebView.swift
//  StateTransfer
//
//  Created by Holger Krupp on 04.03.25.
//

import WebKit
import SwiftUI

struct WebView: NSViewRepresentable {
    let htmlString: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}
