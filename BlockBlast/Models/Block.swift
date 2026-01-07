//
//  Block.swift
//  BlockBlast
//

import SwiftUI

/// Represents a single block in the game grid
struct Block: Identifiable, Equatable, Codable {
    let id: UUID
    var color: BlockColor
    var row: Int
    var column: Int
    var isMatched: Bool = false
    var isAnimating: Bool = false

    init(id: UUID = UUID(), color: BlockColor, row: Int, column: Int) {
        self.id = id
        self.color = color
        self.row = row
        self.column = column
    }

    static func == (lhs: Block, rhs: Block) -> Bool {
        lhs.id == rhs.id
    }
}

/// Available block colors
enum BlockColor: Int, CaseIterable, Codable {
    case red = 0
    case blue = 1
    case green = 2
    case yellow = 3
    case purple = 4
    case orange = 5

    var color: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .blue: return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .green: return Color(red: 0.3, green: 0.9, blue: 0.4)
        case .yellow: return Color(red: 1.0, green: 0.9, blue: 0.3)
        case .purple: return Color(red: 0.7, green: 0.3, blue: 0.9)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }

    var highlightColor: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.5, blue: 0.5)
        case .blue: return Color(red: 0.5, green: 0.7, blue: 1.0)
        case .green: return Color(red: 0.5, green: 1.0, blue: 0.6)
        case .yellow: return Color(red: 1.0, green: 1.0, blue: 0.5)
        case .purple: return Color(red: 0.85, green: 0.5, blue: 1.0)
        case .orange: return Color(red: 1.0, green: 0.75, blue: 0.4)
        }
    }

    var shadowColor: Color {
        switch self {
        case .red: return Color(red: 0.6, green: 0.1, blue: 0.1)
        case .blue: return Color(red: 0.1, green: 0.2, blue: 0.6)
        case .green: return Color(red: 0.1, green: 0.5, blue: 0.2)
        case .yellow: return Color(red: 0.6, green: 0.5, blue: 0.1)
        case .purple: return Color(red: 0.4, green: 0.1, blue: 0.5)
        case .orange: return Color(red: 0.6, green: 0.3, blue: 0.1)
        }
    }

    static func random() -> BlockColor {
        BlockColor.allCases.randomElement()!
    }
}

/// Power-up types available in the game
enum PowerUpType: String, CaseIterable, Codable {
    case bomb = "bomb"           // Clears 3x3 area
    case lightning = "lightning" // Clears entire row
    case rainbow = "rainbow"     // Clears all blocks of one color
    case freeze = "freeze"       // Freezes opponent (multiplayer)
    case shuffle = "shuffle"     // Shuffles own board

    var icon: String {
        switch self {
        case .bomb: return "flame.fill"
        case .lightning: return "bolt.fill"
        case .rainbow: return "sparkles"
        case .freeze: return "snowflake"
        case .shuffle: return "shuffle"
        }
    }

    var color: Color {
        switch self {
        case .bomb: return .orange
        case .lightning: return .yellow
        case .rainbow: return .purple
        case .freeze: return .cyan
        case .shuffle: return .green
        }
    }
}
