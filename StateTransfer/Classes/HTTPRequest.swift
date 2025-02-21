//
//  HTTPRequest.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import Foundation

struct HTTPRequest: Codable {
    var url: URL? = URL(string: "http://localhost:3000/")
    var method: HTTPMethod = .get
    var header: [HeaderEntry] = []
    var parameters: [HeaderEntry] = []
    var parameterEncoding: ParameterEncoding = .form
    var body: String = ""
    var bodyEncoding: BodyEncoding = .utf8

    var follorRedirects: Bool = true
    
    
    
    
    var request: URLRequest? {
        guard let url else { return nil }
        var request = URLRequest(url: url)

        switch method {
        case .get, .head, .options, .trace, .connect:
           
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = parameters
                .filter { $0.active }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
            request = URLRequest(url: urlComponents.url!)

        case .post, .put, .patch, .delete:
            switch parameterEncoding {
            case .form:
                let bodyString = parameters
                    .filter { $0.active }
                    .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }
                    .joined(separator: "&")
                request.httpBody = bodyString.data(using: bodyEncoding.encoding)

            case .json:
                var jsonBody: [String: Any] = [:]

                
                if let existingBody = request.httpBody,
                   let existingJson = try? JSONSerialization.jsonObject(with: existingBody, options: []) as? [String: Any] {
                    jsonBody = existingJson
                }

                
                for param in parameters where param.active {
                    jsonBody[param.key] = param.value
                }

              
                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody, options: [])
            }
        }

        request.httpMethod = method.rawValue

        
        if body.count > 0, let bodyData = body.data(using: bodyEncoding.encoding) {
            if request.httpBody == nil {
                request.httpBody = bodyData
            } else {
                var combinedBody = (try? JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: Any]) ?? [:]
                if let newBody = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] {
                    combinedBody.merge(newBody) { _, new in new }
                }
                request.httpBody = try? JSONSerialization.data(withJSONObject: combinedBody, options: [])
            }
        }

       
        for entry in header.filter({ $0.active }) {
            request.addValue(entry.value, forHTTPHeaderField: entry.key)
        }

        return request
    }
    
    func run() async{
       
        guard let request else { return  }

        let session = createSession(followRedirect: follorRedirects)
        let startTime = DispatchTime.now()

        do{
            let (data, response) = try await session.data(for: request)
            let endTime = DispatchTime.now()
            let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            DispatchQueue.main.async{
                NotificationCenter.default.post(name: NSNotification.Name("HTTPResponse"), object: (data, response, elapsedTime), userInfo: (response as? HTTPURLResponse)?.allHeaderFields)
           
            }
            
        }catch{
            print(error)
        }
    }
   private func createSession(followRedirect: Bool) -> URLSession {
        if followRedirect {
            return URLSession(configuration: .default) // Default behavior follows redirects
        } else {
            return URLSession(configuration: .default, delegate: RedirectHandler(), delegateQueue: nil)
        }
    }
}

enum ParameterEncoding: String, CaseIterable, Codable {
    
    case form = "Form encoded"
    case json = "JSON encoded"
    
}


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
}

enum HTTPMethod: String, CaseIterable, Codable {
    case get
    case post
    case put
    case head
    case delete
    case patch
    case options
    case connect
    case trace
    
    var description: String { rawValue.uppercased() }
}

struct HeaderEntry: Equatable, Identifiable, Codable {
    var id: UUID = UUID()
    var active: Bool
    var key: String
    var value: String
    
}


class RedirectHandler: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil) // Blocks redirection
    }
}
