//
//  GameGrid.swift
//  BlockBlast
//

import Foundation

/// Manages the game grid and block operations
class GameGrid: ObservableObject, Codable {
    @Published var blocks: [[Block?]]
    @Published var isProcessing: Bool = false

    let rows: Int
    let columns: Int

    private var colorCount: Int

    enum CodingKeys: String, CodingKey {
        case blocks, rows, columns, colorCount
    }

    init(rows: Int = 10, columns: Int = 8, colorCount: Int = 5) {
        self.rows = rows
        self.columns = columns
        self.colorCount = min(colorCount, BlockColor.allCases.count)
        self.blocks = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        fillGrid()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rows = try container.decode(Int.self, forKey: .rows)
        columns = try container.decode(Int.self, forKey: .columns)
        colorCount = try container.decode(Int.self, forKey: .colorCount)
        blocks = try container.decode([[Block?]].self, forKey: .blocks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rows, forKey: .rows)
        try container.encode(columns, forKey: .columns)
        try container.encode(colorCount, forKey: .colorCount)
        try container.encode(blocks, forKey: .blocks)
    }

    /// Fill the entire grid with random blocks
    func fillGrid() {
        for row in 0..<rows {
            for col in 0..<columns {
                blocks[row][col] = createRandomBlock(at: row, column: col)
            }
        }
    }

    /// Create a random block at specified position
    private func createRandomBlock(at row: Int, column: Int) -> Block {
        let availableColors = Array(BlockColor.allCases.prefix(colorCount))
        let color = availableColors.randomElement()!
        return Block(color: color, row: row, column: column)
    }

    /// Get block at position
    func block(at row: Int, column: Int) -> Block? {
        guard isValidPosition(row: row, column: column) else { return nil }
        return blocks[row][column]
    }

    /// Check if position is valid
    func isValidPosition(row: Int, column: Int) -> Bool {
        row >= 0 && row < rows && column >= 0 && column < columns
    }

    /// Find all connected blocks of the same color
    func findConnectedBlocks(from row: Int, column: Int) -> Set<Position> {
        guard let startBlock = block(at: row, column: column) else { return [] }

        var visited = Set<Position>()
        var toVisit = [Position(row: row, column: column)]
        let targetColor = startBlock.color

        while !toVisit.isEmpty {
            let current = toVisit.removeFirst()

            guard !visited.contains(current),
                  isValidPosition(row: current.row, column: current.column),
                  let block = self.block(at: current.row, column: current.column),
                  block.color == targetColor else {
                continue
            }

            visited.insert(current)

            // Add adjacent positions
            let neighbors = [
                Position(row: current.row - 1, column: current.column),
                Position(row: current.row + 1, column: current.column),
                Position(row: current.row, column: current.column - 1),
                Position(row: current.row, column: current.column + 1)
            ]

            toVisit.append(contentsOf: neighbors.filter { !visited.contains($0) })
        }

        return visited
    }

    /// Remove blocks at specified positions
    func removeBlocks(at positions: Set<Position>) {
        for position in positions {
            blocks[position.row][position.column] = nil
        }
    }

    /// Apply gravity - blocks fall down to fill empty spaces
    func applyGravity() -> [(from: Position, to: Position)] {
        var movements: [(from: Position, to: Position)] = []

        for col in 0..<columns {
            var writeRow = rows - 1

            for readRow in stride(from: rows - 1, through: 0, by: -1) {
                if var block = blocks[readRow][col] {
                    if readRow != writeRow {
                        let fromPos = Position(row: readRow, column: col)
                        let toPos = Position(row: writeRow, column: col)
                        movements.append((from: fromPos, to: toPos))

                        block.row = writeRow
                        blocks[writeRow][col] = block
                        blocks[readRow][col] = nil
                    }
                    writeRow -= 1
                }
            }
        }

        return movements
    }

    /// Fill empty spaces at top with new blocks
    func fillEmptySpaces() -> [Position] {
        var newBlockPositions: [Position] = []

        for col in 0..<columns {
            for row in 0..<rows {
                if blocks[row][col] == nil {
                    blocks[row][col] = createRandomBlock(at: row, column: col)
                    newBlockPositions.append(Position(row: row, column: col))
                }
            }
        }

        return newBlockPositions
    }

    /// Check if any valid moves exist (groups of 2+ blocks)
    func hasValidMoves() -> Bool {
        for row in 0..<rows {
            for col in 0..<columns {
                let connected = findConnectedBlocks(from: row, column: col)
                if connected.count >= 2 {
                    return true
                }
            }
        }
        return false
    }

    /// Clear blocks in a 3x3 area (bomb power-up)
    func clearArea(centerRow: Int, centerColumn: Int, radius: Int = 1) -> Set<Position> {
        var cleared = Set<Position>()

        for row in (centerRow - radius)...(centerRow + radius) {
            for col in (centerColumn - radius)...(centerColumn + radius) {
                if isValidPosition(row: row, column: col) && blocks[row][col] != nil {
                    cleared.insert(Position(row: row, column: col))
                }
            }
        }

        removeBlocks(at: cleared)
        return cleared
    }

    /// Clear entire row (lightning power-up)
    func clearRow(_ row: Int) -> Set<Position> {
        var cleared = Set<Position>()

        guard row >= 0 && row < rows else { return cleared }

        for col in 0..<columns {
            if blocks[row][col] != nil {
                cleared.insert(Position(row: row, column: col))
            }
        }

        removeBlocks(at: cleared)
        return cleared
    }

    /// Clear all blocks of a specific color (rainbow power-up)
    func clearColor(_ color: BlockColor) -> Set<Position> {
        var cleared = Set<Position>()

        for row in 0..<rows {
            for col in 0..<columns {
                if let block = blocks[row][col], block.color == color {
                    cleared.insert(Position(row: row, column: col))
                }
            }
        }

        removeBlocks(at: cleared)
        return cleared
    }

    /// Shuffle all blocks on the grid
    func shuffleBlocks() {
        var allBlocks: [Block] = []

        // Collect all blocks
        for row in 0..<rows {
            for col in 0..<columns {
                if let block = blocks[row][col] {
                    allBlocks.append(block)
                }
            }
        }

        // Shuffle
        allBlocks.shuffle()

        // Redistribute
        var index = 0
        for row in 0..<rows {
            for col in 0..<columns {
                if index < allBlocks.count {
                    var block = allBlocks[index]
                    block.row = row
                    block.column = col
                    blocks[row][col] = block
                    index += 1
                }
            }
        }
    }

    /// Create a copy of the grid state for multiplayer sync
    func snapshot() -> [[Block?]] {
        return blocks
    }

    /// Restore grid from snapshot
    func restore(from snapshot: [[Block?]]) {
        self.blocks = snapshot
    }
}

/// Represents a position on the grid
struct Position: Hashable, Codable {
    let row: Int
    let column: Int
}
