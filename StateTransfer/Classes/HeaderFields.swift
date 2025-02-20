//
//  HeaderFields.swift
//  StateTransfer
//
//  Created by Holger Krupp on 20.02.25.
//

import Foundation


enum HeaderFields: String, CaseIterable {
    case Accept
    case AcceptEncoding = "Accept-Encoding"
    case AcceptLanguage = "Accept-Language"
    case AccessControlAllowHeaders = "Access-Control-Allow-Headers"
    case AccessControlAllowMethods = "Access-Control-Allow-Methods"
    case AccessControlAllowOrigin = "Access-Control-Allow-Origin"
    case AccessControlRequestHeaders = "Access-Control-Request-Headers"
    case AccessControlRequestMethod = "Access-Control-Request-Method"
    case Authorization
    case CacheControl = "Cache-Control"
    case Connection
    case ContentDisposition = "Content-Disposition"
    case ContentEncoding = "Content-Encoding"
    case ContentLength = "Content-Length"
    case ContentType = "Content-Type"
    case Cookie
    case Date
    case Expect
    case Forwarded
    case From
    case Host
    case IfModifiedSince = "If-Modified-Since"
    case IfNoneMatch = "If-None-Match"
    case IfRange = "If-Range"
    case Location
    case MaxAge = "Max-Age"
    case Origin
    case Pragma
    case Range
    case Referer
    case ReferrerPolicy = "Referrer-Policy"
    case RetryAfter = "Retry-After"
    case Server
    case SetCookie = "Set-Cookie"
    case StrictTransportSecurity = "Strict-Transport-Security"
    case TE
    case TimingAllowOrigin = "Timing-Allow-Origin"
    case TransferEncoding = "Transfer-Encoding"
    case Upgrade
    case UserAgent = "User-Agent"
    case Vary
    case Via
    case WWWAuthenticate = "WWW-Authenticate"
    case XContentDuration = "X-Content-Duration"
    case XContentTypeOptions = "X-Content-Type-Options"
    case XFrameOptions = "X-Frame-Options"
    case XPoweredBy = "X-Powered-By"
    case XRequestID = "X-Request-ID"
    case XXSSProtection = "X-XSS-Protection"

    // Lazy loaded standard values
    static let standardValues: [HeaderFields: [String]] = {
        loadStandardValues()
    }()
    
    // Accessor for standard values
    var values: [String] {
        return HeaderFields.standardValues[self] ?? []
    }
    
    // Load standard values from JSON
    private static func loadStandardValues() -> [HeaderFields: [String]] {
        guard let url = Bundle.main.url(forResource: "HTTPHeaderStandardValues", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            print("❌ Failed to load header values from JSON")
            return [:]
        }

        var tempDict: [HeaderFields: [String]] = [:]
        for (key, values) in json {
            if let headerField = HeaderFields(rawValue: key) {
                tempDict[headerField] = values
            }
        }
        return tempDict
    }
}
