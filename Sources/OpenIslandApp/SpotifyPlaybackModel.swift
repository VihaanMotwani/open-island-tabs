import Foundation
import Observation

enum SpotifyLaunchTrigger: Equatable, Sendable {
    case tabSelection
    case unavailableCard
    case activityIndicator
}

enum SpotifyLaunchPolicy {
    static func command(for trigger: SpotifyLaunchTrigger) -> MediaPlaybackCommand? {
        switch trigger {
        case .tabSelection:
            nil
        case .unavailableCard, .activityIndicator:
            .open
        }
    }
}

@MainActor
@Observable
final class SpotifyPlaybackModel {
    private(set) var snapshot: MediaPlaybackSnapshot = .notRunning

    @ObservationIgnored
    private let provider: any MediaPlaybackProviding

    @ObservationIgnored
    private var pollingTask: Task<Void, Never>?

    @ObservationIgnored
    private var usesDebugSnapshot = false

    init(provider: any MediaPlaybackProviding = SpotifyPlaybackProvider()) {
        self.provider = provider
    }

    func start() {
        guard pollingTask == nil, !usesDebugSnapshot else { return }

        pollingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await refresh()

                let interval: Duration = snapshot.availability == .running
                    ? .seconds(1)
                    : .seconds(4)
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() async {
        guard !usesDebugSnapshot else { return }
        snapshot = await provider.fetchSnapshot()
    }

    func applyDebugSnapshot(_ snapshot: MediaPlaybackSnapshot) {
        stop()
        usesDebugSnapshot = true
        self.snapshot = snapshot
    }

    func perform(_ command: MediaPlaybackCommand) {
        applyOptimisticUpdate(for: command)

        Task { @MainActor [weak self] in
            guard let self else { return }
            await provider.perform(command)
            await refresh()
        }
    }

    func handleLaunchTrigger(_ trigger: SpotifyLaunchTrigger) {
        guard let command = SpotifyLaunchPolicy.command(for: trigger) else { return }
        perform(command)
    }

    private func applyOptimisticUpdate(for command: MediaPlaybackCommand) {
        switch command {
        case .togglePlayPause:
            switch snapshot.playbackState {
            case .playing:
                snapshot.playbackState = .paused
            case .paused, .stopped:
                snapshot.playbackState = .playing
            }
        case let .seek(position):
            snapshot.position = min(max(position, 0), max(snapshot.duration, 0))
        case let .setVolume(volume):
            snapshot.volume = min(max(volume, 0), 1)
        case .open, .previous, .next:
            break
        }
    }
}
