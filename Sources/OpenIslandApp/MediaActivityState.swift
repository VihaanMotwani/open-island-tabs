enum MediaActivityState: Equatable, Hashable, Sendable {
    case hidden
    case paused
    case playing

    init(snapshot: MediaPlaybackSnapshot) {
        guard snapshot.availability == .running else {
            self = .hidden
            return
        }

        self = snapshot.playbackState == .playing ? .playing : .paused
    }
}
