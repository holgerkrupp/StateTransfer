import Foundation

enum RequestTemplateError: LocalizedError {
    case missingVariable(String)
    case invalidURL(String)
    case disabledTemplateParameter(String)
    case requiresChainRun

    var errorDescription: String? {
        switch self {
        case .missingVariable(let name):
            "No runtime value is available for '{{\(name)}}'."
        case .invalidURL(let value):
            "The resolved URL is invalid: \(value)"
        case .disabledTemplateParameter(let name):
            "Parameter '\(name)' contains a runtime template but is disabled. Enable its checkbox so the mapped value is sent."
        case .requiresChainRun:
            "This request contains runtime placeholders. Use Run Chain so values such as '{{id}}' can be resolved."
        }
    }
}

struct RequestTemplateResolver {
    private static let pattern = #"\{\{\s*([A-Za-z_][A-Za-z0-9_.-]*)\s*\}\}"#

    static func resolve(_ template: String, values: [String: String]) throws -> String {
        let template = normalized(template)
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(template.startIndex..., in: template)
        var result = template

        for match in regex.matches(in: template, range: range).reversed() {
            guard let nameRange = Range(match.range(at: 1), in: template),
                  let fullRange = Range(match.range(at: 0), in: result) else {
                continue
            }
            let name = String(template[nameRange])
            guard let value = values[name] else {
                throw RequestTemplateError.missingVariable(name)
            }
            result.replaceSubrange(fullRange, with: value)
        }
        return result
    }

    static func containsPlaceholder(_ value: String) -> Bool {
        normalized(value).range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    static func placeholderNames(in value: String) -> [String] {
        let value = normalized(value)
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(value.startIndex..., in: value)
        return regex.matches(in: value, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: value) else {
                return nil
            }
            return String(value[range])
        }
    }

    static func placeholderNames(in request: HTTPRequest) -> Set<String> {
        let values = [request.url?.absoluteString ?? "", request.body]
            + request.header.map(\.value)
            + request.parameters.map(\.value)
        return Set(values.flatMap(placeholderNames(in:)))
    }

    static func requestContainsPlaceholder(_ request: HTTPRequest) -> Bool {
        containsPlaceholder(request.url?.absoluteString ?? "")
            || request.header.contains { containsPlaceholder($0.value) }
            || request.parameters.contains { containsPlaceholder($0.value) }
            || containsPlaceholder(request.body)
    }

    private static func normalized(_ value: String) -> String {
        var result = value
        var previous: String

        repeat {
            previous = result
            result = result
                .replacingOccurrences(
                    of: "%257B",
                    with: "%7B",
                    options: .caseInsensitive
                )
                .replacingOccurrences(
                    of: "%257D",
                    with: "%7D",
                    options: .caseInsensitive
                )
                .replacingOccurrences(
                    of: "%7B",
                    with: "{",
                    options: .caseInsensitive
                )
                .replacingOccurrences(
                    of: "%7D",
                    with: "}",
                    options: .caseInsensitive
                )
        } while result != previous

        return result
    }
}

extension HTTPRequest {
    func resolvedURLRequest(values: [String: String]) throws -> URLRequest {
        guard let url else {
            throw RequestTemplateError.invalidURL("")
        }

        let resolvedURLString = try RequestTemplateResolver.resolve(
            url.absoluteString,
            values: values
        )
        guard let resolvedURL = URL(string: resolvedURLString),
              resolvedURL.isSupportedHTTPURL else {
            throw RequestTemplateError.invalidURL(resolvedURLString)
        }

        var result = URLRequest(url: resolvedURL)
        result.httpMethod = method.rawValue

        if authorizationCredentials.active {
            result.setValue(
                basicAuthHeader(
                    username: authorizationCredentials.username,
                    password: authorizationCredentials.password
                ),
                forHTTPHeaderField: "Authorization"
            )
        }

        for entry in header where entry.active {
            result.addValue(
                try RequestTemplateResolver.resolve(entry.value, values: values),
                forHTTPHeaderField: entry.key
            )
        }

        if let disabledParameter = parameters.first(where: {
            !$0.active && RequestTemplateResolver.containsPlaceholder($0.value)
        }) {
            throw RequestTemplateError.disabledTemplateParameter(
                disabledParameter.key
            )
        }

        let resolvedParameters = try parameters
            .filter(\.active)
            .map {
                HeaderEntry(
                    id: $0.id,
                    active: true,
                    key: $0.key,
                    value: try RequestTemplateResolver.resolve($0.value, values: values)
                )
            }
        let resolvedBody = try RequestTemplateResolver.resolve(body, values: values)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        switch method {
        case .get, .head, .options, .trace, .connect:
            if var components = URLComponents(
                url: resolvedURL,
                resolvingAgainstBaseURL: false
            ) {
                var queryItems = components.queryItems ?? []
                queryItems.append(contentsOf: resolvedParameters.map {
                    URLQueryItem(name: $0.key, value: $0.value)
                })
                components.queryItems = queryItems
                result.url = components.url
            }

        case .post, .put, .patch, .delete:
            switch parameterEncoding {
            case .form:
                let encodedParameters = resolvedParameters
                    .map { "\(formEncode($0.key))=\(formEncode($0.value))" }
                    .joined(separator: "&")
                let combined: String
                if !resolvedBody.isEmpty, !encodedParameters.isEmpty {
                    combined = "\(resolvedBody)&\(encodedParameters)"
                } else {
                    combined = resolvedBody.isEmpty ? encodedParameters : resolvedBody
                }
                result.httpBody = combined.isEmpty
                    ? nil
                    : combined.data(using: bodyEncoding.encoding)
                if result.httpBody != nil,
                   result.value(forHTTPHeaderField: "Content-Type") == nil {
                    result.setValue(
                        "application/x-www-form-urlencoded; \(bodyEncoding.value)",
                        forHTTPHeaderField: "Content-Type"
                    )
                }

            case .json:
                if resolvedParameters.isEmpty {
                    result.httpBody = resolvedBody.isEmpty
                        ? nil
                        : resolvedBody.data(using: bodyEncoding.encoding)
                } else {
                    var object: [String: Any] = [:]
                    if !resolvedBody.isEmpty,
                       let data = resolvedBody.data(using: bodyEncoding.encoding),
                       let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        object = existing
                    }
                    for parameter in resolvedParameters {
                        object[parameter.key] = parameter.value
                    }
                    result.httpBody = try JSONSerialization.data(withJSONObject: object)
                }
                if result.httpBody != nil,
                   result.value(forHTTPHeaderField: "Content-Type") == nil {
                    result.setValue(
                        "application/json; \(bodyEncoding.value)",
                        forHTTPHeaderField: "Content-Type"
                    )
                }
            }
        }

        return result
    }

    private func formEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return value
            .addingPercentEncoding(withAllowedCharacters: allowed)?
            .replacingOccurrences(of: "%20", with: "+") ?? value
    }
}
