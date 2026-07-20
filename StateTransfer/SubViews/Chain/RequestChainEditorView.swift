import SwiftUI

private enum ChainEditorSelection: Hashable {
    case node(UUID)
    case link(UUID)
}

private struct ChainNodeFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [UUID: Anchor<CGRect>],
        nextValue: () -> [UUID: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct ChainDataDependency: Identifiable {
    let sourceNodeID: UUID
    let destinationNodeID: UUID
    let variableName: String

    var id: String {
        "\(sourceNodeID)-\(destinationNodeID)-\(variableName)"
    }
}

struct RequestChainEditorView: View {
    @ObservedObject var document: HTTPRequestDocument
    @ObservedObject var historyStore: RequestHistoryStore
    @ObservedObject var runner: RequestChainRunner
    @State private var selectedChainID: UUID?
    @State private var selection: ChainEditorSelection?
    @State private var editorError: String?
    @State private var inspectorFraction: CGFloat = 0.5
    @State private var showsChainInputs = false
    @GestureState private var inspectorDividerTranslation: CGFloat = 0

    var body: some View {
        HSplitView {
            chainSidebar
                .frame(
                    minWidth: 170,
                    idealWidth: 200,
                    maxWidth: 260,
                    maxHeight: .infinity,
                    alignment: .top
                )

            if let chainBinding {
                chainWorkspace(chain: chainBinding)
            } else {
                ContentUnavailableView(
                    "No Chain Selected",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    description: Text("Create a chain to build a request workflow.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .alert(
            "Chain Error",
            isPresented: Binding(
                get: { editorError != nil },
                set: { if !$0 { editorError = nil } }
            )
        ) {
            Button("OK") { editorError = nil }
        } message: {
            Text(editorError ?? "")
        }
        .onAppear {
            selectedChainID = selectedChainID ?? document.chains.first?.id
        }
    }

    private func chainWorkspace(chain: Binding<RequestChain>) -> some View {
        GeometryReader { geometry in
            let dividerWidth: CGFloat = 9
            let availableWidth = max(geometry.size.width - dividerWidth, 0)
            let minimumCanvasWidth = min(300, availableWidth / 2)
            let minimumInspectorWidth = min(380, availableWidth / 2)
            let minimumInspectorFraction = availableWidth > 0
                ? minimumInspectorWidth / availableWidth
                : 0.5
            let maximumInspectorFraction = availableWidth > 0
                ? 1 - (minimumCanvasWidth / availableWidth)
                : 0.5
            let preferredInspectorWidth =
                availableWidth * inspectorFraction - inspectorDividerTranslation
            let inspectorWidth = min(
                max(preferredInspectorWidth, minimumInspectorWidth),
                availableWidth - minimumCanvasWidth
            )

            HStack(spacing: 0) {
                chainCanvas(chain: chain)
                    .frame(width: max(availableWidth - inspectorWidth, 0))
                    .frame(maxHeight: .infinity, alignment: .top)

                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)
                    .frame(width: dividerWidth)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .updating($inspectorDividerTranslation) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                guard availableWidth > 0 else { return }
                                let adjustedFraction = (
                                    availableWidth * inspectorFraction
                                        - value.translation.width
                                ) / availableWidth
                                inspectorFraction = min(
                                    max(adjustedFraction, minimumInspectorFraction),
                                    maximumInspectorFraction
                                )
                            }
                    )
                    .accessibilityLabel("Resize chain inspector")

                chainInspector(chain: chain)
                    .frame(width: inspectorWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(minWidth: 680, maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chainBinding: Binding<RequestChain>? {
        guard let selectedChainID,
              let index = document.chains.firstIndex(where: { $0.id == selectedChainID }) else {
            return nil
        }
        return $document.chains[index]
    }

    private var chainSidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedChainID) {
                ForEach(document.chains) { chain in
                    Label(chain.name, systemImage: "link")
                        .tag(chain.id)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                deleteChain(chain.id)
                            }
                        }
                }
            }
            .listStyle(.sidebar)

            Divider()
            HStack {
                Button {
                    let chain = document.addChain()
                    selectedChainID = chain.id
                    selection = nil
                } label: {
                    Label("Add Chain", systemImage: "plus")
                }
                Spacer()
                Button(role: .destructive) {
                    if let selectedChainID {
                        deleteChain(selectedChainID)
                    }
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedChainID == nil)
            }
            .buttonStyle(.borderless)
            .padding(10)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func chainCanvas(chain: Binding<RequestChain>) -> some View {
        VStack(spacing: 0) {
            chainToolbar(chain: chain)
            Divider()

            if chain.wrappedValue.nodes.isEmpty {
                ContentUnavailableView {
                    Label("Empty Chain", systemImage: "point.3.connected.trianglepath.dotted")
                } description: {
                    Text("Add a request to create the start node.")
                } actions: {
                    requestMenu(title: "Add Start Request") { request in
                        addStartNode(requestID: request.id, chain: chain)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chain.wrappedValue.nodes) { node in
                            chainNodeCard(node, chain: chain)
                            outgoingLinks(from: node.id, chain: chain)
                        }
                    }
                    .padding()
                    .overlayPreferenceValue(ChainNodeFramePreferenceKey.self) {
                        dependencyOverlay(
                            anchors: $0,
                            chain: chain.wrappedValue
                        )
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func chainToolbar(chain: Binding<RequestChain>) -> some View {
        HStack {
            TextField("Chain Name", text: chain.name)
                .textFieldStyle(.plain)
                .font(.headline)

            Spacer()
            Button {
                showsChainInputs.toggle()
            } label: {
                Label(
                    chain.wrappedValue.inputs.isEmpty
                        ? "Inputs"
                        : "Inputs (\(chain.wrappedValue.inputs.count))",
                    systemImage: "curlybraces"
                )
            }
            .popover(isPresented: $showsChainInputs, arrowEdge: .bottom) {
                ChainInputsEditor(inputs: chain.inputs)
            }
            if runner.isRunning {
                Button("Cancel", systemImage: "stop.fill") {
                    runner.cancel()
                }
            } else {
                Button("Run Chain", systemImage: "play.fill") {
                    runner.run(
                        chain: chain.wrappedValue,
                        requests: document.requests
                    )
                    if let error = runner.validationError {
                        editorError = error
                    }
                }
                .disabled(chain.wrappedValue.nodes.isEmpty)
            }
            Button("Reset", systemImage: "arrow.counterclockwise") {
                runner.reset()
            }
            .disabled(runner.executions.isEmpty)
        }
        .padding(12)
    }

    private func chainNodeCard(
        _ node: RequestChainNode,
        chain: Binding<RequestChain>
    ) -> some View {
        let request = document.requests.first { $0.id == node.requestID }
        let execution = runner.latestExecution(for: node.id)
        let isStart = chain.wrappedValue.startNodeID == node.id
        let color = nodeColor(node.id, chain: chain.wrappedValue)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isStart ? "play.circle.fill" : "circle.fill")
                    .foregroundStyle(isStart ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(request?.name ?? "Missing Request")
                        .font(.headline)
                    Text("steps.\(node.variableName)")
                        .font(.caption2)
                        .foregroundStyle(color)
                    Text(request.map { "\($0.method.description) \($0.url?.absoluteString ?? "")" } ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                executionBadge(execution?.status ?? .waiting)
            }

            if let execution, let resolvedURL = execution.resolvedRequestURL {
                Text("Sent: \(resolvedURL.absoluteString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            HStack {
                requestMenu(title: "Add Branch") { request in
                    addDestination(
                        requestID: request.id,
                        from: node.id,
                        chain: chain
                    )
                }
                Menu("Connect") {
                    ForEach(chain.wrappedValue.nodes.filter { $0.id != node.id }) { destination in
                        Button(nodeTitle(destination)) {
                            connect(
                                sourceNodeID: node.id,
                                destinationNodeID: destination.id,
                                chain: chain
                            )
                        }
                    }
                }
                .disabled(chain.wrappedValue.nodes.count < 2)
                Spacer()
                Button(role: .destructive) {
                    removeNode(node.id, chain: chain)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(selection == .node(node.id) ? 0.18 : 0.09))
                .stroke(
                    selection == .node(node.id) ? Color.accentColor : .clear,
                    lineWidth: 2
                )
        }
        .overlay(alignment: .leading) {
            Capsule()
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 9)
        }
        .anchorPreference(
            key: ChainNodeFramePreferenceKey.self,
            value: .bounds
        ) {
            [node.id: $0]
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selection = .node(node.id)
        }
    }

    @ViewBuilder
    private func outgoingLinks(
        from nodeID: UUID,
        chain: Binding<RequestChain>
    ) -> some View {
        let links = chain.wrappedValue.links.filter { $0.sourceNodeID == nodeID }
        ForEach(links) { link in
            Button {
                selection = .link(link.id)
            } label: {
                HStack {
                    Image(systemName: "arrow.down")
                    Text("To \(nodeTitle(id: link.destinationNodeID, chain: chain.wrappedValue))")
                    if !link.conditions.isEmpty {
                        Text("\(link.conditions.count) condition(s)")
                            .foregroundStyle(.secondary)
                    }
                    if !link.mappings.isEmpty {
                        Text("\(link.mappings.count) mapping(s)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(
                    Capsule().fill(
                        selection == .link(link.id)
                            ? Color.accentColor.opacity(0.18)
                            : Color.secondary.opacity(0.08)
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func chainInspector(chain: Binding<RequestChain>) -> some View {
        switch selection {
        case .node(let nodeID):
            if let node = chain.wrappedValue.nodes.first(where: { $0.id == nodeID }),
               let nodeIndex = chain.wrappedValue.nodes.firstIndex(where: { $0.id == nodeID }),
               let request = document.requests.first(where: { $0.id == node.requestID }) {
                NodeInspectorView(
                    node: chain.nodes[nodeIndex],
                    request: request,
                    execution: runner.latestExecution(for: nodeID),
                    historyStore: historyStore
                )
                .id(nodeID)
            }
        case .link(let linkID):
            if let index = chain.wrappedValue.links.firstIndex(where: { $0.id == linkID }) {
                let sourceNodeID = chain.wrappedValue.links[index].sourceNodeID
                let sourceStepName = chain.wrappedValue.nodes
                    .first(where: { $0.id == sourceNodeID })?
                    .variableName ?? "step"
                let sourceRequest = chain.wrappedValue.nodes
                    .first(where: { $0.id == sourceNodeID })
                    .flatMap { sourceNode in
                        document.requests.first {
                            $0.id == sourceNode.requestID
                        }
                    }
                let siblingIndices = chain.wrappedValue.links.indices.filter {
                    chain.wrappedValue.links[$0].sourceNodeID == sourceNodeID
                }
                let siblingPosition = siblingIndices.firstIndex(of: index) ?? 0
                if let sourceRequest {
                    ChainLinkInspectorView(
                        link: chain.links[index],
                        sourceNodeID: sourceNodeID,
                        sourceStepName: sourceStepName,
                        sourceRequest: sourceRequest,
                        runner: runner,
                        canMoveUp: siblingPosition > 0,
                        canMoveDown: siblingPosition < siblingIndices.count - 1,
                        onMoveUp: {
                            guard siblingPosition > 0 else { return }
                            chain.wrappedValue.links.swapAt(
                                index,
                                siblingIndices[siblingPosition - 1]
                            )
                        },
                        onMoveDown: {
                            guard siblingPosition < siblingIndices.count - 1 else { return }
                            chain.wrappedValue.links.swapAt(
                                index,
                                siblingIndices[siblingPosition + 1]
                            )
                        },
                        onDelete: {
                            chain.wrappedValue.links.removeAll { $0.id == linkID }
                            selection = nil
                        }
                    )
                }
            }
        case nil:
            ContentUnavailableView(
                "Select a Step or Link",
                systemImage: "sidebar.right",
                description: Text("Edit requests, conditions, mappings, and inspect results here.")
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .center
            )
        }
    }

    private func requestMenu(
        title: String,
        action: @escaping (HTTPRequest) -> Void
    ) -> some View {
        Menu(title) {
            ForEach(document.requests, id: \.id) { request in
                Button(request.name) { action(request) }
            }
            Divider()
            Button("New Request") {
                let request = HTTPRequest()
                document.addRequest(request)
                action(request)
            }
        }
    }

    private func addStartNode(requestID: UUID, chain: Binding<RequestChain>) {
        let node = RequestChainNode(
            requestID: requestID,
            variableName: uniqueStepName(
                for: requestID,
                chain: chain.wrappedValue
            )
        )
        chain.wrappedValue.nodes.append(node)
        chain.wrappedValue.startNodeID = node.id
        selection = .node(node.id)
    }

    private func addDestination(
        requestID: UUID,
        from sourceNodeID: UUID,
        chain: Binding<RequestChain>
    ) {
        let node = RequestChainNode(
            requestID: requestID,
            variableName: uniqueStepName(
                for: requestID,
                chain: chain.wrappedValue
            )
        )
        chain.wrappedValue.nodes.append(node)
        chain.wrappedValue.links.append(RequestChainLink(
            sourceNodeID: sourceNodeID,
            destinationNodeID: node.id
        ))
        selection = .node(node.id)
    }

    private func connect(
        sourceNodeID: UUID,
        destinationNodeID: UUID,
        chain: Binding<RequestChain>
    ) {
        guard !chain.wrappedValue.links.contains(where: {
            $0.sourceNodeID == sourceNodeID
                && $0.destinationNodeID == destinationNodeID
        }) else { return }

        var candidate = chain.wrappedValue
        let link = RequestChainLink(
            sourceNodeID: sourceNodeID,
            destinationNodeID: destinationNodeID
        )
        candidate.links.append(link)
        do {
            try candidate.validate(requestIDs: Set(document.requests.map(\.id)))
            chain.wrappedValue = candidate
            selection = .link(link.id)
        } catch {
            editorError = error.localizedDescription
        }
    }

    private func removeNode(_ nodeID: UUID, chain: Binding<RequestChain>) {
        chain.wrappedValue.nodes.removeAll { $0.id == nodeID }
        chain.wrappedValue.links.removeAll {
            $0.sourceNodeID == nodeID || $0.destinationNodeID == nodeID
        }
        if chain.wrappedValue.startNodeID == nodeID {
            chain.wrappedValue.startNodeID = chain.wrappedValue.nodes.first?.id
        }
        selection = nil
    }

    private func deleteChain(_ id: UUID) {
        document.chains.removeAll { $0.id == id }
        selectedChainID = document.chains.first?.id
        selection = nil
        runner.reset()
    }

    private func nodeTitle(_ node: RequestChainNode) -> String {
        document.requests.first { $0.id == node.requestID }?.name ?? "Missing Request"
    }

    private func nodeTitle(id: UUID, chain: RequestChain) -> String {
        guard let node = chain.nodes.first(where: { $0.id == id }) else {
            return "Missing Node"
        }
        return nodeTitle(node)
    }

    private func executionBadge(_ status: ChainExecutionStatus) -> some View {
        Label(status.rawValue.capitalized, systemImage: status.systemImage)
            .font(.caption)
            .foregroundStyle(status.color)
    }

    private func uniqueStepName(
        for requestID: UUID,
        chain: RequestChain
    ) -> String {
        let requestName = document.requests
            .first(where: { $0.id == requestID })?
            .name ?? "step"
        var base = requestName
            .replacingOccurrences(
                of: #"[^A-Za-z0-9_-]+"#,
                with: "_",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "_-"))
        if base.isEmpty || base.first?.isNumber == true {
            base = "step_\(base)"
        }
        var candidate = base
        var suffix = 2
        let existing = Set(chain.nodes.map(\.variableName))
        while existing.contains(candidate) {
            candidate = "\(base)_\(suffix)"
            suffix += 1
        }
        return candidate
    }

    private func nodeColor(_ nodeID: UUID, chain: RequestChain) -> Color {
        let colors: [Color] = [
            .blue, .orange, .green, .purple, .pink, .cyan, .indigo, .mint
        ]
        let index = chain.nodes.firstIndex(where: { $0.id == nodeID }) ?? 0
        return colors[index % colors.count]
    }

    private func dataDependencies(
        in chain: RequestChain
    ) -> [ChainDataDependency] {
        let nodesByName = Dictionary(
            uniqueKeysWithValues: chain.nodes.map { ($0.variableName, $0) }
        )
        return chain.nodes.flatMap { destination -> [ChainDataDependency] in
            guard let request = document.requests.first(
                where: { $0.id == destination.requestID }
            ) else {
                return []
            }
            return RequestTemplateResolver.placeholderNames(in: request)
                .compactMap { placeholder in
                    let parts = placeholder.split(separator: ".", maxSplits: 2)
                    guard parts.count == 3,
                          parts[0] == "steps",
                          let source = nodesByName[String(parts[1])],
                          source.id != destination.id else {
                        return nil
                    }
                    return ChainDataDependency(
                        sourceNodeID: source.id,
                        destinationNodeID: destination.id,
                        variableName: String(parts[2])
                    )
                }
        }
    }

    private func dependencyOverlay(
        anchors: [UUID: Anchor<CGRect>],
        chain: RequestChain
    ) -> some View {
        GeometryReader { proxy in
            Canvas { context, _ in
                for (index, dependency) in dataDependencies(in: chain).enumerated() {
                    guard let sourceAnchor = anchors[dependency.sourceNodeID],
                          let destinationAnchor = anchors[dependency.destinationNodeID] else {
                        continue
                    }
                    let source = proxy[sourceAnchor]
                    let destination = proxy[destinationAnchor]
                    let railX = min(source.minX, destination.minX)
                        - 7 - CGFloat(index % 5) * 4
                    var path = Path()
                    path.move(to: CGPoint(x: source.minX, y: source.midY))
                    path.addLine(to: CGPoint(x: railX, y: source.midY))
                    path.addLine(to: CGPoint(x: railX, y: destination.midY))
                    path.addLine(to: CGPoint(
                        x: destination.minX,
                        y: destination.midY
                    ))
                    context.stroke(
                        path,
                        with: .color(nodeColor(
                            dependency.sourceNodeID,
                            chain: chain
                        )),
                        style: StrokeStyle(
                            lineWidth: 2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }
            .allowsHitTesting(false)
        }
    }
}

private struct ChainInputsEditor: View {
    @Binding var inputs: [ChainInputParameter]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Chain Inputs")
                    .font(.headline)
                Text(
                    "Values are available as {{name}} or {{input.name}}."
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if inputs.isEmpty {
                Text("No input parameters")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 8) {
                    GridRow {
                        Text("Name")
                        Text("Value")
                        Color.clear.frame(width: 20, height: 1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    ForEach($inputs) { $input in
                        GridRow {
                            TextField("id", text: $input.name)
                                .frame(minWidth: 110)
                            TextField("Value", text: $input.value)
                                .frame(minWidth: 180)
                            Button(role: .destructive) {
                                inputs.removeAll { $0.id == input.id }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            HStack {
                Button("Add Input", systemImage: "plus") {
                    inputs.append(ChainInputParameter())
                }
                Spacer()
            }
        }
        .padding(16)
        .frame(minWidth: 390)
    }
}

private struct NodeInspectorView: View {
    @Binding var node: RequestChainNode
    @ObservedObject var request: HTTPRequest
    let execution: ChainNodeExecution?
    @ObservedObject var historyStore: RequestHistoryStore
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text("Request").tag(0)
                Text("Latest Result").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()
            if tab == 0 {
                VStack(spacing: 0) {
                    HStack {
                        Text("Step Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("step", text: $node.variableName)
                            .textFieldStyle(.roundedBorder)
                        Text("Use outputs as {{steps.\(node.variableName).value}}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    Divider()
                    if let execution,
                       !execution.variables.isEmpty
                        || execution.resolvedRequestURL != nil {
                        runtimeVariables(execution)
                        Divider()
                    }
                    RequestView(request: request, historyStore: historyStore)
                }
            } else if let response = execution?.response {
                ChainResponseView(request: request, response: response)
                    .id(execution?.id)
            } else if let error = execution?.errorMessage {
                ContentUnavailableView(
                    "Step Failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ContentUnavailableView(
                    "No Result",
                    systemImage: "clock",
                    description: Text("Run the chain to inspect this step's response.")
                )
            }
        }
        .onChange(of: execution?.status) { _, status in
            if status == .succeeded || status == .failed {
                tab = 1
            }
        }
        .onAppear {
            if execution?.response != nil || execution?.errorMessage != nil {
                tab = 1
            }
        }
    }

    private func runtimeVariables(_ execution: ChainNodeExecution) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Runtime Variables")
                .font(.caption)
                .fontWeight(.semibold)
            ForEach(execution.variables.keys.sorted(), id: \.self) { name in
                HStack(alignment: .firstTextBaseline) {
                    Text("{{\(name)}}")
                        .foregroundStyle(.secondary)
                    Text(execution.variables[name] ?? "")
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
                .font(.caption)
            }
            if let resolvedURL = execution.resolvedRequestURL {
                HStack(alignment: .firstTextBaseline) {
                    Text("Sent URL")
                        .foregroundStyle(.secondary)
                    Text(resolvedURL.absoluteString)
                        .textSelection(.enabled)
                        .lineLimit(3)
                }
                .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.accentColor.opacity(0.08))
    }
}

private struct ChainResponseView: View {
    @StateObject private var displayRequest: HTTPRequest

    init(request: HTTPRequest, response: HTTPResponseSnapshot) {
        let displayRequest = HTTPRequest()
        displayRequest.name = request.name
        displayRequest.url = request.url
        displayRequest.responseSnapshot = response
        _displayRequest = StateObject(wrappedValue: displayRequest)
    }

    var body: some View {
        ResponseView(request: displayRequest)
            .padding()
    }
}

private struct ChainLinkInspectorView: View {
    @Binding var link: RequestChainLink
    let sourceNodeID: UUID
    let sourceStepName: String
    @ObservedObject var sourceRequest: HTTPRequest
    @ObservedObject var runner: RequestChainRunner
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    private var sourceResponse: HTTPResponseSnapshot? {
        runner.latestExecution(for: sourceNodeID)?.response
            ?? sourceRequest.responseSnapshot
    }

    private var jsonPathSuggestions: [JSONPathSuggestion] {
        JSONPathSuggestionBuilder().suggestions(
            from: sourceResponse?.bodyData
        )
    }

    var body: some View {
        Form {
            Section("Source Response") {
                if let sourceResponse {
                    LabeledContent(
                        runner.latestExecution(for: sourceNodeID)?.response != nil
                            ? "Chain Run"
                            : "Test Request",
                        value: "HTTP \(sourceResponse.statusCode)"
                    )
                } else {
                    Text("Run the source request once to preview selectors.")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Branch Order") {
                HStack {
                    Button("Move Earlier", systemImage: "arrow.up", action: onMoveUp)
                        .disabled(!canMoveUp)
                    Button("Move Later", systemImage: "arrow.down", action: onMoveDown)
                        .disabled(!canMoveDown)
                }
            }
            Section("Conditions") {
                ForEach($link.conditions) { $condition in
                    ChainConditionEditor(condition: $condition) {
                        link.conditions.removeAll { $0.id == condition.id }
                    }
                }
                Button("Add Condition", systemImage: "plus") {
                    link.conditions.append(ChainCondition())
                }
            }

            Section("Output Mappings") {
                ForEach($link.mappings) { $mapping in
                    ChainMappingEditor(
                        mapping: $mapping,
                        sourceStepName: sourceStepName,
                        jsonPathSuggestions: jsonPathSuggestions,
                        sourceResponse: sourceResponse
                    ) {
                        link.mappings.removeAll { $0.id == mapping.id }
                    }
                }
                Button("Add Mapping", systemImage: "plus") {
                    link.mappings.append(ChainOutputMapping())
                }
            }

            Section {
                Button("Delete Link", role: .destructive, action: onDelete)
            }
        }
        .formStyle(.grouped)
    }
}

private struct ChainConditionEditor: View {
    @Binding var condition: ChainCondition
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ChainValueSourceEditor(source: $condition.source)
            Picker("Comparison", selection: $condition.operation) {
                ForEach(ChainComparisonOperation.allCases, id: \.self) {
                    Text($0.title).tag($0)
                }
            }
            if condition.operation != .exists {
                TextField("Expected Value", text: $condition.expectedValue)
            }
            HStack {
                Spacer()
                Button("Remove", role: .destructive, action: onDelete)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ChainMappingEditor: View {
    private enum Preview {
        case unavailable
        case value(String)
        case noValue
        case error(String)
    }

    @Binding var mapping: ChainOutputMapping
    let sourceStepName: String
    let jsonPathSuggestions: [JSONPathSuggestion]
    let sourceResponse: HTTPResponseSnapshot?
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Variable Name", text: $mapping.variableName)
            ChainValueSourceEditor(
                source: $mapping.source,
                allowsStatus: false,
                jsonPathSuggestions: jsonPathSuggestions
            )
            mappingPreview
            Toggle("Optional", isOn: $mapping.isOptional)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Short: {{\(mapping.variableName)}}")
                    Text(
                        "Qualified: {{steps.\(sourceStepName).\(mapping.variableName)}}"
                    )
                }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Remove", role: .destructive, action: onDelete)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var mappingPreview: some View {
        switch preview {
        case .unavailable:
            Label(
                "No source response available for preview",
                systemImage: "clock"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        case .value(let value):
            LabeledContent("Selected Value") {
                Text(value)
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
            .font(.caption)
        case .noValue:
            Label("No value (optional mapping)", systemImage: "minus.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .error(let message):
            Label(
                message,
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(.red)
        }
    }

    private var preview: Preview {
        guard let sourceResponse else {
            return .unavailable
        }
        do {
            if let value = try ChainValueExtractor().singleValue(
                from: mapping.source,
                response: sourceResponse,
                optional: mapping.isOptional
            ) {
                return .value(value)
            } else {
                return .noValue
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
}

private struct ChainValueSourceEditor: View {
    @Binding var source: ChainValueSource
    var allowsStatus = true
    var jsonPathSuggestions: [JSONPathSuggestion] = []

    private enum SourceKind: String, CaseIterable {
        case status = "HTTP Status"
        case header = "Response Header"
        case jsonPath = "JSONPath"
        case xpath = "XPath"
    }

    private var kind: Binding<SourceKind> {
        Binding(
            get: {
                switch source {
                case .status: .status
                case .header: .header
                case .jsonPath: .jsonPath
                case .xpath: .xpath
                }
            },
            set: {
                switch $0 {
                case .status: source = .status
                case .header: source = .header("Content-Type")
                case .jsonPath: source = .jsonPath("$.value")
                case .xpath: source = .xpath("//value")
                }
            }
        )
    }

    private var selector: Binding<String> {
        Binding(
            get: {
                switch source {
                case .status: ""
                case .header(let value), .jsonPath(let value), .xpath(let value):
                    value
                }
            },
            set: {
                switch source {
                case .status:
                    break
                case .header:
                    source = .header($0)
                case .jsonPath:
                    source = .jsonPath($0)
                case .xpath:
                    source = .xpath($0)
                }
            }
        )
    }

    var body: some View {
        Picker("Source", selection: kind) {
            ForEach(SourceKind.allCases.filter { allowsStatus || $0 != .status }, id: \.self) {
                Text($0.rawValue).tag($0)
            }
        }
        if kind.wrappedValue != .status {
            if kind.wrappedValue == .jsonPath {
                SelectorComboField(
                    text: selector,
                    suggestions: jsonPathSuggestions
                )
            } else {
                TextField("Selector", text: selector)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

private struct SelectorComboField: View {
    @Binding var text: String
    let suggestions: [JSONPathSuggestion]

    var body: some View {
        HStack(spacing: 0) {
            TextField("Selector", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)

            Divider()
                .frame(height: 20)

            Menu {
                if suggestions.isEmpty {
                    Text("Run the source request to discover fields")
                } else {
                    ForEach(suggestions) { suggestion in
                        Button {
                            text = suggestion.path
                        } label: {
                            VStack(alignment: .leading) {
                                Text(suggestion.path)
                                Text(suggestion.sample)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.35))
        )
    }
}

private extension ChainExecutionStatus {
    var systemImage: String {
        switch self {
        case .waiting: "clock"
        case .running: "progress.indicator"
        case .succeeded: "checkmark.circle.fill"
        case .failed: "xmark.octagon.fill"
        case .skipped: "forward.fill"
        case .cancelled: "stop.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .waiting, .skipped: .secondary
        case .running: .blue
        case .succeeded: .green
        case .failed: .red
        case .cancelled: .orange
        }
    }
}
