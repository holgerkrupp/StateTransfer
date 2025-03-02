//
//  HTTPRequest.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import Foundation



struct HTTPRequest: Codable, Hashable {
    var id = UUID()
    var name: String?
    var url: URL? = URL(string: "http://localhost:3000/")
    var method: HTTPMethod = .get
    var header: [HeaderEntry] = []
    var parameters: [HeaderEntry] = []
    var parameterEncoding: ParameterEncoding = .form
    var body: String = ""
    var bodyEncoding: BodyEncoding = .utf8

    var follorRedirects: Bool = true
    
    var authorizationCredentials: Authentication = Authentication()
    
    
    private enum CodingKeys: String, CodingKey {
        case url
        case name
        case method
        case header
        case parameters
        case body
        case parameterEncoding
        case bodyEncoding
        case follorRedirects
        case authorizationCredentials
    }
    
    init(){}
    
    // Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        method = try container.decode(HTTPMethod.self, forKey: .method)
        header = try container.decode([HeaderEntry].self, forKey: .header)
        parameters = try container.decode([HeaderEntry].self, forKey: .parameters)
        parameterEncoding = try container.decode(ParameterEncoding.self, forKey: .parameterEncoding)
        body = try container.decode(String.self, forKey: .body)
        bodyEncoding = try container.decode(BodyEncoding.self, forKey: .bodyEncoding)
        follorRedirects = try container.decode(Bool.self, forKey: .follorRedirects)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        // Decode authorizationCredentials but do NOT add it to CodingKeys
   
        let rawCredentials = try container.decodeIfPresent(Authentication.self, forKey: .authorizationCredentials)
           authorizationCredentials = rawCredentials ?? Authentication()
    }

    // Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encode(method, forKey: .method)
        try container.encode(header, forKey: .header)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(parameterEncoding, forKey: .parameterEncoding)
        try container.encode(body, forKey: .body)
        try container.encode(bodyEncoding, forKey: .bodyEncoding)
        try container.encode(follorRedirects, forKey: .follorRedirects)
        try container.encodeIfPresent(name, forKey: .name)
        // Do NOT encode authorizationCredentials
    }
    
    
    var request: URLRequest? {
        guard let url else { return nil }
        var request = URLRequest(url: url)
        
        
        // METHOD
        request.httpMethod = method.rawValue

        // HEADER
        
        if authorizationCredentials.active {
            request.setValue(basicAuthHeader(username: authorizationCredentials.username, password: authorizationCredentials.password), forHTTPHeaderField: "Authorization")
        }
        for entry in header.filter({ $0.active }) {
            request.addValue(entry.value, forHTTPHeaderField: entry.key)
        }

        // BODY
        switch method {
        case .get, .head, .options, .trace, .connect:
           
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = parameters
                .filter { $0.active }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
            request.url = urlComponents.url!

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
        
    
        if method != .get {
        
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

        }


        return request
    }
    
    var curlCommand: String {
        guard let request else { return  "" }
        guard let url = request.url else { return "" }
        
    
       
       var components = ["curl"]
       
       // Add HTTP method
       if let method = request.httpMethod, method != "GET" {
           components.append("-X \(method)")
       }
       
       // Add headers
       if let headers = request.allHTTPHeaderFields {
           for (key, value) in headers {
               components.append("-H \"\(key): \(value)\"")
           }
       }
       
       // Add body
       if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
           components.append("-d '\(bodyString)'")
       }
       
       // Add URL
       components.append("\"\(url.absoluteString)\"")
       
       return components.joined(separator: " \\\n    ")
    }
    var swiftCode: String {
        guard let request else { return  "" }
        guard let url = request.url else { return "" }

        var code = """
        var request = URLRequest(url: URL(string: "\(url.absoluteString)")!)
        request.httpMethod = "\(request.httpMethod ?? "GET")"
        """

        // Add headers
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            for (key, value) in headers {
                code += "\nrequest.setValue(\"\(value)\", forHTTPHeaderField: \"\(key)\")"
            }
        }

        // Add body (if present)
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            code += "\nrequest.httpBody = \"\(bodyString)\".data(using: .utf8)"
        }

        return code
    }
    var httpFile: String {
        guard let request else { return  "" }
        guard let url = request.url else { return "" }

        var httpContent = "\(request.httpMethod ?? "GET") \(url.absoluteString)"

        // Add headers
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            for (key, value) in headers {
                httpContent += "\n\(key): \(value)"
            }
        }

        // Add body (if applicable)
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            httpContent += "\n\n\(bodyString)"
        }

        return httpContent
    }
    

    
    func basicAuthHeader(username: String, password: String) -> String {
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else { return "" }
        let base64Credentials = data.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    func run() async{
       
        guard let request else { return  }
        
       // dump(request)

        let session = createSession(followRedirect: follorRedirects)
        let startTime = DispatchTime.now()

        do{
            let (data, response) = try await session.data(for: request)
            
            let endTime = DispatchTime.now()
            let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            DispatchQueue.main.async{
                NotificationCenter.default.post(name: NSNotification.Name("HTTPResponse"), object: (id, data, response, elapsedTime), userInfo: (response as? HTTPURLResponse)?.allHeaderFields)
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    if let server =  request.url?.host(),
                       !authorizationCredentials.username.isEmpty,
                       !authorizationCredentials.password.isEmpty {
                        KeychainManager.saveCredentials(authorizationCredentials, server: server)
                    }
                } else {
                    print("Invalid credentials, not saving to Keychain.")
                }
            }
            
        }catch{
            print(error)
            DispatchQueue.main.async{
                NotificationCenter.default.post(name: NSNotification.Name("HTTPError"), object: (id, error))
            }
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


struct HeaderEntry: Equatable, Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var active: Bool
    var key: String
    var value: String
    
    private enum CodingKeys: String, CodingKey {
        case active
        case key
        case value
    }
    
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
