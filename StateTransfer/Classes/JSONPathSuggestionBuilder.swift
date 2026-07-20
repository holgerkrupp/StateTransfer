import Foundation

struct JSONPathSuggestion: Identifiable, Hashable {
    let path: String
    let sample: String

    var id: String { path }
}

struct JSONPathSuggestionBuilder {
    private let maximumSuggestions = 300
    private let maximumArrayElements = 20

    func suggestions(from data: Data?) -> [JSONPathSuggestion] {
        guard let data,
              let root = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        var suggestions: [JSONPathSuggestion] = []
        appendSuggestions(
            for: root,
            path: "$",
            into: &suggestions
        )
        return suggestions
    }

    private func appendSuggestions(
        for value: Any,
        path: String,
        into suggestions: inout [JSONPathSuggestion]
    ) {
        guard suggestions.count < maximumSuggestions else { return }

        switch value {
        case let object as [String: Any]:
            for key in object.keys.sorted() {
                guard suggestions.count < maximumSuggestions,
                      let child = object[key] else {
                    return
                }
                appendSuggestions(
                    for: child,
                    path: path + pathComponent(for: key),
                    into: &suggestions
                )
            }

        case let array as [Any]:
            for (index, child) in array.prefix(maximumArrayElements).enumerated() {
                guard suggestions.count < maximumSuggestions else { return }
                appendSuggestions(
                    for: child,
                    path: "\(path)[\(index)]",
                    into: &suggestions
                )
            }

        case is NSNull:
            suggestions.append(JSONPathSuggestion(path: path, sample: "null"))

        case let string as String:
            suggestions.append(JSONPathSuggestion(
                path: path,
                sample: shortened(string)
            ))

        case let number as NSNumber:
            suggestions.append(JSONPathSuggestion(
                path: path,
                sample: number.stringValue
            ))

        default:
            suggestions.append(JSONPathSuggestion(
                path: path,
                sample: shortened(String(describing: value))
            ))
        }
    }

    private func pathComponent(for key: String) -> String {
        if key.range(
            of: #"^[A-Za-z_][A-Za-z0-9_]*$"#,
            options: .regularExpression
        ) != nil {
            return ".\(key)"
        }

        let escaped = key
            .replacingOccurrences(of: #"\"#, with: #"\\"#)
            .replacingOccurrences(of: "'", with: #"\'"#)
        return "['\(escaped)']"
    }

    private func shortened(_ value: String) -> String {
        let singleLine = value.replacingOccurrences(of: "\n", with: " ")
        guard singleLine.count > 70 else { return singleLine }
        return String(singleLine.prefix(67)) + "..."
    }
}
