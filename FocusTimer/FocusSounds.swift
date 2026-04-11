//
//  FocusSounds.swift
//  FocusTimer
//

import Foundation
import Combine
import AVFoundation

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
    
    var frequency: Float {
        switch self {
        case .whiteNoise: return 0
        case .brownNoise: return 1
        case .pinkNoise: return 2
        default: return -1
        }
    }
}

// MARK: - Sound Manager

class FocusSoundManager: ObservableObject {
    static let shared = FocusSoundManager()
    
    @Published var currentSound: FocusSoundType = .none
    @Published var volume: Float = 0.5
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var noiseGenerator: AVAudioEngine?
    private var noiseNode: AVAudioSourceNode?
    
    func play(sound: FocusSoundType) {
        stop()
        
        currentSound = sound
        
        if sound == .none {
            return
        }
        
        // For noise types, generate them programmatically
        if sound.frequency >= 0 {
            generateNoise(type: sound)
        } else {
            // For ambient sounds, we would load audio files
            // Since we don't have actual audio files, we'll simulate with system sounds
            playSystemSound()
        }
        
        isPlaying = true
    }
    
    func stop() {
        isPlaying = false
        audioPlayer?.stop()
        audioPlayer = nil
        noiseGenerator?.stop()
        noiseGenerator = nil
        noiseNode = nil
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = volume
    }
    
    private func playSystemSound() {
        // In a real implementation, this would play ambient audio files
        // For now, we'll use a placeholder approach
        // The app would include bundled audio files for rain, forest, etc.
    }
    
    private func generateNoise(type: FocusSoundType) {
        // Noise generation would be implemented here
        // White, brown, and pink noise can be generated programmatically
        // This is a simplified placeholder
    }
    
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
