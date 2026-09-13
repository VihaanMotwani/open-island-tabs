import Foundation

public struct CodexDesktopAttentionUpdate: Sendable, Equatable {
    public var sessionID: String
    public var pendingRequestIDs: Set<String>
}

/// Read-only projection of the versioned Desktop window-to-window stream.
/// Retains pending requests only; conversation history is discarded.
public struct CodexDesktopRequestStream {
    private struct State {
        var owner: String
        var revision: Int
        var requests: [[String: Any]]
    }
    private var states: [String: State] = [:]
    public private(set) var needsSnapshot: Set<String> = []

    public init() {}

    public mutating func reset() {
        states.removeAll()
        needsSnapshot.removeAll()
    }

    public mutating func receive(_ data: Data) -> CodexDesktopAttentionUpdate? {
        guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              message["type"] as? String == "broadcast",
              message["method"] as? String == "thread-stream-state-changed",
              let params = message["params"] as? [String: Any],
              params["hostId"] as? String == "local",
              let id = params["conversationId"] as? String,
              let owner = message["sourceClientId"] as? String else { return nil }
        guard message["version"] as? Int == 11,
              let change = params["change"] as? [String: Any],
              let revision = change["revision"] as? Int else { return nil }

        let previous = states[id]
        var next: State
        if change["type"] as? String == "snapshot" {
            guard let conversation = change["conversationState"] as? [String: Any],
                  let requests = conversation["requests"] as? [[String: Any]] else { return nil }
            if let previous, previous.owner == owner, revision < previous.revision { return nil }
            next = State(owner: owner, revision: revision, requests: requests)
            needsSnapshot.remove(id)
        } else if change["type"] as? String == "patches" {
            guard var current = previous, current.owner == owner,
                  change["baseRevision"] as? Int == current.revision,
                  revision > current.revision,
                  let patches = change["patches"] as? [[String: Any]] else {
                needsSnapshot.insert(id)
                return nil
            }
            do {
                var requests: Any = current.requests
                for patch in patches {
                    guard let path = patch["path"] as? [Any] else { throw PatchError.invalid }
                    guard path.first as? String == "requests" else { continue }
                    requests = try Self.patch(requests, path: Array(path.dropFirst()), operation: patch)
                }
                guard let updated = requests as? [[String: Any]] else { throw PatchError.invalid }
                current.requests = updated
                current.revision = revision
                next = current
            } catch {
                needsSnapshot.insert(id)
                return nil
            }
        } else { return nil }
        states[id] = next
        let result = Self.pendingIDs(next.requests, sessionID: id)
        guard previous == nil || result != Self.pendingIDs(previous!.requests, sessionID: id) else { return nil }
        return CodexDesktopAttentionUpdate(sessionID: id, pendingRequestIDs: result)
    }

    private static func pendingIDs(_ requests: [[String: Any]], sessionID: String) -> Set<String> {
        let methods: Set<String> = [
            "item/commandExecution/requestApproval", "item/fileChange/requestApproval",
            "item/permissions/requestApproval", "mcpServer/elicitation/request",
        ]
        return Set(requests.compactMap { request in
            guard let method = request["method"] as? String, methods.contains(method),
                  let params = request["params"] as? [String: Any],
                  params["threadId"] as? String == sessionID else { return nil }
            if let id = request["id"] as? String { return "string:\(id)" }
            if let id = request["id"] as? Int { return "number:\(id)" }
            return nil
        })
    }

    private enum PatchError: Error { case invalid }

    private static func patch(_ value: Any, path: [Any], operation: [String: Any]) throws -> Any {
        guard let op = operation["op"] as? String, ["add", "replace", "remove"].contains(op) else {
            throw PatchError.invalid
        }
        guard let key = path.first else {
            guard op != "remove", let replacement = operation["value"] else { throw PatchError.invalid }
            return replacement
        }
        if var array = value as? [Any], let index = key as? Int {
            if path.count == 1 {
                if op == "add", index >= 0, index <= array.count, let replacement = operation["value"] {
                    array.insert(replacement, at: index)
                } else if array.indices.contains(index) {
                    if op == "remove" { array.remove(at: index) }
                    else if let replacement = operation["value"] { array[index] = replacement }
                    else { throw PatchError.invalid }
                } else { throw PatchError.invalid }
            } else {
                guard array.indices.contains(index) else { throw PatchError.invalid }
                array[index] = try patch(array[index], path: Array(path.dropFirst()), operation: operation)
            }
            return array
        }
        if var object = value as? [String: Any], let key = key as? String {
            if path.count == 1 {
                if op == "remove" { object.removeValue(forKey: key) }
                else if let replacement = operation["value"] { object[key] = replacement }
                else { throw PatchError.invalid }
            } else {
                guard let child = object[key] else { throw PatchError.invalid }
                object[key] = try patch(child, path: Array(path.dropFirst()), operation: operation)
            }
            return object
        }
        throw PatchError.invalid
    }
}
