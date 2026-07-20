import Foundation

struct HTTPRequestDocumentEnvelope: Codable {
    static let currentVersion = 2

    var version = currentVersion
    var requests: [HTTPRequest]
    var chains: [RequestChain]
}
