//
//  FocusSounds.swift
//  FocusTimer
//

import Foundation
import Combine
import AVFoundation
import AudioToolbox

// MARK: - Sound Type

enum FocusSoundType: String, CaseIterable, Codable, Identifiable {
    case none = "none"
    case rain = "rain"
    case forest = "forest"
    case ocean = "ocean"
    case coffeeShop = "coffee_shop"
    case fireplace = "fireplace"
    case lofi = "lofi"
    case whiteNoise = "white_noise"
    case brownNoise = "brown_noise"
    case pinkNoise = "pink_noise"
    case wind = "wind"
    case birds = "birds"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .rain: return "Rain"
        case .forest: return "Forest"
        case .ocean: return "Ocean Waves"
        case .coffeeShop: return "Coffee Shop"
        case .fireplace: return "Fireplace"
        case .lofi: return "Lo-Fi Beats"
        case .whiteNoise: return "White Noise"
        case .brownNoise: return "Brown Noise"
        case .pinkNoise: return "Pink Noise"
        case .wind: return "Wind"
        case .birds: return "Birds Chirping"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .forest: return "leaf.fill"
        case .ocean: return "water.waves"
        case .coffeeShop: return "cup.and.saucer.fill"
        case .fireplace: return "flame.fill"
        case .lofi: return "headphones"
        case .whiteNoise: return "waveform"
        case .brownNoise: return "waveform.path"
        case .pinkNoise: return "waveform.circle"
        case .wind: return "wind"
        case .birds: return "bird.fill"
        }
    }
    
    /// -1 = use AVAudioEngine synthesized, 0 = white noise, 1 = brown noise, 2 = pink noise
    var frequency: Float {
        switch self {
        case .whiteNoise: return 0
        case .brownNoise: return 1
        case .pinkNoise: return 2
        default: return -1
        }
    }
    
    var isSynthesized: Bool {
        return frequency >= 0 || Self.synthesizableSounds.contains(self)
    }
    
    static let synthesizableSounds: Set<FocusSoundType> = [
        .rain, .forest, .ocean, .coffeeShop, .fireplace, .wind, .birds, .lofi
    ]
}

// MARK: - Sound Manager

class FocusSoundManager: ObservableObject {
    static let shared = FocusSoundManager()
    
    @Published var currentSound: FocusSoundType = .none
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    
    // Noise state for colored noise
    private var noiseState: [Float] = [0, 0, 0, 0, 0, 0, 0]
    private var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0
    private var b4: Float = 0, b5: Float = 0, b6: Float = 0
    
    // Ambient synthesis state
    private var phase: Float = 0
    private var lfoPhase: Float = 0
    
    // Bird chirp state
    private var birdTimer: Float = 0
    private var birdChirpPhase: Float = 0
    private var birdActive: Bool = false
    
    // Raindrop state
    private var rainDrops: [Float] = []
    private let rainDropCount = 60
    
    func play(sound: FocusSoundType) {
        stop()
        
        currentSound = sound
        
        if sound == .none {
            return
        }
        
        if sound.frequency >= 0 {
            // Colored noise (white/pink/brown)
            startSynthesizedAudio(soundType: sound)
        } else if FocusSoundType.synthesizableSounds.contains(sound) {
            // Procedurally synthesized ambient sounds
            startSynthesizedAudio(soundType: sound)
        } else {
            // Fallback: notification sound
            playSystemSound()
            isPlaying = true
        }
    }
    
    func stop() {
        isPlaying = false
        audioPlayer?.stop()
        audioPlayer = nil
        
        audioEngine?.stop()
        sourceNode = nil
        audioEngine = nil
        
        // Reset state
        phase = 0
        lfoPhase = 0
        birdTimer = 0
        birdActive = false
        noiseState = [0, 0, 0, 0, 0, 0, 0]
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; b4 = 0; b5 = 0; b6 = 0
        
        // Reset rain drops
        rainDrops = []
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
    }
    
    private func playSystemSound() {
        AudioServicesPlaySystemSound(1007)
    }
    
    // MARK: - Synthesized Audio Engine
    
    private func startSynthesizedAudio(soundType: FocusSoundType) {
        audioEngine?.stop()
        audioEngine = nil
        sourceNode = nil
        
        let engine = AVAudioEngine()
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Initialize rain drops
        if soundType == .rain {
            rainDrops = (0..<rainDropCount).map { _ in Float.random(in: 0...1) }
        }
        
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = ablPointer.first, let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            let vol = self.volume
            
            for frame in 0..<Int(frameCount) {
                let sample: Float
                
                switch soundType {
                    
                case .whiteNoise:
                    sample = Float.random(in: -1...1) * vol
                    
                case .brownNoise:
                    sample = self.generateBrownNoise(volume: vol)
                    
                case .pinkNoise:
                    sample = self.generatePinkNoise(volume: vol)
                    
                case .rain:
                    sample = self.generateRainSound(volume: vol)
                    
                case .ocean:
                    sample = self.generateOceanSound(volume: vol)
                    
                case .forest:
                    sample = self.generateForestSound(volume: vol)
                    
                case .coffeeShop:
                    sample = self.generateCoffeeShopSound(volume: vol)
                    
                case .fireplace:
                    sample = self.generateFireplaceSound(volume: vol)
                    
                case .wind:
                    sample = self.generateWindSound(volume: vol)
                    
                case .birds:
                    sample = self.generateBirdSound(volume: vol)
                    
                case .lofi:
                    sample = self.generateLofiSound(volume: vol)
                    
                default:
                    sample = 0
                }
                
                ptr[frame] = sample
            }
            
            return noErr
        }
        
        sourceNode = node
        audioEngine = engine
        
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        
        // Set session category for background audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
        
        do {
            try engine.start()
            isPlaying = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Noise Generation
    
    private func generateBrownNoise(volume: Float) -> Float {
        let white = Float.random(in: -1...1)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        let output = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.11
        b6 = white * 0.115926
        return output * volume
    }
    
    private func generatePinkNoise(volume: Float) -> Float {
        let white = Float.random(in: -1...1)
        noiseState[0] = 0.99886 * noiseState[0] + white * 0.0555179
        noiseState[1] = 0.99332 * noiseState[1] + white * 0.0750759
        noiseState[2] = 0.96900 * noiseState[2] + white * 0.1538520
        noiseState[3] = 0.86650 * noiseState[3] + white * 0.3104856
        noiseState[4] = 0.55000 * noiseState[4] + white * 0.5329522
        noiseState[5] = -0.7616 * noiseState[5] - white * 0.0168980
        let pink = (noiseState[0] + noiseState[1] + noiseState[2] + noiseState[3] +
                    noiseState[4] + noiseState[5] + noiseState[6] + white * 0.5362) * 0.11
        noiseState[6] = white * 0.115926
        return pink * volume
    }
    
    // MARK: - Ambient Sound Synthesis
    
    /// Rain: layered filtered noise with random droplets
    private func generateRainSound(volume: Float) -> Float {
        // Base rain: low-pass filtered white noise
        let white = Float.random(in: -1...1)
        b0 = 0.99 * b0 + white * 0.1
        let baseRain = b0 * 0.8
        
        // Raindrop impacts: occasional brief spikes
        var drop: Float = 0
        for i in 0..<rainDropCount {
            rainDrops[i] -= Float.random(in: 0.001...0.003)
            if rainDrops[i] <= 0 {
                rainDrops[i] = Float.random(in: 0.02...0.15)
                drop += Float.random(in: 0.3...0.8) * rainDrops[i]
            } else {
                drop += -rainDrops[i] * Float.random(in: 0.5...1.5)
            }
        }
        
        return (baseRain * 0.7 + drop * 0.3) * volume
    }
    
    /// Ocean: slow wave oscillation with filtered noise
    private func generateOceanSound(volume: Float) -> Float {
        // LFO controls the "wave" amplitude (period ~7 seconds)
        lfoPhase += 0.00014 // ~7 second cycle at 44.1kHz
        if lfoPhase > Float.pi * 2 { lfoPhase -= Float.pi * 2 }
        let waveAmp = (sin(lfoPhase) + 1) * 0.5
        
        // Filtered noise for wave texture
        let white = Float.random(in: -1...1)
        b0 = 0.97 * b0 + white * 0.12
        let waveTexture = b0 * 0.4
        
        // Combine: wave envelope * texture + subtle low rumble
        let wave = (waveAmp * waveTexture + sin(lfoPhase * 0.5) * 0.1) * 0.8
        
        return wave * volume
    }
    
    /// Forest: pink noise base + occasional bird chirps + wind gusts
    private func generateForestSound(volume: Float) -> Float {
        // Pink noise base (soft wind through leaves)
        let pink = generatePinkNoise(volume: 0.5)
        
        // Wind gust: slow LFO modulating the noise
        lfoPhase += 0.00005
        if lfoPhase > Float.pi * 2 { lfoPhase -= Float.pi * 2 }
        let windGust = (sin(lfoPhase) + 1) * 0.25
        
        // Bird chirps: brief sinusoidal bursts
        var bird: Float = 0
        birdTimer += 1
        if birdTimer > 8000 + Float.random(in: 0...4000) {
            birdTimer = 0
            birdActive = true
            birdChirpPhase = 0
        }
        if birdActive {
            birdChirpPhase += 0.4
            // Frequency sweep for chirp character
            let freq = 1800 + sin(birdChirpPhase * 3) * 400
            bird = sin(birdChirpPhase * freq * 0.01) * exp(-birdChirpPhase * 0.15) * 0.15
            if birdChirpPhase > 30 { birdActive = false }
        }
        
        return (pink * (0.4 + windGust) + bird) * volume
    }
    
    /// Coffee Shop: brown noise base + soft babble modulation
    private func generateCoffeeShopSound(volume: Float) -> Float {
        // Brown noise for ambient chatter base
        let chatter = generateBrownNoise(volume: 0.35)
        
        // Babble: multiple low-freq AM modulations to simulate voices
        lfoPhase += 0.00008
        let chatterEnvelope = (sin(lfoPhase) * 0.3 + sin(lfoPhase * 2.3) * 0.2 + sin(lfoPhase * 0.7) * 0.25 + 0.8)
        
        // Occasional cup/clink sounds
        phase += 1
        var clink: Float = 0
        if phase > 15000 + Float.random(in: 0...10000) {
            phase = 0
            clink = Float.random(in: 0.5...1.0) * 0.2
        }
        
        return (chatter * chatterEnvelope + clink) * volume
    }
    
    /// Fireplace: brown noise + crackle pops + low rumble
    private func generateFireplaceSound(volume: Float) -> Float {
        // Base: warm low-frequency noise (fire roar)
        let white = Float.random(in: -1...1)
        b0 = 0.95 * b0 + white * 0.08
        let fireBase = b0 * 0.5
        
        // Crackle: random impulse pops
        var crackle: Float = 0
        phase += 1
        if Float.random(in: 0...1) < 0.0015 {
            crackle = Float.random(in: 0.3...0.9) * (Float.random(in: 0...1) > 0.5 ? 1 : -1)
        }
        
        // Low rumble
        lfoPhase += 0.00003
        let rumble = sin(lfoPhase * 0.8) * 0.08
        
        return (fireBase + crackle * 0.3 + rumble) * volume
    }
    
    /// Wind: band-pass filtered noise with slow modulation
    private func generateWindSound(volume: Float) -> Float {
        let white = Float.random(in: -1...1)
        
        // Heavily filtered for "whooshing" quality
        b0 = 0.97 * b0 + white * 0.08
        b1 = 0.95 * b1 + b0 * 0.1
        
        // Slow amplitude modulation (gusts)
        lfoPhase += 0.00006
        let gustAmp = (sin(lfoPhase) + 1) * 0.4 + 0.3
        
        return b1 * gustAmp * volume
    }
    
    /// Birds: sparse chirps over quiet background
    private func generateBirdSound(volume: Float) -> Float {
        // Very quiet ambient background
        let ambient = generatePinkNoise(volume: 0.15)
        
        // Bird chirp timing
        birdTimer += 1
        if birdTimer > 6000 + Float.random(in: 0...8000) {
            birdTimer = 0
            birdActive = true
            birdChirpPhase = 0
        }
        
        var bird: Float = 0
        if birdActive {
            birdChirpPhase += 0.3
            // Chirp: frequency-modulated sine with fast decay
            let chirpFreq = 2400 + sin(birdChirpPhase * 4) * 600
            bird = sin(birdChirpPhase * chirpFreq * 0.008) * exp(-birdChirpPhase * 0.12) * 0.25
            // Second harmonic for richness
            bird += sin(birdChirpPhase * chirpFreq * 0.012) * exp(-birdChirpPhase * 0.15) * 0.08
            if birdChirpPhase > 35 { birdActive = false }
        }
        
        return (ambient + bird) * volume
    }
    
    /// Lo-Fi: filtered brown noise with subtle vinyl crackle and low-fi character
    private func generateLofiSound(volume: Float) -> Float {
        // Lo-fi base: brown noise with very slow rolloff
        let white = Float.random(in: -1...1)
        b0 = 0.99 * b0 + white * 0.02
        b1 = 0.98 * b1 + b0 * 0.03
        let lofiBase = b1 * 0.6
        
        // Subtle vinyl crackle
        var crackle: Float = 0
        if Float.random(in: 0...1) < 0.002 {
            crackle = Float.random(in: 0.1...0.3) * (Float.random(in: 0...1) > 0.5 ? 1 : -1)
        }
        
        // Very slow wobble (like a worn record)
        lfoPhase += 0.00002
        let wobble = sin(lfoPhase * 0.3) * 0.05
        
        return (lofiBase + crackle * 0.1) * (1 + wobble) * volume
    }
    
    // MARK: - Persistence
    
    func save() {
        UserDefaults.standard.set(currentSound.rawValue, forKey: "focus_sound")
        UserDefaults.standard.set(volume, forKey: "focus_sound_volume")
    }
    
    func load() {
        if let raw = UserDefaults.standard.string(forKey: "focus_sound"),
           let sound = FocusSoundType(rawValue: raw) {
            currentSound = sound
        }
        volume = UserDefaults.standard.float(forKey: "focus_sound_volume")
        if volume == 0 { volume = 0.5 }
    }
}
