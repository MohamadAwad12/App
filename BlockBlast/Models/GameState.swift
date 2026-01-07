//
//  GameState.swift
//  BlockBlast
//

import Foundation

/// Represents the current state of a game
struct GameState: Codable {
    var score: Int = 0
    var level: Int = 1
    var combo: Int = 0
    var blocksCleared: Int = 0
    var movesRemaining: Int? = nil  // nil for endless mode
    var timeRemaining: TimeInterval? = nil  // nil for untimed mode
    var powerUps: [PowerUpType: Int] = [:]
    var isFrozen: Bool = false
    var frozenTimeRemaining: TimeInterval = 0

    /// Points needed for next level
    var pointsForNextLevel: Int {
        return level * 1000
    }

    /// Progress towards next level (0.0 - 1.0)
    var levelProgress: Double {
        let pointsInCurrentLevel = score - ((level - 1) * 1000)
        return Double(pointsInCurrentLevel) / Double(1000)
    }

    /// Calculate score for clearing blocks
    mutating func calculateScore(blocksCleared count: Int) -> Int {
        // Base score: 10 points per block
        // Combo multiplier: combo * 0.5 + 1
        // Size bonus: extra points for clearing larger groups

        let baseScore = count * 10
        let comboMultiplier = Double(combo) * 0.5 + 1.0
        let sizeBonus = count > 5 ? (count - 5) * 5 : 0

        let totalScore = Int(Double(baseScore + sizeBonus) * comboMultiplier)

        score += totalScore
        blocksCleared += count
        combo += 1

        // Check for level up
        while score >= pointsForNextLevel {
            level += 1
        }

        return totalScore
    }

    /// Reset combo when no match is made
    mutating func resetCombo() {
        combo = 0
    }

    /// Add a power-up
    mutating func addPowerUp(_ type: PowerUpType) {
        powerUps[type, default: 0] += 1
    }

    /// Use a power-up
    mutating func usePowerUp(_ type: PowerUpType) -> Bool {
        guard let count = powerUps[type], count > 0 else { return false }
        powerUps[type] = count - 1
        return true
    }

    /// Apply freeze effect (from opponent in multiplayer)
    mutating func applyFreeze(duration: TimeInterval = 3.0) {
        isFrozen = true
        frozenTimeRemaining = duration
    }

    /// Update freeze timer
    mutating func updateFreeze(deltaTime: TimeInterval) {
        if isFrozen {
            frozenTimeRemaining -= deltaTime
            if frozenTimeRemaining <= 0 {
                isFrozen = false
                frozenTimeRemaining = 0
            }
        }
    }
}

/// Game mode options
enum GameMode: String, CaseIterable, Codable {
    case endless = "Endless"
    case timed = "Timed"
    case moves = "Limited Moves"
    case multiplayer = "Multiplayer"

    var description: String {
        switch self {
        case .endless:
            return "Play until no moves remain"
        case .timed:
            return "Score as high as possible in 2 minutes"
        case .moves:
            return "Clear blocks in 30 moves"
        case .multiplayer:
            return "Compete against another player"
        }
    }

    var icon: String {
        switch self {
        case .endless: return "infinity"
        case .timed: return "clock.fill"
        case .moves: return "number"
        case .multiplayer: return "person.2.fill"
        }
    }
}

/// Difficulty levels
enum Difficulty: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var colorCount: Int {
        switch self {
        case .easy: return 4
        case .medium: return 5
        case .hard: return 6
        case .expert: return 6
        }
    }

    var gridSize: (rows: Int, columns: Int) {
        switch self {
        case .easy: return (8, 6)
        case .medium: return (10, 8)
        case .hard: return (10, 8)
        case .expert: return (12, 10)
        }
    }
}
