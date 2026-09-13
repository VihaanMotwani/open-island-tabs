import AppKit
import Testing
@testable import OpenIslandApp

@MainActor
struct MusicPresentationModelTests {
    @Test
    func failedArtworkShowsTheNewTitleWithoutTheOldSongsCover() async {
        let data = imageData(.red)
        let model = MusicPresentationModel { url in
            if url.lastPathComponent == "Missing.png" { throw URLError(.timedOut) }
            return data
        }
        await model.update(track("First"))
        #expect(model.track?.artwork != nil)
        await model.update(track("Missing"))
        #expect(model.track?.title == "Missing")
        #expect(model.track?.artwork == nil)
    }

    @Test
    func tracksWithoutCoversStillPublishTheirMetadata() async {
        var noCover = track("No cover")
        noCover.artworkURL = nil
        let model = MusicPresentationModel { _ in
            Issue.record("A track without a cover must not request artwork")
            return Data()
        }
        await model.update(noCover)
        #expect(model.track?.title == "No cover")
        #expect(model.track?.artwork == nil)
    }

    @Test
    func revisitingATrackUsesItsCachedCover() async {
        var requests: [URL] = []
        let data = imageData(.red)
        let model = MusicPresentationModel { url in
            requests.append(url)
            return data
        }
        await model.update(track("First"))
        let firstImage = model.track?.artwork
        await model.update(track("Second"))
        await model.update(track("First"))
        #expect(requests.count == 2)
        #expect(model.track?.artwork === firstImage)
    }

    @Test
    func stoppingPlaybackClearsArtworkAndRejectsThePendingCover() async {
        let loader = ArtworkLoaderStub()
        let model = MusicPresentationModel(loadArtwork: loader.load)
        let song = track("Pending")
        let loading = Task { await model.update(song) }
        while loader.pending.isEmpty { await Task.yield() }
        await model.update(.notRunning)
        loader.finish(song.artworkURL!, data: imageData(.red))
        await loading.value
        #expect(model.track == nil)
    }

    @Test
    func aSlowSkippedSongCannotReplaceTheLatestSong() async {
        let loader = ArtworkLoaderStub()
        let model = MusicPresentationModel(loadArtwork: loader.load)
        let skipped = track("Skipped")
        let latest = track("Latest")
        let slow = Task { await model.update(skipped) }
        while loader.pending[skipped.artworkURL!] == nil { await Task.yield() }
        let fast = Task { await model.update(latest) }
        while loader.pending[latest.artworkURL!] == nil { await Task.yield() }
        loader.finish(latest.artworkURL!, data: imageData(.blue))
        await fast.value
        loader.finish(skipped.artworkURL!, data: imageData(.red))
        await slow.value
        #expect(model.track?.title == "Latest")
    }

    @Test
    func keepsThePreviousCoverAndTitleTogetherUntilTheNextCoverArrives() async {
        let loader = ArtworkLoaderStub()
        let model = MusicPresentationModel(loadArtwork: loader.load)
        let first = track("First")
        let second = track("Second")
        let initial = Task { await model.update(first) }
        while loader.pending.isEmpty { await Task.yield() }
        loader.finish(first.artworkURL!, data: imageData(.red))
        await initial.value
        let previousImage = model.track?.artwork

        let next = Task { await model.update(second) }
        while loader.pending.isEmpty { await Task.yield() }

        #expect(model.track?.title == "First")
        #expect(model.track?.artwork === previousImage)
        loader.finish(second.artworkURL!, data: imageData(.blue))
        await next.value
        #expect(model.track?.title == "Second")
        #expect(model.track?.artwork != nil)
        #expect(model.track?.artwork !== previousImage)
    }

    private func track(_ title: String) -> MediaPlaybackSnapshot {
        MediaPlaybackSnapshot(availability: .running, playbackState: .playing,
            title: title, artist: "Artist", album: "Album",
            artworkURL: URL(string: "https://example.com/\(title).png"),
            duration: 240, position: 0, volume: 0.5)
    }

    private func imageData(_ color: NSColor) -> Data {
        let image = NSImage(size: NSSize(width: 2, height: 2), flipped: false) { rect in
            color.setFill()
            rect.fill()
            return true
        }
        return image.tiffRepresentation!
    }
}

@MainActor
private final class ArtworkLoaderStub {
    var pending: [URL: CheckedContinuation<Data, any Error>] = [:]
    func load(_ url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { pending[url] = $0 }
    }
    func finish(_ url: URL, data: Data) {
        pending.removeValue(forKey: url)?.resume(returning: data)
    }
}
