import Foundation

struct RequestChain: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = "New Chain"
    var startNodeID: UUID?
    var nodes: [RequestChainNode] = []
    var links: [RequestChainLink] = []
    var inputs: [ChainInputParameter] = []

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case startNodeID
        case nodes
        case links
        case inputs
    }

    init(
        id: UUID = UUID(),
        name: String = "New Chain",
        startNodeID: UUID? = nil,
        nodes: [RequestChainNode] = [],
        links: [RequestChainLink] = [],
        inputs: [ChainInputParameter] = []
    ) {
        self.id = id
        self.name = name
        self.startNodeID = startNodeID
        self.nodes = nodes
        self.links = links
        self.inputs = inputs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? "New Chain"
        startNodeID = try container.decodeIfPresent(
            UUID.self,
            forKey: .startNodeID
        )
        nodes = try container.decodeIfPresent(
            [RequestChainNode].self,
            forKey: .nodes
        ) ?? []
        var usedStepNames = Set<String>()
        for index in nodes.indices {
            var candidate = nodes[index].variableName
            if candidate.isEmpty || usedStepNames.contains(candidate) {
                candidate = "step\(index + 1)"
            }
            while usedStepNames.contains(candidate) {
                candidate += "_"
            }
            nodes[index].variableName = candidate
            usedStepNames.insert(candidate)
        }
        links = try container.decodeIfPresent(
            [RequestChainLink].self,
            forKey: .links
        ) ?? []
        inputs = try container.decodeIfPresent(
            [ChainInputParameter].self,
            forKey: .inputs
        ) ?? []
    }
}

struct ChainInputParameter: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = ""
    var value = ""
}

struct RequestChainNode: Codable, Identifiable, Equatable {
    var id = UUID()
    var requestID: UUID
    var variableName = "step"

    private enum CodingKeys: String, CodingKey {
        case id
        case requestID
        case variableName
    }

    init(
        id: UUID = UUID(),
        requestID: UUID,
        variableName: String = "step"
    ) {
        self.id = id
        self.requestID = requestID
        self.variableName = variableName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        requestID = try container.decode(UUID.self, forKey: .requestID)
        variableName = try container.decodeIfPresent(
            String.self,
            forKey: .variableName
        ) ?? ""
    }
}

struct RequestChainLink: Codable, Identifiable, Equatable {
    var id = UUID()
    var sourceNodeID: UUID
    var destinationNodeID: UUID
    var conditions: [ChainCondition] = []
    var mappings: [ChainOutputMapping] = []
}

struct ChainCondition: Codable, Identifiable, Equatable {
    var id = UUID()
    var source: ChainValueSource = .status
    var operation: ChainComparisonOperation = .equals
    var expectedValue = "200"
}

struct ChainOutputMapping: Codable, Identifiable, Equatable {
    var id = UUID()
    var variableName = "value"
    var source: ChainValueSource = .jsonPath("$.value")
    var isOptional = false
}

enum ChainValueSource: Codable, Equatable {
    case status
    case header(String)
    case jsonPath(String)
    case xpath(String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    private enum Kind: String, Codable {
        case status
        case header
        case jsonPath
        case xpath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .status:
            self = .status
        case .header:
            self = .header(try container.decode(String.self, forKey: .value))
        case .jsonPath:
            self = .jsonPath(try container.decode(String.self, forKey: .value))
        case .xpath:
            self = .xpath(try container.decode(String.self, forKey: .value))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .status:
            try container.encode(Kind.status, forKey: .kind)
        case .header(let value):
            try container.encode(Kind.header, forKey: .kind)
            try container.encode(value, forKey: .value)
        case .jsonPath(let value):
            try container.encode(Kind.jsonPath, forKey: .kind)
            try container.encode(value, forKey: .value)
        case .xpath(let value):
            try container.encode(Kind.xpath, forKey: .kind)
            try container.encode(value, forKey: .value)
        }
    }
}

enum ChainComparisonOperation: String, Codable, CaseIterable {
    case equals
    case notEquals
    case contains
    case exists
    case lessThan
    case lessThanOrEqual
    case greaterThan
    case greaterThanOrEqual

    var title: String {
        switch self {
        case .equals: "Equals"
        case .notEquals: "Does Not Equal"
        case .contains: "Contains"
        case .exists: "Exists"
        case .lessThan: "Less Than"
        case .lessThanOrEqual: "Less Than or Equal"
        case .greaterThan: "Greater Than"
        case .greaterThanOrEqual: "Greater Than or Equal"
        }
    }
}

enum RequestChainValidationError: LocalizedError {
    case missingStartNode
    case startNodeHasIncomingLink
    case unreachableNode
    case missingRequest(UUID)
    case missingNode(UUID)
    case cycle
    case invalidStepName(String)
    case duplicateStepName(String)

    var errorDescription: String? {
        switch self {
        case .missingStartNode:
            "The chain must have exactly one valid start node."
        case .startNodeHasIncomingLink:
            "The start node cannot have an incoming link."
        case .unreachableNode:
            "Every node must be reachable from the start node."
        case .missingRequest:
            "A chain node references a request that no longer exists."
        case .missingNode:
            "A chain link references a node that no longer exists."
        case .cycle:
            "Request chains cannot contain cycles."
        case .invalidStepName(let name):
            "Invalid step key '\(name)'. Use letters, numbers, dashes, or underscores, starting with a letter or underscore."
        case .duplicateStepName(let name):
            "The step key '\(name)' is used more than once in this chain."
        }
    }
}

extension RequestChain {
    func validate(requestIDs: Set<UUID>) throws {
        guard let startNodeID, nodes.contains(where: { $0.id == startNodeID }) else {
            throw RequestChainValidationError.missingStartNode
        }

        let nodeIDs = Set(nodes.map(\.id))
        var stepNames = Set<String>()
        for node in nodes where !requestIDs.contains(node.requestID) {
            throw RequestChainValidationError.missingRequest(node.requestID)
        }
        for node in nodes {
            guard node.variableName.range(
                of: #"^[A-Za-z_][A-Za-z0-9_-]*$"#,
                options: .regularExpression
            ) != nil else {
                throw RequestChainValidationError.invalidStepName(
                    node.variableName
                )
            }
            guard stepNames.insert(node.variableName).inserted else {
                throw RequestChainValidationError.duplicateStepName(
                    node.variableName
                )
            }
        }
        for link in links {
            guard nodeIDs.contains(link.sourceNodeID) else {
                throw RequestChainValidationError.missingNode(link.sourceNodeID)
            }
            guard nodeIDs.contains(link.destinationNodeID) else {
                throw RequestChainValidationError.missingNode(link.destinationNodeID)
            }
        }
        if links.contains(where: { $0.destinationNodeID == startNodeID }) {
            throw RequestChainValidationError.startNodeHasIncomingLink
        }

        var visiting = Set<UUID>()
        var visited = Set<UUID>()
        let outgoing = Dictionary(grouping: links, by: \.sourceNodeID)

        func visit(_ nodeID: UUID) throws {
            if visiting.contains(nodeID) {
                throw RequestChainValidationError.cycle
            }
            guard !visited.contains(nodeID) else { return }

            visiting.insert(nodeID)
            for link in outgoing[nodeID, default: []] {
                try visit(link.destinationNodeID)
            }
            visiting.remove(nodeID)
            visited.insert(nodeID)
        }

        try visit(startNodeID)
        if visited != nodeIDs {
            throw RequestChainValidationError.unreachableNode
        }
    }
}
