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
    var follorRedirects: Bool = true
    
    
    
    
    var request : URLRequest? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        
        switch method {
        
        case .get:
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.field, value: $0.value) }

            request = URLRequest(url: urlComponents.url!)
        case .post:
            break
            /*
             
             Need to check the Body and might need to merge the parameters and the body in one JSON
             
             
             */
        default:
            break
        }
        
        
       
        request.httpMethod = method.rawValue
        if body.count > 0 {
            request.httpBody = body.data(using: .utf8)
        }
        
        for entry in header {
            request.addValue(entry.value, forHTTPHeaderField: entry.field)
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
    var field: String
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
