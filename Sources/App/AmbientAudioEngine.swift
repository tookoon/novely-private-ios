import AVFoundation
import Foundation

// MARK: - Bundled Realistic Offline Ambient Sound Loops (.m4a via AVAudioPlayer)

public enum AmbientSoundMode: String, CaseIterable, Identifiable {
    case off = "Aus"
    case rain = "Regen"
    case fireplace = "Kamin"
    case library = "Bibliothek"
    case piano = "Klavier"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .off: return "speaker.slash"
        case .rain: return "cloud.rain.fill"
        case .fireplace: return "flame.fill"
        case .library: return "building.columns.fill"
        case .piano: return "music.note"
        }
    }

    public var resourceName: String? {
        switch self {
        case .off: return nil
        case .rain: return "ambient_rain"
        case .fireplace: return "ambient_fireplace"
        case .library: return "ambient_library"
        case .piano: return "ambient_piano"
        }
    }
}

@MainActor
public final class AmbientAudioEngine: ObservableObject {
    @Published public var mode: AmbientSoundMode = .off
    @Published public var volume: Float = 0.72 {
        didSet {
            player?.volume = volume
        }
    }

    private var player: AVAudioPlayer?

    public init() {}

    public func select(_ newMode: AmbientSoundMode) {
        mode = newMode
        stop()
        guard let resource = newMode.resourceName else { return }
        startLoop(resourceName: resource)
    }

    public func stop() {
        player?.stop()
        player = nil
    }

    private func startLoop(resourceName: String) {
        let url = Bundle.main.url(forResource: resourceName, withExtension: "m4a")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "m4a", subdirectory: "Sounds")

        guard let audioURL = url else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = volume
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            self.player = audioPlayer
        } catch {
            // Ignore audio hardware unavailable errors in headless simulator
        }
    }
}
