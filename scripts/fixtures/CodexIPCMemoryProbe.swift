import Darwin
import Foundation

/// Uses the production client's public socket API without inspecting its buffer.
/// Replaying 256 MiB must not retain the consumed stream. The 96 MiB ceiling
/// leaves ample room for runtime overhead and one 64 KiB frame.
@main
enum CodexIPCMemoryProbe {
    static func main() throws {
        let path = CommandLine.arguments[1]
        let listener = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard listener >= 0 else { throw POSIXError(.EIO) }
        defer { Darwin.close(listener) }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) {
            $0.copyBytes(from: Array(path.utf8) + [0])
        }
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(listener, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bound == 0, Darwin.listen(listener, 1) == 0 else { throw POSIXError(.EIO) }

        let processed = DispatchSemaphore(value: 0)
        let releasePeer = DispatchSemaphore(value: 0)
        let client = CodexDesktopIPCClient(socketPath: path) { update in
            if update.sessionID == "memory-probe", update.pendingRequestIDs.isEmpty {
                processed.signal()
            }
        }
        defer { client.sync(sessionIDs: []); releasePeer.signal() }
        DispatchQueue.global().async {
            do {
                let fd = Darwin.accept(listener, nil, nil)
                guard fd >= 0 else { throw POSIXError(.EIO) }
                defer { Darwin.close(fd) }
                var noSignal: Int32 = 1
                setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
                let message = try JSONSerialization.data(withJSONObject: [
                    "type": "memory-probe-padding", "padding": String(repeating: "x", count: 64 * 1024)
                ])
                let frame = framed(message)
                for _ in 0..<4096 { try writeAll(frame, to: fd) }
                // The update callback proves the client processed the entire
                // preceding stream. Keep the connection open until measured:
                // disconnecting would hide retained memory by resetting it.
                let marker = try JSONSerialization.data(withJSONObject: [
                    "type": "broadcast", "method": "thread-stream-state-changed", "version": 11,
                    "sourceClientId": "probe-owner",
                    "params": ["hostId": "local", "conversationId": "memory-probe",
                        "change": ["type": "snapshot", "revision": 1,
                            "conversationState": ["requests": []]]]
                ])
                try writeAll(framed(marker), to: fd)
                _ = releasePeer.wait(timeout: .now() + 30)
            } catch {
                print("IPC memory probe peer failed: \(error)")
                exit(1)
            }
        }
        client.sync(sessionIDs: ["memory-probe"])
        guard processed.wait(timeout: .now() + 30) == .success else {
            print("IPC memory probe timed out before processing the stream")
            exit(1)
        }
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { throw POSIXError(.EIO) }
        let peakMiB = Double(usage.ru_maxrss) / 1024 / 1024
        print(String(format: "IPC memory probe: processed 256 MiB; peak RSS %.1f MiB (limit 96 MiB)", peakMiB))
        guard usage.ru_maxrss < 96 * 1024 * 1024 else { exit(1) }
    }

    private static func framed(_ data: Data) -> Data {
        var length = UInt32(data.count).littleEndian
        var frame = withUnsafeBytes(of: &length) { Data($0) }
        frame.append(data)
        return frame
    }

    private static func writeAll(_ data: Data, to fd: Int32) throws {
        try data.withUnsafeBytes { bytes in
            var sent = 0
            while sent < bytes.count {
                let count = Darwin.write(fd, bytes.baseAddress!.advanced(by: sent), bytes.count - sent)
                if count < 0, errno == EINTR { continue }
                guard count > 0 else { throw POSIXError(.EIO) }
                sent += count
            }
        }
    }
}
