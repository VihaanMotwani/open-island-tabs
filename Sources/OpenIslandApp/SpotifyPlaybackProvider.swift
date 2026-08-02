import AppKit
import Foundation

enum MediaAvailability: Equatable, Sendable {
    case notRunning
    case running
}

enum MediaPlaybackState: Equatable, Sendable {
    case stopped
    case paused
    case playing
}

struct MediaPlaybackSnapshot: Equatable, Sendable {
    var availability: MediaAvailability
    var playbackState: MediaPlaybackState
    var title: String
    var artist: String
    var album: String
    var artworkURL: URL?
    var duration: TimeInterval
    var position: TimeInterval
    var volume: Double

    static let notRunning = MediaPlaybackSnapshot(
        availability: .notRunning,
        playbackState: .stopped,
        title: "",
        artist: "",
        album: "",
        artworkURL: nil,
        duration: 0,
        position: 0,
        volume: 0
    )
}

enum MediaPlaybackCommand: Equatable, Sendable {
    case open
    case togglePlayPause
    case previous
    case next
    case seek(to: TimeInterval)
    case setVolume(Double)
}

protocol MediaPlaybackProviding: Sendable {
    func fetchSnapshot() async -> MediaPlaybackSnapshot
    func perform(_ command: MediaPlaybackCommand) async
}

protocol SpotifyScriptExecuting: Sendable {
    func execute(_ source: String) async throws -> [String]
}

struct SpotifyPlaybackProvider: MediaPlaybackProviding {
    private let executor: any SpotifyScriptExecuting

    init(executor: any SpotifyScriptExecuting = SystemSpotifyScriptExecutor()) {
        self.executor = executor
    }

    func fetchSnapshot() async -> MediaPlaybackSnapshot {
        do {
            return Self.snapshot(from: try await executor.execute(Self.snapshotScript))
        } catch {
            return .notRunning
        }
    }

    func perform(_ command: MediaPlaybackCommand) async {
        let script: String
        switch command {
        case .open:
            script = #"tell application "Spotify" to activate"#
        case .togglePlayPause:
            script = #"tell application "Spotify" to playpause"#
        case .previous:
            script = #"tell application "Spotify" to previous track"#
        case .next:
            script = #"tell application "Spotify" to next track"#
        case let .seek(position):
            let clampedPosition = max(position, 0)
            script = #"tell application "Spotify" to set player position to \#(clampedPosition)"#
        case let .setVolume(volume):
            let percent = Int((min(max(volume, 0), 1) * 100).rounded())
            script = #"tell application "Spotify" to set sound volume to \#(percent)"#
        }

        _ = try? await executor.execute(script)
    }

    private static func snapshot(from fields: [String]) -> MediaPlaybackSnapshot {
        guard fields.first == "running", fields.count >= 9 else {
            return .notRunning
        }

        let playbackState: MediaPlaybackState = switch fields[1].lowercased() {
        case "playing": .playing
        case "paused": .paused
        default: .stopped
        }
        let durationMilliseconds = Double(fields[6]) ?? 0
        let position = Double(fields[7]) ?? 0
        let volumePercent = Double(fields[8]) ?? 0

        return MediaPlaybackSnapshot(
            availability: .running,
            playbackState: playbackState,
            title: fields[2],
            artist: fields[3],
            album: fields[4],
            artworkURL: URL(string: fields[5]),
            duration: max(durationMilliseconds / 1_000, 0),
            position: max(position, 0),
            volume: min(max(volumePercent / 100, 0), 1)
        )
    }

    private static let snapshotScript = """
    if application "Spotify" is not running then
        return {"notRunning"}
    end if

    tell application "Spotify"
        try
            set playbackState to player state as text
            set trackInfo to current track
            return {¬
                "running", ¬
                playbackState, ¬
                name of trackInfo, ¬
                artist of trackInfo, ¬
                album of trackInfo, ¬
                artwork url of trackInfo, ¬
                duration of trackInfo as text, ¬
                player position as text, ¬
                sound volume as text ¬
            }
        on error
            return {"running", "stopped", "", "", "", "", "0", "0", sound volume as text}
        end try
    end tell
    """
}

struct SystemSpotifyScriptExecutor: SpotifyScriptExecuting {
    func execute(_ source: String) async throws -> [String] {
        try await Task.detached(priority: .utility) {
            guard let script = NSAppleScript(source: source) else {
                throw SpotifyScriptError.compilationFailed
            }

            var errorInfo: NSDictionary?
            let result = script.executeAndReturnError(&errorInfo)
            if let errorInfo {
                let message = errorInfo[NSAppleScript.errorMessage] as? String
                    ?? "Spotify rejected the AppleScript command."
                throw SpotifyScriptError.executionFailed(message)
            }

            guard result.numberOfItems > 0 else {
                return []
            }

            return (1...result.numberOfItems).map {
                result.atIndex($0)?.stringValue ?? ""
            }
        }.value
    }
}

private enum SpotifyScriptError: LocalizedError {
    case compilationFailed
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .compilationFailed:
            "Could not compile the Spotify AppleScript."
        case let .executionFailed(message):
            message
        }
    }
}
