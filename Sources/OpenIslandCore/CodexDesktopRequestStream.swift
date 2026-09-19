import Foundation

public struct CodexDesktopAttentionUpdate: Sendable, Equatable {
    public var sessionID: String
    public var pendingRequestIDs: Set<String>
    public var appApproval: CodexDesktopAppApproval?
}

public enum CodexDesktopApprovalPersistence: String, Codable, Sendable, CaseIterable {
    case session
    case always
}

public enum CodexDesktopAppDecision: Sendable, Equatable {
    case deny
    case allowOnce
    case allowForSession
    case allowAlways

    var persistence: CodexDesktopApprovalPersistence? {
        switch self {
        case .deny, .allowOnce: nil
        case .allowForSession: .session
        case .allowAlways: .always
        }
    }
}

/// Only plain Computer Use app-access prompts have direct Island actions.
/// Other forms and execution-bound approvals remain in Codex.
public struct CodexDesktopAppApproval: Sendable, Equatable {
    public var sessionID: String
    public var ownerClientID: String
    public var requestKey: String
    public var message: String
    public var appIdentifier: String
    public var persistenceOptions: Set<CodexDesktopApprovalPersistence> = []

    public func supports(_ decision: CodexDesktopAppDecision) -> Bool {
        decision.persistence.map { persistenceOptions.contains($0) } ?? true
    }

    var wireRequestID: Any {
        if requestKey.hasPrefix("number:"), let number = Int(requestKey.dropFirst(7)) { return number }
        return String(requestKey.dropFirst(7))
    }
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
        guard let message = try? CodexDesktopMessage.decode(data) else { return nil }
        return receive(message)
    }

    mutating func receive(_ message: [String: Any]) -> CodexDesktopAttentionUpdate? {
        guard message["type"] as? String == "broadcast",
              message["method"] as? String == "thread-stream-state-changed",
              let params = message["params"] as? [String: Any],
              params["hostId"] as? String == "local",
              let id = params["conversationId"] as? String,
              let owner = message["sourceClientId"] as? String else { return nil }
        guard message["version"] as? Int == 11 else {
            needsSnapshot.insert(id)
            return nil
        }
        guard let change = params["change"] as? [String: Any],
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
        let approval = currentAppApproval(sessionID: id)
        let previousApproval = previous.flatMap { Self.appApproval($0, sessionID: id) }
        guard previous == nil || result != Self.pendingIDs(previous!.requests, sessionID: id)
                || approval != previousApproval else { return nil }
        return CodexDesktopAttentionUpdate(sessionID: id, pendingRequestIDs: result, appApproval: approval)
    }

    public func currentAppApproval(sessionID: String) -> CodexDesktopAppApproval? {
        states[sessionID].flatMap { Self.appApproval($0, sessionID: sessionID) }
    }

    private static func appApproval(_ state: State, sessionID: String) -> CodexDesktopAppApproval? {
        for request in state.requests {
            guard request["method"] as? String == "mcpServer/elicitation/request",
                  let params = request["params"] as? [String: Any],
                  params["threadId"] as? String == sessionID,
                  params["mode"] as? String == "form",
                  let schema = params["requestedSchema"] as? [String: Any],
                  schema["type"] as? String == "object",
                  let properties = schema["properties"] as? [String: Any], properties.isEmpty,
                  (schema["required"] as? [String] ?? []).isEmpty,
                  let meta = params["_meta"] as? [String: Any],
                  meta["codex_approval_kind"] as? String == "mcp_tool_call",
                  meta["connector_id"] as? String == "computer-use",
                  meta["tool_name"] as? String == "get_app_state",
                  let toolParams = meta["tool_params"] as? [String: Any], toolParams.count == 1,
                  let app = toolParams["app"] as? String, !app.isEmpty,
                  let message = params["message"] as? String, !message.isEmpty, message.count <= 500 else { continue }
            let key: String
            if let id = request["id"] as? String { key = "string:\(id)" }
            else if let id = request["id"] as? Int { key = "number:\(id)" }
            else { continue }
            return CodexDesktopAppApproval(sessionID: sessionID, ownerClientID: state.owner,
                requestKey: key, message: message, appIdentifier: app,
                persistenceOptions: persistenceOptions(meta["persist"]))
        }
        return nil
    }

    private static func persistenceOptions(_ value: Any?) -> Set<CodexDesktopApprovalPersistence> {
        let values: [String]
        if let single = value as? String { values = [single] }
        else if let multiple = value as? [String] { values = multiple }
        else { return [] }
        let options = values.compactMap(CodexDesktopApprovalPersistence.init(rawValue:))
        // Unknown metadata must never broaden the actions offered by the owner.
        guard options.count == values.count else { return [] }
        return Set(options)
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


/// Decode the approval projection without materializing conversation history.
/// JSONDecoder still validates/skips the wire JSON, but turns, tool output and
/// unrelated patch values never become Foundation dictionaries or strings.
enum CodexDesktopMessage {
    static func decode(_ data: Data) throws -> [String: Any] {
        try JSONDecoder().decode(Projection.self, from: data).object
    }

    private struct Key: CodingKey {
        let stringValue: String
        let intValue: Int? = nil
        init(_ value: String) { stringValue = value }
        init?(stringValue: String) { self.init(stringValue) }
        init?(intValue: Int) { return nil }
    }

    private struct Projection: Decodable {
        let object: [String: Any]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            let fields: [String]
            switch decoder.codingPath.map(\.stringValue) {
            case []:
                fields = ["type", "method", "version", "requestId", "sourceClientId", "resultType", "result", "params"]
            case ["params"]:
                fields = ["hostId", "conversationId", "change"]
            case ["params", "change"]:
                fields = ["type", "revision", "baseRevision", "conversationState", "patches"]
            case ["params", "change", "conversationState"]:
                fields = ["requests"]
            case ["result"]:
                fields = ["clientId", "ok"]
            default:
                fields = []
            }
            var result: [String: Any] = [:]
            for name in fields {
                let key = Key(name)
                guard container.contains(key) else { continue }
                if ["params", "change", "conversationState", "result"].contains(name) {
                    // Preserve invalid/missing object shapes as invalid state;
                    // never fabricate an empty requests snapshot from them.
                    if let nested = try? container.decode(Projection.self, forKey: key) {
                        result[name] = nested.object
                    }
                } else if name == "patches" {
                    if let patches = try? container.decode([Patch].self, forKey: key) {
                        result[name] = patches.map(\.object)
                    }
                } else {
                    result[name] = try container.decode(Value.self, forKey: key).value
                }
            }
            object = result
        }
    }

    private struct Patch: Decodable {
        let object: [String: Any]
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Key.self)
            var result: [String: Any] = [:]
            if let path = try container.decodeIfPresent(Value.self, forKey: Key("path"))?.value {
                result["path"] = path
            }
            if (result["path"] as? [Any])?.first as? String == "requests" {
                for name in ["op", "value"] where container.contains(Key(name)) {
                    result[name] = try container.decode(Value.self, forKey: Key(name)).value
                }
            }
            object = result
        }
    }

    /// Only approval payloads need heterogeneous values, including null and
    /// numeric request IDs. Leave their existing protocol validation unchanged.
    private struct Value: Decodable {
        let value: Any
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() { value = NSNull() }
            else if let bool = try? container.decode(Bool.self) { value = bool }
            else if let int = try? container.decode(Int.self) { value = int }
            else if let number = try? container.decode(Double.self) { value = number }
            else if let string = try? container.decode(String.self) { value = string }
            else if let array = try? container.decode([Value].self) { value = array.map(\.value) }
            else { value = try container.decode([String: Value].self).mapValues(\.value) }
        }
    }
}
