import Foundation

enum ChainExecutionStatus: String {
    case waiting
    case running
    case succeeded
    case failed
    case skipped
    case cancelled
}

enum ChainExecutionError: LocalizedError {
    case invalidVariableName(String)
    case duplicateVariableName(String)

    var errorDescription: String? {
        switch self {
        case .invalidVariableName(let name):
            "Invalid runtime variable name '\(name)'. Use letters, numbers, dots, dashes, or underscores, starting with a letter or underscore."
        case .duplicateVariableName(let name):
            "The chain input variable '\(name)' is defined more than once."
        }
    }
}

struct ChainNodeExecution: Identifiable {
    let id: UUID
    let nodeID: UUID
    let requestID: UUID
    let startedAt: Date
    var status: ChainExecutionStatus
    var response: HTTPResponseSnapshot?
    var errorMessage: String?
    var variables: [String: String]
    var resolvedRequestURL: URL?
}

@MainActor
final class RequestChainRunner: ObservableObject {
    @Published private(set) var executions: [ChainNodeExecution] = []
    @Published private(set) var isRunning = false
    @Published private(set) var validationError: String?

    private var runTask: Task<Void, Never>?
    private let executor = HTTPRequestExecutor()
    private let extractor = ChainValueExtractor()

    func run(chain: RequestChain, requests: [HTTPRequest]) {
        cancel()
        reset()

        var requestMap: [UUID: HTTPRequest] = [:]
        for request in requests {
            guard requestMap.updateValue(request, forKey: request.id) == nil else {
                validationError = "The document contains duplicate request identifiers. Duplicate the affected request to give it a new identity."
                return
            }
        }
        do {
            try chain.validate(requestIDs: Set(requestMap.keys))
        } catch {
            validationError = error.localizedDescription
            return
        }
        guard let startNodeID = chain.startNodeID else { return }

        let initialContext: [String: String]
        do {
            initialContext = try inputContext(for: chain)
        } catch {
            validationError = error.localizedDescription
            return
        }

        isRunning = true
        runTask = Task { [weak self] in
            guard let self else { return }
            await self.executeNode(
                startNodeID,
                context: initialContext,
                chain: chain,
                requests: requestMap
            )
            if !Task.isCancelled {
                self.isRunning = false
            }
        }
    }

    private func inputContext(
        for chain: RequestChain
    ) throws -> [String: String] {
        var context: [String: String] = [:]
        for input in chain.inputs {
            guard input.name.range(
                of: #"^[A-Za-z_][A-Za-z0-9_.-]*$"#,
                options: .regularExpression
            ) != nil else {
                throw ChainExecutionError.invalidVariableName(input.name)
            }
            guard context[input.name] == nil else {
                throw ChainExecutionError.duplicateVariableName(input.name)
            }
            context[input.name] = input.value
            context["input.\(input.name)"] = input.value
        }
        return context
    }

    func cancel() {
        runTask?.cancel()
        runTask = nil
        for index in executions.indices
        where executions[index].status == .running
            || executions[index].status == .waiting {
            executions[index].status = .cancelled
        }
        isRunning = false
    }

    func reset() {
        runTask?.cancel()
        runTask = nil
        executions = []
        validationError = nil
        isRunning = false
    }

    func latestExecution(for nodeID: UUID) -> ChainNodeExecution? {
        executions.last { $0.nodeID == nodeID }
    }

    private func executeNode(
        _ nodeID: UUID,
        context: [String: String],
        chain: RequestChain,
        requests: [UUID: HTTPRequest]
    ) async {
        guard !Task.isCancelled,
              let node = chain.nodes.first(where: { $0.id == nodeID }),
              let request = requests[node.requestID] else {
            return
        }

        let executionID = UUID()
        executions.append(ChainNodeExecution(
            id: executionID,
            nodeID: nodeID,
            requestID: node.requestID,
            startedAt: Date(),
            status: .running,
            response: nil,
            errorMessage: nil,
            variables: context,
            resolvedRequestURL: nil
        ))

        do {
            let urlRequest = try request.resolvedURLRequest(values: context)
            update(executionID, resolvedRequestURL: urlRequest.url)
            let response = try await executor.execute(
                urlRequest,
                followRedirects: request.follorRedirects
            )
            guard !Task.isCancelled else {
                update(executionID, status: .cancelled)
                return
            }
            update(executionID, status: .succeeded, response: response)

            let outgoingLinks = chain.links.filter { $0.sourceNodeID == nodeID }
            var branches: [(RequestChainLink, [String: String])] = []

            for link in outgoingLinks {
                let matches = try link.conditions.allSatisfy {
                    try extractor.matches($0, response: response)
                }
                guard matches else { continue }

                var branchContext = context
                for mapping in link.mappings {
                    guard mapping.variableName.range(
                        of: #"^[A-Za-z_][A-Za-z0-9_.-]*$"#,
                        options: .regularExpression
                    ) != nil else {
                        throw ChainExecutionError.invalidVariableName(
                            mapping.variableName
                        )
                    }
                    if let value = try extractor.singleValue(
                        from: mapping.source,
                        response: response,
                        optional: mapping.isOptional
                    ) {
                        branchContext[mapping.variableName] = value
                        branchContext[
                            "steps.\(node.variableName).\(mapping.variableName)"
                        ] = value
                    }
                }
                branches.append((link, branchContext))
            }

            await withTaskGroup(of: Void.self) { group in
                for (link, branchContext) in branches {
                    group.addTask { [weak self] in
                        guard let self else { return }
                        await self.executeNode(
                            link.destinationNodeID,
                            context: branchContext,
                            chain: chain,
                            requests: requests
                        )
                    }
                }
            }
        } catch is CancellationError {
            update(executionID, status: .cancelled)
        } catch {
            update(
                executionID,
                status: .failed,
                errorMessage: error.localizedDescription
            )
        }
    }

    private func update(
        _ executionID: UUID,
        status: ChainExecutionStatus,
        response: HTTPResponseSnapshot? = nil,
        errorMessage: String? = nil
    ) {
        guard let index = executions.firstIndex(where: { $0.id == executionID }) else {
            return
        }
        executions[index].status = status
        if let response {
            executions[index].response = response
        }
        if let errorMessage {
            executions[index].errorMessage = errorMessage
        }
    }

    private func update(
        _ executionID: UUID,
        resolvedRequestURL: URL?
    ) {
        guard let index = executions.firstIndex(where: { $0.id == executionID }) else {
            return
        }
        executions[index].resolvedRequestURL = resolvedRequestURL
    }
}
