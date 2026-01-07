//
//  GameManager.swift
//  BlockBlast
//

import SwiftUI
import Combine

/// Main game manager that coordinates all game logic
class GameManager: ObservableObject {
    // MARK: - Published Properties

    @Published var appState: AppState = .menu
    @Published var grid: GameGrid
    @Published var gameState: GameState
    @Published var gameMode: GameMode = .endless
    @Published var difficulty: Difficulty = .medium
    @Published var selectedPositions: Set<Position> = []
    @Published var isAnimating: Bool = false
    @Published var lastScoreGained: Int = 0
    @Published var scorePopupPosition: CGPoint? = nil
    @Published var highScores: [GameMode: Int] = [:]

    // MARK: - Private Properties

    private var gameTimer: AnyCancellable?
    private var animationTimer: AnyCancellable?
    private let haptics = HapticsManager.shared
    private let sounds = SoundManager.shared

    // MARK: - Initialization

    init() {
        let size = Difficulty.medium.gridSize
        self.grid = GameGrid(rows: size.rows, columns: size.columns, colorCount: Difficulty.medium.colorCount)
        self.gameState = GameState()
        loadHighScores()
    }

    // MARK: - Game Control

    /// Start a new game with the specified mode and difficulty
    func startGame(mode: GameMode, difficulty: Difficulty) {
        self.gameMode = mode
        self.difficulty = difficulty

        let size = difficulty.gridSize
        grid = GameGrid(rows: size.rows, columns: size.columns, colorCount: difficulty.colorCount)
        gameState = GameState()

        // Set up mode-specific parameters
        switch mode {
        case .timed:
            gameState.timeRemaining = 120  // 2 minutes
            startTimer()
        case .moves:
            gameState.movesRemaining = 30
        case .multiplayer:
            // Handled by MultiplayerManager
            break
        case .endless:
            break
        }

        // Give starting power-ups
        gameState.addPowerUp(.bomb)
        gameState.addPowerUp(.lightning)

        withAnimation(.easeInOut(duration: 0.3)) {
            appState = .playing
        }

        sounds.play(.gameStart)
    }

    /// Handle tap on a block
    func handleTap(at row: Int, column: Int) {
        guard !isAnimating && !gameState.isFrozen else { return }

        let connectedBlocks = grid.findConnectedBlocks(from: row, column: column)

        if connectedBlocks.count >= 2 {
            clearBlocks(connectedBlocks)
        } else {
            // Invalid tap - shake animation
            haptics.notification(type: .warning)
            sounds.play(.invalidMove)
        }
    }

    /// Clear blocks and process game logic
    private func clearBlocks(_ positions: Set<Position>) {
        isAnimating = true

        // Mark blocks as matched for animation
        for position in positions {
            if grid.blocks[position.row][position.column] != nil {
                grid.blocks[position.row][position.column]?.isMatched = true
            }
        }

        // Calculate score
        let scoreGained = gameState.calculateScore(blocksCleared: positions.count)
        lastScoreGained = scoreGained

        // Haptic and sound feedback based on combo
        if gameState.combo > 3 {
            haptics.notification(type: .success)
            sounds.play(.combo)
        } else {
            haptics.impact(style: .medium)
            sounds.play(.blockClear)
        }

        // Award power-ups for large clears
        if positions.count >= 7 {
            gameState.addPowerUp(.bomb)
            sounds.play(.powerUp)
        }
        if positions.count >= 10 {
            gameState.addPowerUp(.lightning)
        }

        // Decrement moves if in moves mode
        if gameMode == .moves {
            gameState.movesRemaining? -= 1
        }

        // Animation sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.grid.removeBlocks(at: positions)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                _ = self?.grid.applyGravity()
                self?.sounds.play(.blockFall)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    _ = self?.grid.fillEmptySpaces()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        self?.isAnimating = false
                        self?.checkGameOver()
                    }
                }
            }
        }
    }

    /// Use a power-up
    func usePowerUp(_ type: PowerUpType, at row: Int? = nil, column: Int? = nil) {
        guard gameState.usePowerUp(type) else { return }

        isAnimating = true
        sounds.play(.powerUp)
        haptics.notification(type: .success)

        var clearedPositions = Set<Position>()

        switch type {
        case .bomb:
            if let row = row, let col = column {
                clearedPositions = grid.clearArea(centerRow: row, centerColumn: col, radius: 1)
            }
        case .lightning:
            if let row = row {
                clearedPositions = grid.clearRow(row)
            }
        case .rainbow:
            if let row = row, let col = column,
               let block = grid.block(at: row, column: col) {
                clearedPositions = grid.clearColor(block.color)
            }
        case .shuffle:
            grid.shuffleBlocks()
        case .freeze:
            // Only used in multiplayer
            break
        }

        if !clearedPositions.isEmpty {
            let scoreGained = gameState.calculateScore(blocksCleared: clearedPositions.count)
            lastScoreGained = scoreGained
        }

        // Process gravity and refill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            _ = self?.grid.applyGravity()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                _ = self?.grid.fillEmptySpaces()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.isAnimating = false
                    self?.checkGameOver()
                }
            }
        }
    }

    /// Check for game over conditions
    private func checkGameOver() {
        var isGameOver = false

        switch gameMode {
        case .endless:
            isGameOver = !grid.hasValidMoves()
        case .timed:
            isGameOver = (gameState.timeRemaining ?? 0) <= 0
        case .moves:
            isGameOver = (gameState.movesRemaining ?? 0) <= 0 || !grid.hasValidMoves()
        case .multiplayer:
            // Handled by MultiplayerManager
            break
        }

        if isGameOver {
            endGame()
        }
    }

    /// End the current game
    func endGame() {
        gameTimer?.cancel()

        // Update high score
        if gameState.score > (highScores[gameMode] ?? 0) {
            highScores[gameMode] = gameState.score
            saveHighScores()
        }

        sounds.play(.gameOver)
        haptics.notification(type: .error)

        withAnimation(.easeInOut(duration: 0.5)) {
            appState = .gameOver
        }
    }

    /// Return to main menu
    func returnToMenu() {
        gameTimer?.cancel()
        gameState.resetCombo()

        withAnimation(.easeInOut(duration: 0.3)) {
            appState = .menu
        }
    }

    // MARK: - Timer

    private func startTimer() {
        gameTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if var time = self.gameState.timeRemaining {
                    time -= 1
                    self.gameState.timeRemaining = time

                    // Warning sounds when time is low
                    if time <= 10 && time > 0 {
                        self.sounds.play(.tick)
                    }

                    if time <= 0 {
                        self.endGame()
                    }
                }

                // Update freeze timer
                self.gameState.updateFreeze(deltaTime: 1.0)
            }
    }

    // MARK: - Persistence

    private func loadHighScores() {
        if let data = UserDefaults.standard.data(forKey: "highScores"),
           let scores = try? JSONDecoder().decode([String: Int].self, from: data) {
            for (key, value) in scores {
                if let mode = GameMode(rawValue: key) {
                    highScores[mode] = value
                }
            }
        }
    }

    private func saveHighScores() {
        var scores: [String: Int] = [:]
        for (mode, score) in highScores {
            scores[mode.rawValue] = score
        }
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: "highScores")
        }
    }

    /// Get high score for a mode
    func highScore(for mode: GameMode) -> Int {
        return highScores[mode] ?? 0
    }
}

/// Application states
enum AppState: Equatable {
    case menu
    case playing
    case gameOver
    case multiplayer
    case matchmaking
}
