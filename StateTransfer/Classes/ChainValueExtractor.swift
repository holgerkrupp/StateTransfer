import DynamicJSON
import Foundation

enum ChainValueError: LocalizedError {
    case missingBody
    case noMatch(String)
    case multipleMatches(String)
    case nonScalar(String)
    case invalidNumber(String)

    var errorDescription: String? {
        switch self {
        case .missingBody:
            "The response has no body to query."
        case .noMatch(let selector):
            "The selector returned no value: \(selector)"
        case .multipleMatches(let selector):
            "The selector returned more than one value: \(selector)"
        case .nonScalar(let selector):
            "The selector returned an object or array: \(selector)"
        case .invalidNumber(let value):
            "The comparison value is not numeric: \(value)"
        }
    }
}

struct ChainValueExtractor {
    func values(
        from source: ChainValueSource,
        response: HTTPResponseSnapshot
    ) throws -> [String] {
        switch source {
        case .status:
            return [String(response.statusCode)]

        case .header(let name):
            return response.header
                .filter { $0.key.caseInsensitiveCompare(name) == .orderedSame }
                .map(\.value)

        case .jsonPath(let path):
            guard let data = response.bodyData else {
                throw ChainValueError.missingBody
            }
            let json = try JSON(data: data)
            return try json.query(values: path).map { value in
                switch value {
                case .null:
                    return "null"
                case .boolean(let value):
                    return String(value)
                case .integer(let value):
                    return String(value)
                case .float(let value):
                    return String(value)
                case .string(let value):
                    return value
                case .array, .object:
                    throw ChainValueError.nonScalar(path)
                }
            }

        case .xpath(let path):
            guard let data = response.bodyData else {
                throw ChainValueError.missingBody
            }
            let document = try XMLDocument(data: data)
            return try document.nodes(forXPath: path).map {
                $0.stringValue ?? ""
            }
        }
    }

    func singleValue(
        from source: ChainValueSource,
        response: HTTPResponseSnapshot,
        optional: Bool
    ) throws -> String? {
        let results = try values(from: source, response: response)
        guard !results.isEmpty else {
            if optional { return nil }
            throw ChainValueError.noMatch(source.selectorDescription)
        }
        guard results.count == 1 else {
            throw ChainValueError.multipleMatches(source.selectorDescription)
        }
        return results[0]
    }

    func matches(
        _ condition: ChainCondition,
        response: HTTPResponseSnapshot
    ) throws -> Bool {
        let results = try values(from: condition.source, response: response)
        if condition.operation == .exists {
            return !results.isEmpty
        }
        guard results.count == 1 else {
            if results.isEmpty {
                throw ChainValueError.noMatch(condition.source.selectorDescription)
            }
            throw ChainValueError.multipleMatches(condition.source.selectorDescription)
        }

        let actual = results[0]
        switch condition.operation {
        case .equals:
            return actual == condition.expectedValue
        case .notEquals:
            return actual != condition.expectedValue
        case .contains:
            return actual.contains(condition.expectedValue)
        case .exists:
            return true
        case .lessThan:
            return try numeric(actual) < numeric(condition.expectedValue)
        case .lessThanOrEqual:
            return try numeric(actual) <= numeric(condition.expectedValue)
        case .greaterThan:
            return try numeric(actual) > numeric(condition.expectedValue)
        case .greaterThanOrEqual:
            return try numeric(actual) >= numeric(condition.expectedValue)
        }
    }

    private func numeric(_ value: String) throws -> Double {
        guard let number = Double(value) else {
            throw ChainValueError.invalidNumber(value)
        }
        return number
    }
}

extension ChainValueSource {
    var selectorDescription: String {
        switch self {
        case .status:
            "HTTP status"
        case .header(let name):
            "Header \(name)"
        case .jsonPath(let path):
            path
        case .xpath(let path):
            path
        }
    }
}
