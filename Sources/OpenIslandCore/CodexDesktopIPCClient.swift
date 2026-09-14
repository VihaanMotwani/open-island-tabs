import Darwin
import Foundation

/// Follows Codex Desktop's same-user, versioned IPC stream without taking
/// ownership. Explicit user decisions can resolve plain app-access prompts.
public final class CodexDesktopIPCClient: @unchecked Sendable {
    private let queue = DispatchQueue(label: "open-island.codex-desktop-ipc", qos: .utility)
    private let onUpdate: @Sendable (CodexDesktopAttentionUpdate) -> Void
    private let socketPath: String
    private var desired: Set<String> = []
    private var subscribed: Set<String> = []
    private var socketFD: Int32 = -1
    private var reader: DispatchSourceRead?
    private var buffer = Data()
    private var clientID: String?
    private var stream = CodexDesktopRequestStream()
    private var pendingResponses: [String: CheckedContinuation<Bool, Never>] = [:]
    private var retryScheduled = false
    private var lastRefresh = Date.distantPast
    private let maxFrameBytes = 256 * 1024 * 1024

    public init(socketPath: String? = nil, onUpdate: @escaping @Sendable (CodexDesktopAttentionUpdate) -> Void) {
        self.socketPath = socketPath ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/ipc/ipc.sock").path
        self.onUpdate = onUpdate
    }

    public func sync(sessionIDs: Set<String>) {
        queue.async { [self] in
            desired = sessionIDs
            if desired.isEmpty { disconnect(); return }
            if socketFD < 0 { connectIfNeeded() }
            else { synchronizeSubscriptions() }
        }
    }

    public func respond(to approval: CodexDesktopAppApproval, decision: CodexDesktopAppDecision) async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                // Revalidate the exact displayed request against current owner
                // state. Never answer a cached prompt after a disconnect.
                guard let clientID, socketFD >= 0, approval.supports(decision),
                      stream.currentAppApproval(sessionID: approval.sessionID) == approval,
                      !stream.needsSnapshot.contains(approval.sessionID) else {
                    continuation.resume(returning: false)
                    return
                }
                let allow = decision != .deny
                let response: [String: Any] = [
                    "action": allow ? "accept" : "decline",
                    "content": allow ? ([:] as [String: String]) as Any : NSNull() as Any,
                    "_meta": decision.persistence.map { ["persist": $0.rawValue] } as Any? ?? NSNull()
                ]
                let id = UUID().uuidString
                pendingResponses[id] = continuation
                send(["type": "request", "method": "thread-follower-submit-mcp-server-elicitation-response",
                      "version": 1, "requestId": id, "sourceClientId": clientID,
                      "targetClientId": approval.ownerClientID,
                      "params": ["conversationId": approval.sessionID, "requestId": approval.wireRequestID,
                                 "response": response]])
                queue.asyncAfter(deadline: .now() + 10) { [weak self] in
                    self?.pendingResponses.removeValue(forKey: id)?.resume(returning: false)
                }
            }
        }
    }

    private func connectIfNeeded() {
        guard socketFD < 0, !desired.isEmpty else { return }
        var info = stat()
        let parent = URL(fileURLWithPath: socketPath).deletingLastPathComponent().path
        var directory = stat()
        guard lstat(socketPath, &info) == 0, info.st_uid == getuid(),
              info.st_mode & S_IFMT == S_IFSOCK,
              lstat(parent, &directory) == 0, directory.st_uid == getuid(),
              directory.st_mode & S_IFMT == S_IFDIR, directory.st_mode & 0o022 == 0 else {
            scheduleRetry(); return
        }
        let fd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { scheduleRetry(); return }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        let bytes = Array(socketPath.utf8) + [0]
        guard bytes.count <= MemoryLayout.size(ofValue: address.sun_path) else { Darwin.close(fd); return }
        withUnsafeMutableBytes(of: &address.sun_path) { destination in
            destination.copyBytes(from: bytes)
        }
        let connected = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard connected == 0 else { Darwin.close(fd); scheduleRetry(); return }
        var noSignal: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
        _ = fcntl(fd, F_SETFL, O_NONBLOCK)
        socketFD = fd
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in self?.readAvailable() }
        source.setCancelHandler { Darwin.close(fd) }
        reader = source
        source.resume()
        send(["type": "request", "requestId": UUID().uuidString, "method": "initialize",
              "version": 0, "params": ["clientType": "open-island-observer"]])
    }

    private func scheduleRetry() {
        guard !retryScheduled, !desired.isEmpty else { return }
        retryScheduled = true
        queue.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            self.retryScheduled = false
            self.connectIfNeeded()
        }
    }

    private func disconnect() {
        reader?.cancel()
        reader = nil
        socketFD = -1
        clientID = nil
        subscribed.removeAll()
        buffer.removeAll(keepingCapacity: false)
        stream.reset()
        for response in pendingResponses.values { response.resume(returning: false) }
        pendingResponses.removeAll()
        // A lost connection does not prove that a pending request resolved.
        // Retain attention in the app until an authoritative snapshot arrives.
    }

    private func readAvailable() {
        var bytes = [UInt8](repeating: 0, count: 64 * 1024)
        while socketFD >= 0 {
            let count = Darwin.read(socketFD, &bytes, bytes.count)
            if count < 0, errno == EAGAIN || errno == EWOULDBLOCK { return }
            if count < 0, errno == EINTR { continue }
            guard count > 0 else { disconnect(); scheduleRetry(); return }
            buffer.append(contentsOf: bytes.prefix(count))
            while buffer.count >= 4 {
                let length = buffer.prefix(4).enumerated().reduce(0) { $0 | Int($1.element) << ($1.offset * 8) }
                guard length > 0, length <= maxFrameBytes else { disconnect(); scheduleRetry(); return }
                guard buffer.count >= length + 4 else { break }
                let frame = Data(buffer.dropFirst(4).prefix(length))
                // Data.removeFirst advances the slice's start index while
                // retaining consumed bytes in its backing allocation. Compact
                // the unread tail instead, and release storage when drained.
                let consumedEnd = buffer.index(buffer.startIndex, offsetBy: length + 4)
                buffer.removeSubrange(buffer.startIndex..<consumedEnd)
                if buffer.isEmpty { buffer = Data() }
                handle(frame)
            }
        }
    }

    private func handle(_ data: Data) {
        guard let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            disconnect(); scheduleRetry(); return
        }
        if message["type"] as? String == "response", let id = message["requestId"] as? String,
           let continuation = pendingResponses.removeValue(forKey: id) {
            let result = message["result"] as? [String: Any]
            continuation.resume(returning: message["resultType"] as? String == "success" && result?["ok"] as? Bool == true)
            return
        }
        if message["type"] as? String == "response", message["method"] as? String == "initialize",
           message["resultType"] as? String == "success",
           let result = message["result"] as? [String: Any], let id = result["clientId"] as? String {
            clientID = id
            synchronizeSubscriptions()
        } else if message["type"] as? String == "client-discovery-request", let id = message["requestId"] {
            send(["type": "client-discovery-response", "requestId": id, "response": ["canHandle": false]])
        } else if message["type"] as? String == "broadcast",
                  let params = message["params"] as? [String: Any],
                  let id = params["conversationId"] as? String, desired.contains(id) {
            if message["method"] as? String == "thread-stream-following-status-requested" {
                follow(id, following: true)
            } else if let update = stream.receive(data) { onUpdate(update) }
            if message["version"] as? Int == 11, stream.needsSnapshot.contains(id) { follow(id, following: true) }
        }
    }

    private func synchronizeSubscriptions() {
        guard clientID != nil else { return }
        for id in subscribed.subtracting(desired) { follow(id, following: false) }
        for id in desired.subtracting(subscribed) { follow(id, following: true) }
        subscribed = desired
        // Recover owner changes and requests resolved during a missed interval.
        if Date.now.timeIntervalSince(lastRefresh) > 15 {
            lastRefresh = .now
            for id in desired { follow(id, following: true) }
        }
    }

    private func follow(_ id: String, following: Bool) {
        guard let clientID else { return }
        send(["type": "broadcast", "method": "thread-stream-following-changed", "version": 1,
              "sourceClientId": clientID, "params": ["hostId": "local", "conversationId": id, "following": following]])
    }

    private func send(_ message: [String: Any]) {
        guard socketFD >= 0, let payload = try? JSONSerialization.data(withJSONObject: message) else { return }
        var length = UInt32(payload.count).littleEndian
        var frame = withUnsafeBytes(of: &length) { Data($0) }
        frame.append(payload)
        let succeeded = frame.withUnsafeBytes { raw -> Bool in
            guard let base = raw.baseAddress else { return false }
            var sent = 0
            while sent < raw.count {
                let count = Darwin.write(socketFD, base.advanced(by: sent), raw.count - sent)
                if count < 0, errno == EINTR { continue }
                guard count > 0 else { return false }
                sent += count
            }
            return true
        }
        if !succeeded { disconnect(); scheduleRetry() }
    }
}
