import Foundation
import SwiftUI

struct RequestHistoryEntry: Codable, Identifiable {
    let id: UUID
    let sentAt: Date
    let method: HTTPMethod
    let url: String
    let requestData: Data

    var menuTitle: String {
        let title = "\(method.description) \(url)"
        guard title.count > 30 else { return title }
        return String(title.prefix(29)) + "…"
    }

    func restoredRequest() -> HTTPRequest? {
        guard let request = try? JSONDecoder().decode(
            HTTPRequest.self,
            from: requestData
        ) else {
            return nil
        }
        // A restored history item is a new document request. Reusing its old ID
        // would create duplicate SwiftUI identities and ambiguous chain lookups.
        request.id = UUID()
        return request
    }
}

@MainActor
final class RequestHistoryStore: ObservableObject {
    @Published private(set) var entries: [RequestHistoryEntry] = []

    private let defaults: UserDefaults
    private let storageKey = "requestHistory"
    private let maximumEntryCount = 20

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func record(_ request: HTTPRequest) {
        guard request.request != nil,
              let requestData = try? JSONEncoder().encode(request) else {
            return
        }

        let entry = RequestHistoryEntry(
            id: UUID(),
            sentAt: Date(),
            method: request.method,
            url: request.url?.absoluteString ?? "",
            requestData: requestData
        )

        entries.insert(entry, at: 0)
        entries = Array(entries.prefix(maximumEntryCount))
        save()
    }

    func clear() {
        entries.removeAll()
        defaults.removeObject(forKey: storageKey)
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let savedEntries = try? JSONDecoder().decode(
                [RequestHistoryEntry].self,
                from: data
              ) else {
            return
        }

        entries = Array(savedEntries.prefix(maximumEntryCount))
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

private struct RestoreHistoryRequestKey: FocusedValueKey {
    typealias Value = (RequestHistoryEntry) -> Void
}

extension FocusedValues {
    var restoreHistoryRequest: ((RequestHistoryEntry) -> Void)? {
        get { self[RestoreHistoryRequestKey.self] }
        set { self[RestoreHistoryRequestKey.self] = newValue }
    }
}

struct RequestHistoryCommands: Commands {
    @ObservedObject var historyStore: RequestHistoryStore
    @FocusedValue(\.restoreHistoryRequest) private var restoreRequest

    var body: some Commands {
        CommandMenu("History") {
            if historyStore.entries.isEmpty {
                Text("No Recent Requests")
            } else {
                ForEach(historyStore.entries.prefix(10)) { entry in
                    Button(entry.menuTitle) {
                        restoreRequest?(entry)
                    }
                    .disabled(restoreRequest == nil)
                }

                Divider()

                Button("Clear History", role: .destructive) {
                    historyStore.clear()
                }
            }
        }
    }
}
