//
//  MultiplayerManager.swift
//  BlockBlast
//

import SwiftUI
import GameKit
import Combine

/// Manages GameKit multiplayer functionality
class MultiplayerManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isAuthenticated: Bool = false
    @Published var currentMatch: GKMatch?
    @Published var opponentName: String = "Opponent"
    @Published var opponentScore: Int = 0
    @Published var opponentGrid: GameGrid?
    @Published var matchState: MatchState = .idle
    @Published var errorMessage: String?
    @Published var localPlayerScore: Int = 0

    // MARK: - Private Properties

    private var localPlayer: GKLocalPlayer { GKLocalPlayer.local }
    private weak var gameManager: GameManager?
    private var matchStartTime: Date?

    // MARK: - Message Types

    enum MessageType: UInt8 {
        case gridUpdate = 1
        case scoreUpdate = 2
        case powerUpUsed = 3
        case freezeOpponent = 4
        case gameOver = 5
    }

    struct GameMessage: Codable {
        let type: UInt8
        let score: Int?
        let gridData: Data?
        let powerUpType: String?
        let timestamp: TimeInterval
    }

    // MARK: - Initialization

    override init() {
        super.init()
        authenticatePlayer()
    }

    func setGameManager(_ manager: GameManager) {
        self.gameManager = manager
    }

    // MARK: - Authentication

    /// Authenticate the local player with Game Center
    func authenticatePlayer() {
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Game Center Error: \(error.localizedDescription)"
                    self?.isAuthenticated = false
                    return
                }

                if viewController != nil {
                    // Present the Game Center login view controller
                    // In a real app, you'd present this from the root view controller
                    self?.isAuthenticated = false
                } else if self?.localPlayer.isAuthenticated == true {
                    self?.isAuthenticated = true
                    self?.errorMessage = nil
                }
            }
        }
    }

    // MARK: - Matchmaking

    /// Start looking for a match
    func findMatch() {
        guard isAuthenticated else {
            errorMessage = "Please sign in to Game Center"
            return
        }

        matchState = .searching

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Matchmaking Error: \(error.localizedDescription)"
                    self?.matchState = .idle
                    return
                }

                guard let match = match else {
                    self?.matchState = .idle
                    return
                }

                self?.currentMatch = match
                match.delegate = self
                self?.startMultiplayerGame(with: match)
            }
        }
    }

    /// Cancel matchmaking
    func cancelMatchmaking() {
        GKMatchmaker.shared().cancel()
        matchState = .idle
    }

    /// Present Game Center matchmaker UI
    func presentMatchmaker(from viewController: UIViewController? = nil) {
        guard isAuthenticated else {
            errorMessage = "Please sign in to Game Center"
            return
        }

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2

        let matchmakerVC = GKMatchmakerViewController(matchRequest: request)
        matchmakerVC?.matchmakerDelegate = self

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(matchmakerVC!, animated: true)
        }
    }

    // MARK: - Game Session

    /// Start a multiplayer game with the matched opponent
    private func startMultiplayerGame(with match: GKMatch) {
        matchState = .playing
        matchStartTime = Date()

        // Get opponent name
        if let opponent = match.players.first {
            opponentName = opponent.displayName
        }

        // Initialize opponent grid
        let size = Difficulty.medium.gridSize
        opponentGrid = GameGrid(rows: size.rows, columns: size.columns, colorCount: Difficulty.medium.colorCount)

        // Notify game manager
        DispatchQueue.main.async { [weak self] in
            self?.gameManager?.appState = .multiplayer
        }
    }

    /// Send local score update to opponent
    func sendScoreUpdate(_ score: Int) {
        localPlayerScore = score
        let message = GameMessage(
            type: MessageType.scoreUpdate.rawValue,
            score: score,
            gridData: nil,
            powerUpType: nil,
            timestamp: Date().timeIntervalSince1970
        )
        sendMessage(message)
    }

    /// Send grid state to opponent
    func sendGridUpdate(_ grid: GameGrid) {
        guard let gridData = try? JSONEncoder().encode(grid) else { return }

        let message = GameMessage(
            type: MessageType.gridUpdate.rawValue,
            score: nil,
            gridData: gridData,
            powerUpType: nil,
            timestamp: Date().timeIntervalSince1970
        )
        sendMessage(message)
    }

    /// Send freeze power-up to opponent
    func sendFreeze() {
        let message = GameMessage(
            type: MessageType.freezeOpponent.rawValue,
            score: nil,
            gridData: nil,
            powerUpType: PowerUpType.freeze.rawValue,
            timestamp: Date().timeIntervalSince1970
        )
        sendMessage(message)
    }

    /// Send game over notification
    func sendGameOver(finalScore: Int) {
        let message = GameMessage(
            type: MessageType.gameOver.rawValue,
            score: finalScore,
            gridData: nil,
            powerUpType: nil,
            timestamp: Date().timeIntervalSince1970
        )
        sendMessage(message)
    }

    /// Send a message to all players
    private func sendMessage(_ message: GameMessage) {
        guard let match = currentMatch,
              let data = try? JSONEncoder().encode(message) else { return }

        do {
            try match.sendData(toAllPlayers: data, with: .reliable)
        } catch {
            print("Failed to send message: \(error)")
        }
    }

    /// End the current match
    func endMatch(won: Bool) {
        matchState = won ? .won : .lost

        // Report score to leaderboard
        if isAuthenticated {
            let score = GKLeaderboardScore()
            score.leaderboardID = "blockblast_multiplayer"
            score.value = localPlayerScore
            GKLeaderboard.submitScore(localPlayerScore, context: 0, player: localPlayer, leaderboardIDs: ["blockblast_multiplayer"]) { error in
                if let error = error {
                    print("Failed to submit score: \(error)")
                }
            }
        }

        // Disconnect after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.currentMatch?.disconnect()
            self?.currentMatch = nil
            self?.matchState = .idle
        }
    }

    /// Disconnect from current match
    func disconnect() {
        currentMatch?.disconnect()
        currentMatch = nil
        matchState = .idle
    }

    // MARK: - Leaderboards & Achievements

    /// Show Game Center leaderboards
    func showLeaderboard() {
        guard isAuthenticated else { return }

        let gcVC = GKGameCenterViewController(state: .leaderboards)
        gcVC.gameCenterDelegate = self

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(gcVC, animated: true)
        }
    }

    /// Report an achievement
    func reportAchievement(_ identifier: String, progress: Double = 100.0) {
        guard isAuthenticated else { return }

        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = progress
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to report achievement: \(error)")
            }
        }
    }
}

// MARK: - GKMatchDelegate

extension MultiplayerManager: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        guard let message = try? JSONDecoder().decode(GameMessage.self, from: data) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedMessage(message, from: player)
        }
    }

    private func handleReceivedMessage(_ message: GameMessage, from player: GKPlayer) {
        guard let type = MessageType(rawValue: message.type) else { return }

        switch type {
        case .scoreUpdate:
            if let score = message.score {
                opponentScore = score
            }

        case .gridUpdate:
            if let gridData = message.gridData,
               let grid = try? JSONDecoder().decode(GameGrid.self, from: gridData) {
                opponentGrid = grid
            }

        case .powerUpUsed:
            // Show opponent used a power-up
            break

        case .freezeOpponent:
            // Opponent used freeze on us
            gameManager?.gameState.applyFreeze()
            HapticsManager.shared.notification(type: .warning)
            SoundManager.shared.play(.freeze)

        case .gameOver:
            if let score = message.score {
                opponentScore = score
                // Determine winner
                let won = localPlayerScore > opponentScore
                endMatch(won: won)
            }
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                self?.opponentName = player.displayName
            case .disconnected:
                self?.errorMessage = "\(player.displayName) disconnected"
                self?.endMatch(won: true)
            default:
                break
            }
        }
    }

    func match(_ match: GKMatch, didFailWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error?.localizedDescription ?? "Match failed"
            self?.matchState = .idle
            self?.disconnect()
        }
    }
}

// MARK: - GKMatchmakerViewControllerDelegate

extension MultiplayerManager: GKMatchmakerViewControllerDelegate {
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        viewController.dismiss(animated: true)
        currentMatch = match
        match.delegate = self
        startMultiplayerGame(with: match)
    }

    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
        viewController.dismiss(animated: true)
        matchState = .idle
    }

    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(animated: true)
        errorMessage = error.localizedDescription
        matchState = .idle
    }
}

// MARK: - GKGameCenterControllerDelegate

extension MultiplayerManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - Match State

enum MatchState: Equatable {
    case idle
    case searching
    case playing
    case won
    case lost
}
