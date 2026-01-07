//
//  BlockBlastApp.swift
//  BlockBlast
//
//  A Multiplayer Block Blast iOS Game
//

import SwiftUI

@main
struct BlockBlastApp: App {
    @StateObject private var gameManager = GameManager()
    @StateObject private var multiplayerManager = MultiplayerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .environmentObject(multiplayerManager)
                .preferredColorScheme(.dark)
        }
    }
}
