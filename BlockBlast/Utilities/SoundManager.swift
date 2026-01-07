//
//  SoundManager.swift
//  BlockBlast
//

import AVFoundation
import UIKit

/// Sound effects available in the game
enum GameSound: String, CaseIterable {
    case blockClear = "block_clear"
    case blockFall = "block_fall"
    case combo = "combo"
    case powerUp = "power_up"
    case gameStart = "game_start"
    case gameOver = "game_over"
    case victory = "victory"
    case defeat = "defeat"
    case invalidMove = "invalid_move"
    case tick = "tick"
    case freeze = "freeze"
    case buttonTap = "button_tap"

    /// System sound ID for fallback
    var systemSoundID: SystemSoundID {
        switch self {
        case .blockClear: return 1104  // Tink
        case .blockFall: return 1103   // Tock
        case .combo: return 1025       // New Mail
        case .powerUp: return 1114     // Tweet sent
        case .gameStart: return 1113   // Beginning
        case .gameOver: return 1073    // VC Ended
        case .victory: return 1025     // New Mail
        case .defeat: return 1073      // VC Ended
        case .invalidMove: return 1053 // Shake
        case .tick: return 1104        // Tink
        case .freeze: return 1110      // Swish
        case .buttonTap: return 1104   // Tink
        }
    }
}

/// Manages audio playback for the game
class SoundManager {
    static let shared = SoundManager()

    private var soundPlayers: [GameSound: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var isEnabled: Bool = true
    private var isMusicEnabled: Bool = true
    private var volume: Float = 1.0

    private init() {
        setupAudioSession()
        preloadSounds()
    }

    /// Setup audio session for game sounds
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    /// Preload all sound effects
    private func preloadSounds() {
        for sound in GameSound.allCases {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") ??
                        Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    soundPlayers[sound] = player
                } catch {
                    print("Failed to load sound \(sound.rawValue): \(error)")
                }
            }
        }
    }

    /// Enable or disable sound effects
    func setSoundEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    /// Enable or disable music
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopMusic()
        }
    }

    /// Set volume level (0.0 - 1.0)
    func setVolume(_ volume: Float) {
        self.volume = max(0, min(1, volume))
        musicPlayer?.volume = self.volume * 0.5
    }

    /// Play a sound effect
    func play(_ sound: GameSound) {
        guard isEnabled else { return }

        if let player = soundPlayers[sound] {
            player.volume = volume
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(sound.systemSoundID)
        }
    }

    /// Play background music
    func playMusic(named name: String) {
        guard isMusicEnabled else { return }

        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            do {
                musicPlayer = try AVAudioPlayer(contentsOf: url)
                musicPlayer?.numberOfLoops = -1  // Loop indefinitely
                musicPlayer?.volume = volume * 0.5
                musicPlayer?.play()
            } catch {
                print("Failed to play music: \(error)")
            }
        }
    }

    /// Stop background music
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    /// Pause all audio
    func pauseAll() {
        musicPlayer?.pause()
    }

    /// Resume all audio
    func resumeAll() {
        if isMusicEnabled {
            musicPlayer?.play()
        }
    }

    // MARK: - Convenience methods for game events

    /// Play block clear sound with pitch variation based on combo
    func playBlockClear(comboLevel: Int = 0) {
        guard isEnabled else { return }

        if let player = soundPlayers[.blockClear] {
            // Increase pitch slightly for combos (simulated by playing faster)
            player.volume = volume
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(GameSound.blockClear.systemSoundID)
        }

        // Play combo sound for higher combos
        if comboLevel >= 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.play(.combo)
            }
        }
    }
}
