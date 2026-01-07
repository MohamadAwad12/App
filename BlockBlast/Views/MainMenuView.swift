//
//  MainMenuView.swift
//  BlockBlast
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager
    @State private var selectedMode: GameMode = .endless
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var showSettings: Bool = false
    @State private var animateTitle: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Title
            titleView

            Spacer()

            // Game Mode Selection
            gameModeSelector

            // Difficulty Selection
            difficultySelector

            // Play Button
            playButton

            // Multiplayer Button
            multiplayerButton

            Spacer()

            // Bottom buttons
            bottomButtons
        }
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateTitle = true
            }
        }
    }

    private var titleView: some View {
        VStack(spacing: 10) {
            Text("BLOCK")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                .scaleEffect(animateTitle ? 1.05 : 1.0)

            Text("BLAST")
                .font(.system(size: 60, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 5)
                .scaleEffect(animateTitle ? 1.0 : 1.05)

            Text("Multiplayer Edition")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    private var gameModeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GAME MODE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GameMode.allCases.filter { $0 != .multiplayer }, id: \.self) { mode in
                        GameModeButton(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            highScore: gameManager.highScore(for: mode)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMode = mode
                            }
                            HapticsManager.shared.impact(style: .light)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var difficultySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DIFFICULTY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        difficulty: difficulty,
                        isSelected: selectedDifficulty == difficulty
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = difficulty
                        }
                        HapticsManager.shared.impact(style: .light)
                    }
                }
            }
        }
    }

    private var playButton: some View {
        Button {
            gameManager.startGame(mode: selectedMode, difficulty: selectedDifficulty)
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("PLAY")
                    .fontWeight(.bold)
            }
            .font(.title2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
    }

    private var multiplayerButton: some View {
        Button {
            if multiplayerManager.isAuthenticated {
                gameManager.appState = .matchmaking
            } else {
                multiplayerManager.authenticatePlayer()
            }
        } label: {
            HStack {
                Image(systemName: "person.2.fill")
                Text(multiplayerManager.isAuthenticated ? "MULTIPLAYER" : "SIGN IN TO PLAY")
                    .fontWeight(.bold)
            }
            .font(.title3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }

    private var bottomButtons: some View {
        HStack(spacing: 30) {
            // Leaderboard
            Button {
                multiplayerManager.showLeaderboard()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                    Text("Ranks")
                        .font(.caption)
                }
                .foregroundColor(.yellow)
            }
            .disabled(!multiplayerManager.isAuthenticated)
            .opacity(multiplayerManager.isAuthenticated ? 1.0 : 0.5)

            // Settings
            Button {
                showSettings = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                    Text("Settings")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }

            // How to Play
            Button {
                // Show tutorial
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                    Text("Help")
                        .font(.caption)
                }
                .foregroundColor(.gray)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Game Mode Button

struct GameModeButton: View {
    let mode: GameMode
    let isSelected: Bool
    let highScore: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .gray)

                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .gray)

                if highScore > 0 {
                    Text("Best: \(highScore)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .gray.opacity(0.7))
                }
            }
            .frame(width: 90, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Difficulty Button

struct DifficultyButton: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    private var color: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }

    var body: some View {
        Button(action: action) {
            Text(difficulty.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? color : Color.gray.opacity(0.2))
                )
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameManager())
        .environmentObject(MultiplayerManager())
        .preferredColorScheme(.dark)
}
