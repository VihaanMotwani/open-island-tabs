import AppKit
import Observation

/// Artwork and labels are published together, independently of playback position.
struct MusicTrackKey: Hashable {
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?

    init(_ snapshot: MediaPlaybackSnapshot) {
        title = snapshot.title
        artist = snapshot.artist
        album = snapshot.album
        artworkURL = snapshot.artworkURL
    }
}

struct MusicPresentedTrack: Identifiable {
    let id: MusicTrackKey
    let artwork: NSImage?
    var title: String { id.title }
    var artist: String { id.artist }
}

@MainActor
@Observable
final class MusicPresentationModel {
    private(set) var track: MusicPresentedTrack?
    @ObservationIgnored private let loadArtwork: @MainActor (URL) async throws -> Data
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private let cache = NSCache<NSURL, NSImage>()

    init(loadArtwork: @escaping @MainActor (URL) async throws -> Data = MusicPresentationModel.remoteArtwork) {
        self.loadArtwork = loadArtwork
        cache.countLimit = 8
    }

    func update(_ snapshot: MediaPlaybackSnapshot) async {
        generation += 1
        let requestGeneration = generation
        guard snapshot.availability == .running else {
            track = nil
            return
        }
        let key = MusicTrackKey(snapshot)
        let image: NSImage?
        if let url = key.artworkURL, let cached = cache.object(forKey: url as NSURL) {
            image = cached
        } else if let url = key.artworkURL, let data = try? await loadArtwork(url) {
            image = NSImage(data: data)
            if let image { cache.setObject(image, forKey: url as NSURL) }
        } else {
            image = nil
        }
        guard generation == requestGeneration, !Task.isCancelled else { return }
        track = MusicPresentedTrack(id: key, artwork: image)
    }

    /// Harness fixtures bypass network loading, including during transition captures.
    func applyPreview(_ snapshot: MediaPlaybackSnapshot, artwork: NSImage?) {
        generation += 1
        track = snapshot.availability == .running
            ? MusicPresentedTrack(id: MusicTrackKey(snapshot), artwork: artwork) : nil
    }

    private static func remoteArtwork(_ url: URL) async throws -> Data {
        let request = URLRequest(url: url, timeoutInterval: 1.5)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
