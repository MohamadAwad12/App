//
//  MatchmakingView.swift
//  BlockBlast
//

import SwiftUI

struct MatchmakingView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var multiplayerManager: MultiplayerManager
    @State private var pulseAnimation: Bool = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Title
            VStack(spacing: 8) {
                Text("MULTIPLAYER")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if !multiplayerManager.isAuthenticated {
                    Text("Sign in to Game Center to play")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Status indicator
            statusView

            // Error message
            if let error = multiplayerManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Action buttons
            actionButtons

            Spacer()
        }
        .padding()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Status View

    @ViewBuilder
    private var statusView: some View {
        switch multiplayerManager.matchState {
        case .idle:
            VStack(spacing: 20) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)

                Text("Ready to battle?")
                    .font(.title3)
                    .foregroundColor(.gray)
            }

        case .searching:
            VStack(spacing: 20) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                        .frame(width: 100, height: 100)

                    // Spinning ring
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(rotationAngle))

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("Finding opponent...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("This may take a moment")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

        case .playing:
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Match found!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("vs \(multiplayerManager.opponentName)")
                    .font(.title3)
                    .foregroundColor(.orange)
            }

        case .won, .lost:
            EmptyView()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            if multiplayerManager.matchState == .idle {
                // Quick Match
                Button {
                    multiplayerManager.findMatch()
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("QUICK MATCH")
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
                }
                .disabled(!multiplayerManager.isAuthenticated)
                .opacity(multiplayerManager.isAuthenticated ? 1.0 : 0.5)

                // Game Center Matchmaker
                Button {
                    multiplayerManager.presentMatchmaker()
                } label: {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                        Text("GAME CENTER")
                            .fontWeight(.bold)
                    }
                    .font(.callout)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!multiplayerManager.isAuthenticated)
                .opacity(multiplayerManager.isAuthenticated ? 1.0 : 0.5)

            } else if multiplayerManager.matchState == .searching {
                // Cancel
                Button {
                    multiplayerManager.cancelMatchmaking()
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("CANCEL")
                            .fontWeight(.bold)
                    }
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            // Back button
            Button {
                multiplayerManager.cancelMatchmaking()
                gameManager.returnToMenu()
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back to Menu")
                }
                .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }

        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

#Preview {
    MatchmakingView()
        .environmentObject(GameManager())
        .environmentObject(MultiplayerManager())
        .preferredColorScheme(.dark)
}
