//
//  MultiplayerGameView.swift
//  BlockBlast
//

import SwiftUI

struct MultiplayerGameView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager
    @State private var selectedPowerUp: PowerUpType?
    @State private var showResultOverlay: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700

            VStack(spacing: isCompact ? 8 : 16) {
                // Header with both players' scores
                scoresHeader

                // Game content
                if isCompact {
                    // Horizontal layout for smaller screens
                    HStack(spacing: 12) {
                        // Opponent's board (smaller)
                        opponentBoardView
                            .frame(maxWidth: geometry.size.width * 0.3)

                        // Player's board
                        playerBoardView
                    }
                } else {
                    // Vertical layout
                    VStack(spacing: 12) {
                        // Opponent's board (smaller)
                        opponentBoardView
                            .frame(maxHeight: geometry.size.height * 0.25)

                        // Player's board
                        playerBoardView
                    }
                }

                // Power-ups bar
                powerUpsBar

                Spacer(minLength: 0)
            }
            .padding()
        }
        .overlay(
            Group {
                if multiplayerManager.matchState == .won || multiplayerManager.matchState == .lost {
                    matchResultOverlay
                }
            }
        )
        .overlay(
            Group {
                if gameManager.gameState.isFrozen {
                    freezeOverlay
                }
            }
        )
        .onChange(of: gameManager.gameState.score) { _, newScore in
            multiplayerManager.sendScoreUpdate(newScore)
        }
    }

    // MARK: - Scores Header

    private var scoresHeader: some View {
        HStack {
            // Player score
            VStack(alignment: .leading, spacing: 4) {
                Text("YOU")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                Text("\(gameManager.gameState.score)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }

            Spacer()

            // VS indicator
            VStack(spacing: 2) {
                Text("VS")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.red)

                // Score difference indicator
                let scoreDiff = gameManager.gameState.score - multiplayerManager.opponentScore
                if scoreDiff != 0 {
                    Text(scoreDiff > 0 ? "+\(scoreDiff)" : "\(scoreDiff)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(scoreDiff > 0 ? .green : .red)
                }
            }

            Spacer()

            // Opponent score
            VStack(alignment: .trailing, spacing: 4) {
                Text(multiplayerManager.opponentName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .lineLimit(1)
                Text("\(multiplayerManager.opponentScore)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Player Board

    private var playerBoardView: some View {
        VStack(spacing: 8) {
            GameBoardView(
                grid: gameManager.grid,
                onBlockTap: handleBlockTap,
                selectedPowerUp: selectedPowerUp
            )
        }
    }

    // MARK: - Opponent Board

    private var opponentBoardView: some View {
        VStack(spacing: 4) {
            Text("Opponent's Board")
                .font(.caption2)
                .foregroundColor(.gray)

            if let opponentGrid = multiplayerManager.opponentGrid {
                GameBoardView(
                    grid: opponentGrid,
                    onBlockTap: { _, _ in },
                    isOpponentView: true,
                    scale: 0.6
                )
                .opacity(0.7)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Text("Waiting...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    // MARK: - Power-ups Bar

    private var powerUpsBar: some View {
        HStack(spacing: 12) {
            ForEach(PowerUpType.allCases, id: \.self) { powerUp in
                PowerUpButton(
                    type: powerUp,
                    count: gameManager.gameState.powerUps[powerUp] ?? 0,
                    isSelected: selectedPowerUp == powerUp
                ) {
                    if powerUp == .freeze {
                        // Freeze directly affects opponent
                        if gameManager.gameState.usePowerUp(.freeze) {
                            multiplayerManager.sendFreeze()
                            HapticsManager.shared.notification(type: .success)
                            SoundManager.shared.play(.powerUp)
                        }
                    } else if selectedPowerUp == powerUp {
                        selectedPowerUp = nil
                    } else if (gameManager.gameState.powerUps[powerUp] ?? 0) > 0 {
                        selectedPowerUp = powerUp
                        HapticsManager.shared.impact(style: .light)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Freeze Overlay

    private var freezeOverlay: some View {
        ZStack {
            Color.cyan.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                Image(systemName: "snowflake")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                Text("FROZEN!")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text(String(format: "%.1fs", gameManager.gameState.frozenTimeRemaining))
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Match Result Overlay

    private var matchResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Result
                if multiplayerManager.matchState == .won {
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                        Text("VICTORY!")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.yellow)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                        Text("DEFEAT")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.red)
                    }
                }

                // Final scores
                HStack(spacing: 40) {
                    VStack {
                        Text("YOU")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(gameManager.gameState.score)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                    Text("vs")
                        .foregroundColor(.gray)

                    VStack {
                        Text(multiplayerManager.opponentName)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(multiplayerManager.opponentScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        multiplayerManager.disconnect()
                        gameManager.appState = .matchmaking
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("FIND NEW MATCH")
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        multiplayerManager.disconnect()
                        gameManager.returnToMenu()
                    } label: {
                        Text("Main Menu")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func handleBlockTap(row: Int, column: Int) {
        if let powerUp = selectedPowerUp {
            gameManager.usePowerUp(powerUp, at: row, column: column)
            selectedPowerUp = nil
        } else {
            gameManager.handleTap(at: row, column: column)
        }
    }
}

#Preview {
    MultiplayerGameView()
        .environmentObject(GameManager())
        .environmentObject(MultiplayerManager())
        .preferredColorScheme(.dark)
}
