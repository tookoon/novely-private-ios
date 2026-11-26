import AVFoundation
import Foundation

// MARK: - Procedural Offline Ambient Sound Engine (Rain, Fireplace, Warm Noise)

public enum AmbientSoundMode: String, CaseIterable, Identifiable {
    case off = "Aus"
    case rain = "Regen"
    case fireplace = "Kamin"
    case library = "Bibliothek"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .off: return "speaker.slash"
        case .rain: return "cloud.rain.fill"
        case .fireplace: return "flame.fill"
        case .library: return "building.columns.fill"
        }
    }
}

@MainActor
public final class AmbientAudioEngine: ObservableObject {
    @Published public var mode: AmbientSoundMode = .off
    @Published public var volume: Float = 0.45 {
        didSet {
            sourceNode?.volume = volume
        }
    }

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    public init() {}

    public func select(_ newMode: AmbientSoundMode) {
        mode = newMode
        stop()
        guard newMode != .off else { return }
        start(mode: newMode)
    }

    public func stop() {
        engine?.stop()
        engine = nil
        sourceNode = nil
    }

    private func start(mode: AmbientSoundMode) {
        let audioEngine = AVAudioEngine()
        let format = audioEngine.outputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }

        var lastOut: Float = 0.0
        var b0: Float = 0, b1: Float = 0, b2: Float = 0

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let white = Float.random(in: -1.0...1.0)
                let sample: Float

                switch mode {
                case .rain:
                    // Soft pink-ish rain wash
                    b0 = 0.997 * b0 + white * 0.029
                    b1 = 0.985 * b1 + white * 0.032
                    b2 = 0.950 * b2 + white * 0.048
                    sample = (b0 + b1 + b2 + white * 0.018) * 0.25
                case .fireplace:
                    // Warm low rumble + occasional subtle crackle
                    lastOut = (lastOut + 0.025 * white) / 1.025
                    let crackle: Float = Float.random(in: 0...1) > 0.9985 ? Float.random(in: -0.35...0.35) : 0
                    sample = lastOut * 1.4 + crackle * 0.35
                case .library:
                    // Deep gentle brown noise
                    lastOut = (lastOut + 0.015 * white) / 1.015
                    sample = lastOut * 1.1
                case .off:
                    sample = 0
                }

                for buf in abl {
                    guard let ptr = buf.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    ptr[frame] = sample
                }
            }
            return noErr
        }

        node.volume = volume
        audioEngine.attach(node)
        audioEngine.connect(node, to: audioEngine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            self.engine = audioEngine
            self.sourceNode = node
        } catch {
            // Silently ignore on simulator if audio hardware unavailable
        }
    }
}
