//
//  ContentView.swift
//  BlockBlast
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main content based on game state
            switch gameManager.appState {
            case .menu:
                MainMenuView()
                    .transition(.opacity)
            case .playing:
                GameView()
                    .transition(.opacity)
            case .gameOver:
                GameOverView()
                    .transition(.opacity)
            case .multiplayer:
                MultiplayerGameView()
                    .transition(.opacity)
            case .matchmaking:
                MatchmakingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: gameManager.appState)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameManager())
        .environmentObject(MultiplayerManager())
}
