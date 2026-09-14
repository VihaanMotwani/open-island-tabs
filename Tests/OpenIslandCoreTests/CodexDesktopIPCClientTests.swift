import Darwin
import Foundation
import Testing
@testable import OpenIslandCore

struct CodexDesktopIPCClientTests {
    @Test(arguments: [CodexDesktopAppDecision.deny, .allowOnce, .allowForSession, .allowAlways])
    func sendsExactDecisionToOwningCodexWindow(decision: CodexDesktopAppDecision) async throws {
        let payload = try await exchange(decision: decision, scopes: ["session", "always"])
        #expect(payload["method"] as? String == "thread-follower-submit-mcp-server-elicitation-response")
        #expect(payload["version"] as? Int == 1)
        #expect(payload["targetClientId"] as? String == "owner")
        #expect(payload["sourceClientId"] as? String == "island")
        let params = try #require(payload["params"] as? [String: Any])
        #expect(params["conversationId"] as? String == "desktop-human")
        #expect(params["requestId"] as? Int == 75)
        let response = try #require(params["response"] as? [String: Any])
        let metadata = response["_meta"] as? [String: String]
        switch decision {
        case .deny:
            #expect(response["action"] as? String == "decline")
            #expect(response["content"] is NSNull)
            #expect(response["_meta"] is NSNull)
        case .allowOnce:
            #expect(response["action"] as? String == "accept")
            #expect((response["content"] as? [String: String]) == [:])
            #expect(response["_meta"] is NSNull)
        case .allowForSession:
            #expect(response["action"] as? String == "accept")
            #expect((response["content"] as? [String: String]) == [:])
            #expect(metadata == ["persist": "session"])
        case .allowAlways:
            #expect(response["action"] as? String == "accept")
            #expect((response["content"] as? [String: String]) == [:])
            #expect(metadata == ["persist": "always"])
        }
    }

    @Test
    func refusesUnadvertisedScopeBeforeSendingAnything() async throws {
        let payload = try await exchange(decision: .allowOnce, scopes: [], attemptUnsupported: true)
        let params = try #require(payload["params"] as? [String: Any])
        let response = try #require(params["response"] as? [String: Any])
        #expect(response["_meta"] is NSNull)
    }

    @Test(arguments: [1, 2, 3, 4, 64 * 1024])
    func preservesApprovalWhenFramesAreSplitAndCoalesced(split: Int) async throws {
        let payload = try await exchange(decision: .allowAlways, scopes: ["always"], frameSplit: split)
        #expect(payload["targetClientId"] as? String == "owner")
        let params = try #require(payload["params"] as? [String: Any])
        #expect(params["requestId"] as? Int == 75)
        let response = try #require(params["response"] as? [String: Any])
        #expect(response["_meta"] as? [String: String] == ["persist": "always"])
    }

    @Test(arguments: ["always", "session", "unknown"])
    func acceptsKnownSingleScopeAndRejectsUnknownScope(scope: String) throws {
        var stream = CodexDesktopRequestStream()
        let received = stream.receive(try Self.snapshot(scopes: scope))
        let update = try #require(received)
        let approval = try #require(update.appApproval)
        #expect(approval.supports(.allowAlways) == (scope == "always"))
        #expect(approval.supports(.allowForSession) == (scope == "session"))
    }

    private func exchange(
        decision: CodexDesktopAppDecision, scopes: [String], attemptUnsupported: Bool = false,
        frameSplit: Int? = nil
    ) async throws -> [String: Any] {
        let peer = try DesktopPeer()
        defer { peer.close() }
        let (updates, continuation) = AsyncThrowingStream<CodexDesktopAttentionUpdate, Error>.makeStream()
        let snapshot = try Self.snapshot(scopes: scopes, padding: frameSplit == nil ? 0 : 192 * 1024)
        let received = Task.detached {
            do { return try await peer.exchange(snapshot: snapshot, frameSplit: frameSplit) }
            catch { continuation.finish(throwing: error); throw error }
        }
        let client = CodexDesktopIPCClient(socketPath: peer.path) { continuation.yield($0) }
        client.sync(sessionIDs: ["desktop-human"])
        defer { client.sync(sessionIDs: []); continuation.finish() }
        var iterator = updates.makeAsyncIterator()
        let update = try #require(try await iterator.next())
        let approval = try #require(update.appApproval)
        // Matching ID alone is insufficient: a changed displayed prompt is stale.
        var stale = approval
        stale.appIdentifier = "different.app"
        #expect(await client.respond(to: stale, decision: decision) == false)
        if attemptUnsupported {
            #expect(await client.respond(to: approval, decision: .allowAlways) == false)
            #expect(await client.respond(to: approval, decision: .allowForSession) == false)
        }
        #expect(await client.respond(to: approval, decision: decision))
        return try #require(JSONSerialization.jsonObject(with: try await received.value) as? [String: Any])
    }

    private static func snapshot(scopes: Any, padding: Int = 0) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "padding": String(repeating: "x", count: padding),
            "type": "broadcast", "method": "thread-stream-state-changed", "version": 11,
            "sourceClientId": "owner", "params": ["hostId": "local", "conversationId": "desktop-human",
                "change": ["type": "snapshot", "revision": 1, "conversationState": ["requests": [[
                    "id": 75, "method": "mcpServer/elicitation/request", "params": [
                        "threadId": "desktop-human", "mode": "form", "message": "Allow Calculator?",
                        "requestedSchema": ["type": "object", "properties": [:]],
                        "_meta": ["codex_approval_kind": "mcp_tool_call", "connector_id": "computer-use",
                            "tool_name": "get_app_state", "tool_params": ["app": "com.apple.calculator"],
                            "persist": scopes]
                    ]
                ]]]]]
        ])
    }
}

/// A bounded, same-user Unix socket peer exercising the actual framing and client API.
private final class DesktopPeer: @unchecked Sendable {
    let path: String
    private let directory: URL
    private let listener: Int32

    init() throws {
        directory = URL(fileURLWithPath: "/tmp/oi-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        path = directory.appendingPathComponent("ipc.sock").path
        listener = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard listener >= 0 else { throw POSIXError(.EIO) }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: Array(path.utf8) + [0]) }
        let result = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(listener, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard result == 0, Darwin.listen(listener, 1) == 0 else { close(); throw POSIXError(.EIO) }
    }

    func close() {
        Darwin.close(listener)
        try? FileManager.default.removeItem(at: directory)
    }

    func exchange(snapshot: Data, frameSplit: Int? = nil) async throws -> Data {
        // Blocking poll/read calls must not occupy the cooperative executor:
        // concurrent peers would prevent the client's async decisions running.
        try await withCheckedThrowingContinuation { result in
            DispatchQueue.global().async {
                result.resume(with: Result { try self.exchangeBlocking(snapshot: snapshot, frameSplit: frameSplit) })
            }
        }
    }

    private func exchangeBlocking(snapshot: Data, frameSplit: Int?) throws -> Data {
        try readable(listener)
        let fd = Darwin.accept(listener, nil, nil)
        guard fd >= 0 else { throw POSIXError(.EIO) }
        defer { Darwin.close(fd) }
        var noSignal: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
        let initialize = try object(readFrame(fd))
        try send(fd, JSONSerialization.data(withJSONObject: [
            "type": "response", "method": "initialize", "requestId": initialize["requestId"]!,
            "resultType": "success", "result": ["clientId": "island"]
        ]))
        for _ in 0..<8 {
            let data = try readFrame(fd)
            let request = try object(data)
            if request["method"] as? String == "thread-stream-following-changed" {
                if let frameSplit {
                    // A complete frame precedes a split header/body; another
                    // follows it. The large snapshot also forces multiple
                    // 64 KiB reads even if the socket coalesces our writes.
                    let noop = framed(Data(#"{"type":"test-noop"}"#.utf8))
                    var batch = noop
                    batch.append(framed(snapshot))
                    batch.append(noop)
                    let split = noop.count + frameSplit
                    try write(fd, Data(batch.prefix(split)))
                    try write(fd, Data(batch.dropFirst(split)))
                } else {
                    try send(fd, snapshot)
                }
                continue
            }
            try send(fd, JSONSerialization.data(withJSONObject: [
                "type": "response", "requestId": request["requestId"]!,
                "resultType": "success", "result": ["ok": true]
            ]))
            return data
        }
        throw POSIXError(.ETIMEDOUT)
    }

    private func object(_ data: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func readable(_ fd: Int32) throws {
        var descriptor = pollfd(fd: fd, events: Int16(POLLIN), revents: 0)
        guard poll(&descriptor, 1, 5000) > 0 else { throw POSIXError(.ETIMEDOUT) }
    }

    private func read(_ fd: Int32, count: Int) throws -> Data {
        var result = Data()
        while result.count < count {
            try readable(fd)
            var bytes = [UInt8](repeating: 0, count: count - result.count)
            let n = Darwin.read(fd, &bytes, bytes.count)
            guard n > 0 else { throw POSIXError(.EIO) }
            result.append(contentsOf: bytes.prefix(n))
        }
        return result
    }

    private func readFrame(_ fd: Int32) throws -> Data {
        let header = try read(fd, count: 4)
        let count = header.enumerated().reduce(0) { $0 | Int($1.element) << ($1.offset * 8) }
        guard count > 0, count < 1_000_000 else { throw POSIXError(.EINVAL) }
        return try read(fd, count: count)
    }

    private func send(_ fd: Int32, _ data: Data) throws {
        try write(fd, framed(data))
    }

    private func framed(_ data: Data) -> Data {
        var length = UInt32(data.count).littleEndian
        var frame = withUnsafeBytes(of: &length) { Data($0) }
        frame.append(data)
        return frame
    }

    private func write(_ fd: Int32, _ data: Data) throws {
        try data.withUnsafeBytes { bytes in
            var sent = 0
            while sent < bytes.count {
                let n = Darwin.write(fd, bytes.baseAddress!.advanced(by: sent), bytes.count - sent)
                guard n > 0 else { throw POSIXError(.EIO) }
                sent += n
            }
        }
    }
}
