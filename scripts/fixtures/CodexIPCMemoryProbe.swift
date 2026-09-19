import Darwin
import Foundation

/// Uses the production client's public socket API without inspecting its buffer.
/// Replaying 256 MiB must not retain the consumed stream. The 96 MiB ceiling
/// leaves ample room for runtime overhead and one 64 KiB frame. Large-history
/// mode includes a ~19 MiB peer-owned frame and the client's JSON scanning map;
/// its separate 192 MiB ceiling bounds peaks, and a CPU budget catches parsing
/// the entire history twice (about 2.2 CPU seconds versus 0.4 for projection).
@main
enum CodexIPCMemoryProbe {
    static func main() throws {
        let path = CommandLine.arguments[1]
        let historyMode = CommandLine.arguments.contains("--history")
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

        let started = Date()
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
                let message: Data
                if historyMode {
                    // Build wire bytes directly so the peer does not allocate the
                    // object graph whose cost we are measuring in the client.
                    let output = String(repeating: "tool output and conversation text ", count: 25)
                    let item = #"{"role":"assistant","content":[{"type":"text","text":""# + output + #""}],"metadata":{"status":"completed","sequence":1}}"#
                    let history = Array(repeating: item, count: 20_000).joined(separator: ",")
                    message = Data((#"{"type":"broadcast","method":"thread-stream-state-changed","version":11,"sourceClientId":"owner","params":{"hostId":"local","conversationId":"large-history","change":{"type":"snapshot","revision":1,"conversationState":{"requests":[],"turns":["# + history + "]}}}}").utf8)
                } else {
                    message = try JSONSerialization.data(withJSONObject: [
                        "type": "memory-probe-padding", "padding": String(repeating: "x", count: 64 * 1024)
                    ])
                }
                let frame = framed(message)
                for _ in 0..<(historyMode ? 8 : 4096) { try writeAll(frame, to: fd) }
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
        client.sync(sessionIDs: ["memory-probe", "large-history"])
        guard processed.wait(timeout: .now() + 30) == .success else {
            print("IPC memory probe timed out before processing the stream")
            exit(1)
        }
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { throw POSIXError(.EIO) }
        let cpuSeconds = Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec) + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
        print(String(format: "CPU %.2fs; wall %.2fs", cpuSeconds, Date().timeIntervalSince(started)))
        let peakMiB = Double(usage.ru_maxrss) / 1024 / 1024
        let memoryLimit = historyMode ? 192 : 96
        print(String(format: "IPC memory probe (\(historyMode ? "large history" : "256 MiB stream")): peak RSS %.1f MiB (limit \(memoryLimit) MiB)", peakMiB))
        guard usage.ru_maxrss < memoryLimit * 1024 * 1024 else { exit(1) }
        if historyMode, cpuSeconds >= 1.5 {
            print("Large-history CPU budget exceeded (limit 1.5 seconds)")
            exit(1)
        }
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
