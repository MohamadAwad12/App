//
//  GameView.swift
//  BlockBlast
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showPauseMenu: Bool = false
    @State private var selectedPowerUp: PowerUpType?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                // Header with score and controls
                headerView

                // Game status (time/moves remaining)
                statusBar

                Spacer()

                // Game Board
                GameBoardView(
                    grid: gameManager.grid,
                    onBlockTap: handleBlockTap,
                    selectedPowerUp: selectedPowerUp
                )
                .padding(.horizontal, 8)

                Spacer()

                // Power-ups bar
                powerUpsBar

                // Combo indicator
                if gameManager.gameState.combo > 1 {
                    comboIndicator
                }
            }
            .padding()
            .overlay(
                // Freeze overlay
                Group {
                    if gameManager.gameState.isFrozen {
                        freezeOverlay
                    }
                }
            )
            .overlay(
                // Score popup
                Group {
                    if gameManager.lastScoreGained > 0 && gameManager.isAnimating {
                        scorePopup
                    }
                }
            )
            .sheet(isPresented: $showPauseMenu) {
                PauseMenuView(showPauseMenu: $showPauseMenu)
                    .environmentObject(gameManager)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Back button
            Button {
                showPauseMenu = true
            } label: {
                Image(systemName: "pause.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            // Score
            VStack(spacing: 2) {
                Text("SCORE")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(gameManager.gameState.score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()

            // Level
            VStack(spacing: 2) {
                Text("LEVEL")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(gameManager.gameState.level)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 20) {
            // Mode-specific indicator
            switch gameManager.gameMode {
            case .timed:
                if let time = gameManager.gameState.timeRemaining {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(time <= 10 ? .red : .orange)
                        Text(formatTime(time))
                            .fontWeight(.bold)
                            .foregroundColor(time <= 10 ? .red : .white)
                    }
                    .font(.title3)
                }

            case .moves:
                if let moves = gameManager.gameState.movesRemaining {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundColor(.blue)
                        Text("\(moves) moves")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .font(.title3)
                }

            case .endless:
                HStack(spacing: 6) {
                    Image(systemName: "infinity")
                        .foregroundColor(.purple)
                    Text("Endless")
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                }
                .font(.subheadline)

            case .multiplayer:
                EmptyView()
            }

            Spacer()

            // Blocks cleared
            HStack(spacing: 4) {
                Image(systemName: "cube.fill")
                    .foregroundColor(.mint)
                Text("\(gameManager.gameState.blocksCleared)")
                    .foregroundColor(.white)
            }
            .font(.subheadline)
        }
        .padding(.horizontal)
    }

    // MARK: - Power-ups Bar

    private var powerUpsBar: some View {
        HStack(spacing: 16) {
            ForEach(PowerUpType.allCases.filter { $0 != .freeze }, id: \.self) { powerUp in
                PowerUpButton(
                    type: powerUp,
                    count: gameManager.gameState.powerUps[powerUp] ?? 0,
                    isSelected: selectedPowerUp == powerUp
                ) {
                    if selectedPowerUp == powerUp {
                        selectedPowerUp = nil
                    } else if (gameManager.gameState.powerUps[powerUp] ?? 0) > 0 {
                        selectedPowerUp = powerUp
                        HapticsManager.shared.impact(style: .light)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Combo Indicator

    private var comboIndicator: some View {
        Text("\(gameManager.gameState.combo)x COMBO!")
            .font(.title2)
            .fontWeight(.black)
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .orange.opacity(0.5), radius: 5)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Freeze Overlay

    private var freezeOverlay: some View {
        ZStack {
            Color.cyan.opacity(0.3)
                .ignoresSafeArea()

            VStack {
                Image(systemName: "snowflake")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                Text("FROZEN!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text(String(format: "%.1f", gameManager.gameState.frozenTimeRemaining))
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Score Popup

    private var scorePopup: some View {
        Text("+\(gameManager.lastScoreGained)")
            .font(.title)
            .fontWeight(.black)
            .foregroundColor(.yellow)
            .shadow(color: .black, radius: 2)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.5).combined(with: .opacity),
                removal: .opacity.combined(with: .move(edge: .top))
            ))
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

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Power-up Button

struct PowerUpButton: View {
    let type: PowerUpType
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        count > 0 ?
                        LinearGradient(colors: [type.color, type.color.opacity(0.6)], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: isSelected ? type.color.opacity(0.5) : .clear, radius: 8)

                VStack(spacing: 2) {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(count == 0)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Pause Menu

struct PauseMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @Binding var showPauseMenu: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)

                VStack(spacing: 8) {
                    Text("Score: \(gameManager.gameState.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text("Level: \(gameManager.gameState.level)")
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                VStack(spacing: 16) {
                    Button {
                        showPauseMenu = false
                    } label: {
                        Text("RESUME")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showPauseMenu = false
                        gameManager.returnToMenu()
                    } label: {
                        Text("QUIT")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    GameView()
        .environmentObject(GameManager())
        .preferredColorScheme(.dark)
}
