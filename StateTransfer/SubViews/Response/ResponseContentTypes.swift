//
//  ResponseContentTypes.swift
//  StateTransfer
//
//  Created by Holger Krupp on 23.02.25.
//


enum ContentType {
    case image(ImageContentType)
    case text(TextContentType)
    case unknown(String)
    
    static func from(_ rawValue: String) -> ContentType {
        if let imageType = ImageContentType.from(rawValue) {
            return .image(imageType)
        } else if let textType = TextContentType.from(rawValue) {
            return .text(textType)
        } else {
            return .unknown(rawValue)
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
        return TextContentType(rawValue: rawValue)
    }
}

