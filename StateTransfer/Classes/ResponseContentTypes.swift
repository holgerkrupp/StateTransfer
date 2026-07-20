//
//  ResponseContentTypes.swift
//  StateTransfer
//
//  Created by Holger Krupp on 23.02.25.
//

import Foundation


enum ContentType: Equatable {
    case image(ImageContentType)
    case text(TextContentType)
    case unknown(String)
    
    static func from(_ rawValue: String) -> ContentType {
        let mimeType = rawValue
            .split(separator: ";", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""

        if let imageType = ImageContentType.from(mimeType) {
            return .image(imageType)
        } else if let textType = TextContentType.from(mimeType) {
            return .text(textType)
        } else {
            return .unknown(mimeType)
        }
    }
}

enum ImageContentType: String {
    case jpeg = "image/jpeg"
    case jpg = "image/jpg"
    case png = "image/png"
    case gif = "image/gif"
    case svg = "image/svg+xml"
    case webp = "image/webp"
    case bmp = "image/bmp"
    case tiff = "image/tiff"
    case ico = "image/x-icon"
    case avif = "image/avif"
    
    static func from(_ rawValue: String) -> ImageContentType? {
        return ImageContentType(rawValue: rawValue)
    }
}

enum TextContentType: String {
    case plain = "text/plain"
    case html = "text/html"
    case xml = "application/xml"
    case json = "application/json"
    case yaml = "application/x-yaml"
    case markdown = "text/markdown"
    case csv = "text/csv"
    case css = "text/css"
    case javascript = "application/javascript"
    case rtf = "application/rtf"
    
    static func from(_ rawValue: String) -> TextContentType? {
        if let exactType = TextContentType(rawValue: rawValue) {
            return exactType
        }

        switch rawValue {
        case "text/xml", "application/xhtml+xml":
            return .xml
        case "text/json":
            return .json
        case "text/yaml", "application/yaml":
            return .yaml
        case "text/javascript", "application/x-javascript":
            return .javascript
        case "text/rtf":
            return .rtf
        case "application/x-www-form-urlencoded", "application/graphql", "application/sql":
            return .plain
        default:
            if rawValue.hasSuffix("+json") {
                return .json
            }
            if rawValue.hasSuffix("+xml") {
                return .xml
            }
            if rawValue.hasPrefix("text/") {
                return .plain
            }
            return nil
        }
    }
}
