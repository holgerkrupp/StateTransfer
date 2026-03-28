//
//  HTTPRequest.swift
//  StateTransfer
//
//  Created by Holger Krupp on 19.02.25.
//

import Foundation

struct HTTPResponseSnapshot: Equatable {
    var statusCode: Int
    var message: String?
    var imageData: Data?
    var messageEncoding: BodyEncoding
    var contentType: ContentType
    var header: [HeaderEntry]
    var requestTime: Double?

    static func response(
        data: Data,
        response: HTTPURLResponse,
        elapsedTime: Double
    ) -> HTTPResponseSnapshot {
        let (encoding, type) = extractEncodingAndContentType(from: response)
        let messageEncoding = encoding ?? .utf8
        let contentType = type ?? .text(.plain)

        var message: String?
        var imageData: Data?

        switch contentType {
        case .text:
            message = String(data: data, encoding: messageEncoding.encoding)
        case .image:
            imageData = data
        case .unknown:
            break
        }

        return HTTPResponseSnapshot(
            statusCode: response.statusCode,
            message: message,
            imageData: imageData,
            messageEncoding: messageEncoding,
            contentType: contentType,
            header: transformHeaders(response.allHeaderFields),
            requestTime: elapsedTime
        )
    }

    static func error(_ error: Error) -> HTTPResponseSnapshot {
        HTTPResponseSnapshot(
            statusCode: 0,
            message: error.localizedDescription,
            imageData: nil,
            messageEncoding: .utf8,
            contentType: .text(.plain),
            header: [],
            requestTime: 0
        )
    }

    private static func extractEncodingAndContentType(
        from response: HTTPURLResponse
    ) -> (BodyEncoding?, ContentType?) {
        guard let contentType = response.allHeaderFields["Content-Type"] as? String else {
            return (nil, nil)
        }

        let components = contentType.lowercased().components(separatedBy: ";")
        let mimeType = components.first?.trimmingCharacters(in: .whitespaces)
        let resolvedContentType = ContentType.from(mimeType ?? "")

        let encoding = components
            .first(where: { $0.contains("charset=") })
            .flatMap { charsetComponent in
                let charset = charsetComponent
                    .replacingOccurrences(of: "charset=", with: "")
                    .trimmingCharacters(in: .whitespaces)

                return BodyEncoding.allCases.first { $0.value.contains(charset) }
            }

        return (encoding, resolvedContentType)
    }

    private static func transformHeaders(
        _ allHeaderFields: [AnyHashable: Any]
    ) -> [HeaderEntry] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"

        return allHeaderFields.reduce(into: [HeaderEntry]()) { result, entry in
            guard let key = entry.key as? String else {
                return
            }

            let value: String
            switch entry.value {
            case let string as String:
                value = string
            case let int as Int:
                value = String(int)
            case let number as NSNumber:
                value = number.stringValue
            case let date as Date:
                value = formatter.string(from: date)
            default:
                value = "\(entry.value)"
            }

            result.append(HeaderEntry(active: false, key: key, value: value))
        }
    }
}

class HTTPRequest: Codable, ObservableObject, Equatable {
    static func == (lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        lhs.id == rhs.id
    }
    
   
    
    @Published var id = UUID()
    @Published var name: String = "unnamed" { didSet { notifyChange() } }
    @Published var url: URL? = URL(string: "http://localhost:3000/") { didSet { notifyChange() } }
    @Published var method: HTTPMethod = .get { didSet { notifyChange() } }
    @Published var header: [HeaderEntry] = [] { didSet { notifyChange() } }
    @Published var parameters: [HeaderEntry] = [] { didSet { notifyChange() } }
    @Published var parameterEncoding: ParameterEncoding = .form { didSet { notifyChange() } }
    @Published var body: String = "" { didSet { notifyChange() } }
    @Published var bodyEncoding: BodyEncoding = .utf8 { didSet { notifyChange() } }
    @Published var follorRedirects: Bool = true { didSet { notifyChange() } }
    @Published var authorizationCredentials: Authentication = Authentication() { didSet { notifyChange() } }
    @Published var responseSnapshot: HTTPResponseSnapshot?

    private func notifyChange() {
           objectWillChange.send() // Notify SwiftUI about property change
           onChange?() // Trigger document save
         
       }

       var onChange: (() -> Void)? 
    
    
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
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        method = try container.decode(HTTPMethod.self, forKey: .method)
        header = try container.decode([HeaderEntry].self, forKey: .header)
        parameters = try container.decode([HeaderEntry].self, forKey: .parameters)
        parameterEncoding = try container.decode(ParameterEncoding.self, forKey: .parameterEncoding)
        body = try container.decode(String.self, forKey: .body)
        bodyEncoding = try container.decode(BodyEncoding.self, forKey: .bodyEncoding)
        follorRedirects = try container.decode(Bool.self, forKey: .follorRedirects)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "unnamed"
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
        try container.encode(name, forKey: .name)
        // Do NOT encode authorizationCredentials
    }
    
    
    var request: URLRequest? {
        guard let url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if authorizationCredentials.active {
            request.setValue(
                basicAuthHeader(
                    username: authorizationCredentials.username,
                    password: authorizationCredentials.password
                ),
                forHTTPHeaderField: "Authorization"
            )
        }

        for entry in header where entry.active {
            request.addValue(entry.value, forHTTPHeaderField: entry.key)
        }

        let activeParameters = parameters.filter(\.active)
        let rawBody = body.trimmingCharacters(in: .whitespacesAndNewlines)

        switch method {
        case .get, .head, .options, .trace, .connect:
            if let requestURL = mergedURL(baseURL: url, with: activeParameters) {
                request.url = requestURL
            }

        case .post, .put, .patch, .delete:
            switch parameterEncoding {
            case .form:
                let encodedParameters = formEncodedBody(from: activeParameters)

                if !rawBody.isEmpty, !encodedParameters.isEmpty {
                    request.httpBody = "\(rawBody)&\(encodedParameters)".data(using: bodyEncoding.encoding)
                } else if !encodedParameters.isEmpty {
                    request.httpBody = encodedParameters.data(using: bodyEncoding.encoding)
                } else if !rawBody.isEmpty {
                    request.httpBody = rawBody.data(using: bodyEncoding.encoding)
                }

                if request.httpBody != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue(
                        "application/x-www-form-urlencoded; \(bodyEncoding.value)",
                        forHTTPHeaderField: "Content-Type"
                    )
                }

            case .json:
                request.httpBody = jsonBody(from: rawBody, parameters: activeParameters)

                if request.httpBody != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue(
                        "application/json; \(bodyEncoding.value)",
                        forHTTPHeaderField: "Content-Type"
                    )
                }
            }

            if request.httpBody != nil,
               request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("text/plain; \(bodyEncoding.value)", forHTTPHeaderField: "Content-Type")
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
    
    @MainActor
    func run() async{
        guard let request else { return  }
        let credentials = authorizationCredentials

        let session = createSession(followRedirect: follorRedirects)
        let startTime = DispatchTime.now()

        do{
            let (data, response) = try await session.data(for: request)
            
            let endTime = DispatchTime.now()
            let elapsedTime = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000

            if let httpResponse = response as? HTTPURLResponse {
                responseSnapshot = HTTPResponseSnapshot.response(
                    data: data,
                    response: httpResponse,
                    elapsedTime: elapsedTime
                )

                if httpResponse.statusCode == 200 {
                    if let server = request.url?.host(),
                       !credentials.username.isEmpty,
                       !credentials.password.isEmpty {
                        KeychainManager.saveCredentials(credentials, server: server)
                    }
                } else {
                    print("Invalid credentials, not saving to Keychain.")
                }
            }
        }catch{
            print(error)
            responseSnapshot = HTTPResponseSnapshot.error(error)
        }
    }
   private func createSession(followRedirect: Bool) -> URLSession {
        if followRedirect {
            return URLSession(configuration: .default) // Default behavior follows redirects
        } else {
            return URLSession(configuration: .default, delegate: RedirectHandler(), delegateQueue: nil)
        }
    }

    private func mergedURL(baseURL: URL, with parameters: [HeaderEntry]) -> URL? {
        guard !parameters.isEmpty else { return baseURL }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return baseURL
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(contentsOf: parameters.map {
            URLQueryItem(name: $0.key, value: $0.value)
        })
        components.queryItems = queryItems

        return components.url
    }

    private func formEncodedBody(from parameters: [HeaderEntry]) -> String {
        parameters
            .map {
                "\(formEncoded($0.key))=\(formEncoded($0.value))"
            }
            .joined(separator: "&")
    }

    private func jsonBody(from rawBody: String, parameters: [HeaderEntry]) -> Data? {
        guard !rawBody.isEmpty || !parameters.isEmpty else {
            return nil
        }

        if parameters.isEmpty {
            return rawBody.data(using: bodyEncoding.encoding)
        }

        var jsonObject: [String: Any] = [:]

        if !rawBody.isEmpty {
            guard let rawData = rawBody.data(using: bodyEncoding.encoding),
                  let existingJSON = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any] else {
                return rawBody.data(using: bodyEncoding.encoding)
            }
            jsonObject = existingJSON
        }

        for parameter in parameters {
            jsonObject[parameter.key] = parameter.value
        }

        return try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
    }

    private func formEncoded(_ value: String) -> String {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: ":#[]@!$&'()*+,;=")

        return value
            .addingPercentEncoding(withAllowedCharacters: allowedCharacters)?
            .replacingOccurrences(of: "%20", with: "+") ?? value
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
