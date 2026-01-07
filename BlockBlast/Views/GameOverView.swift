//
//  GameOverView.swift
//  BlockBlast
//

import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showStats: Bool = false
    @State private var animateScore: Bool = false

    private var isNewHighScore: Bool {
        gameManager.gameState.score >= (gameManager.highScores[gameManager.gameMode] ?? 0)
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Game Over Title
            VStack(spacing: 8) {
                Text("GAME OVER")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if isNewHighScore {
                    Text("NEW HIGH SCORE!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 10)
                        .scaleEffect(animateScore ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateScore)
                }
            }

            // Score display
            VStack(spacing: 16) {
                // Final Score
                VStack(spacing: 4) {
                    Text("FINAL SCORE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(gameManager.gameState.score)")
                        .font(.system(size: 60, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .gray],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Stats Grid
                HStack(spacing: 40) {
                    StatItem(title: "Level", value: "\(gameManager.gameState.level)", icon: "star.fill", color: .yellow)
                    StatItem(title: "Cleared", value: "\(gameManager.gameState.blocksCleared)", icon: "cube.fill", color: .mint)
                    StatItem(title: "Best Combo", value: "\(gameManager.gameState.combo)x", icon: "flame.fill", color: .orange)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Spacer()

            // Action Buttons
            VStack(spacing: 16) {
                // Play Again
                Button {
                    gameManager.startGame(mode: gameManager.gameMode, difficulty: gameManager.difficulty)
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("PLAY AGAIN")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Main Menu
                Button {
                    gameManager.returnToMenu()
                } label: {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("MAIN MENU")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Share Score
                Button {
                    shareScore()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("SHARE")
                            .fontWeight(.bold)
                    }
                    .font(.callout)
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear {
            animateScore = true
        }
    }

    private func shareScore() {
        let text = "I scored \(gameManager.gameState.score) points in Block Blast! Can you beat my score?"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    let gameManager = GameManager()
    gameManager.gameState.score = 12500
    gameManager.gameState.level = 5
    gameManager.gameState.blocksCleared = 234
    gameManager.gameState.combo = 8

    return GameOverView()
        .environmentObject(gameManager)
        .preferredColorScheme(.dark)
}
