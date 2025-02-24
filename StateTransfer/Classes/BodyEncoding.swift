//
//  BodyEncoding.swift
//  StateTransfer
//
//  Created by Holger Krupp on 24.02.25.
//


enum BodyEncoding: String, CaseIterable, Codable {
    case utf8 = "UTF-8"
    case utf16 = "UTF-16"
    case utf16LE = "UTF-16LE"
    case utf16BE = "UTF-16BE"
    case utf32 = "UTF-32"
    case utf32LE = "UTF-32LE"
    case utf32BE = "UTF-32BE"
    case iso_8859_1 = "ISO-8859-1 (Latin-1)"
    case ascii = "ASCII"
    case shiftJIS = "Shift-JIS"

    var value: String {
        switch self {
        case .utf8:
            return "charset=utf-8"
        case .utf16:
            return "charset=utf-16"
        case .utf16LE:
            return "charset=utf-16le"
        case .utf16BE:
            return "charset=utf-16be"
        case .utf32:
            return "charset=utf-32"
        case .utf32LE:
            return "charset=utf-32le"
        case .utf32BE:
            return "charset=utf-32be"
        case .iso_8859_1:
            return "charset=iso-8859-1"
        case .ascii:
            return "charset=ascii"
        case .shiftJIS:
            return "charset=shift_jis"
        }
    }

    var encoding: String.Encoding {
        switch self {
        case .utf8:
            return .utf8
        case .utf16:
            return .utf16
        case .utf16LE:
            return .utf16LittleEndian
        case .utf16BE:
            return .utf16BigEndian
        case .utf32:
            return .utf32
        case .utf32LE:
            return .utf32LittleEndian
        case .utf32BE:
            return .utf32BigEndian
        case .iso_8859_1:
            return .isoLatin1
        case .ascii:
            return .ascii
        case .shiftJIS:
            return .shiftJIS
        }
    }
    var unicodeEncoding: Any.Type {
        switch self {
        case .utf8:
            return Unicode.UTF8.self
        case .utf16, .utf16LE, .utf16BE:
            return Unicode.UTF16.self
        case .utf32, .utf32LE, .utf32BE:
            return Unicode.UTF32.self
        default:
            return Unicode.UTF8.self // No direct mapping in Unicode.Encoding
        }
    }
    

}
