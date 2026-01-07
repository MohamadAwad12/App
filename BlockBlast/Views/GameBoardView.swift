//
//  GameBoardView.swift
//  BlockBlast
//

import SwiftUI

struct GameBoardView: View {
    @ObservedObject var grid: GameGrid
    let onBlockTap: (Int, Int) -> Void
    var selectedPowerUp: PowerUpType?
    var isOpponentView: Bool = false
    var scale: CGFloat = 1.0

    @State private var highlightedPositions: Set<Position> = []

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let blockSize = min(
                availableWidth / CGFloat(grid.columns),
                availableHeight / CGFloat(grid.rows)
            ) * scale

            let gridWidth = blockSize * CGFloat(grid.columns)
            let gridHeight = blockSize * CGFloat(grid.rows)

            ZStack {
                // Grid background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: gridWidth + 16, height: gridHeight + 16)

                // Blocks
                VStack(spacing: 0) {
                    ForEach(0..<grid.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<grid.columns, id: \.self) { column in
                                blockCell(row: row, column: column, size: blockSize)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(CGFloat(grid.columns) / CGFloat(grid.rows), contentMode: .fit)
    }

    @ViewBuilder
    private func blockCell(row: Int, column: Int, size: CGFloat) -> some View {
        let position = Position(row: row, column: column)
        let isHighlighted = highlightedPositions.contains(position)

        ZStack {
            if let block = grid.blocks[row][column] {
                BlockView(
                    block: block,
                    size: size,
                    isHighlighted: isHighlighted,
                    isMatched: block.isMatched
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                    removal: .scale(scale: 1.5).combined(with: .opacity)
                ))
                .onTapGesture {
                    guard !isOpponentView else { return }
                    handleTap(row: row, column: column)
                }
                .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                    if pressing && !isOpponentView {
                        showPreview(row: row, column: column)
                    } else {
                        clearPreview()
                    }
                }, perform: {})
            } else {
                Color.clear
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }

    private func handleTap(row: Int, column: Int) {
        clearPreview()
        onBlockTap(row, column)
    }

    private func showPreview(row: Int, column: Int) {
        let connected = grid.findConnectedBlocks(from: row, column: column)
        if connected.count >= 2 {
            withAnimation(.easeInOut(duration: 0.2)) {
                highlightedPositions = connected
            }
        }
    }

    private func clearPreview() {
        withAnimation(.easeOut(duration: 0.15)) {
            highlightedPositions = []
        }
    }
}

// MARK: - Block View

struct BlockView: View {
    let block: Block
    let size: CGFloat
    var isHighlighted: Bool = false
    var isMatched: Bool = false

    @State private var animationPhase: Double = 0

    var body: some View {
        ZStack {
            // Shadow layer
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(block.color.shadowColor)
                .frame(width: size - 4, height: size - 4)
                .offset(y: 3)

            // Main block
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(
                    LinearGradient(
                        colors: [
                            isHighlighted ? block.color.highlightColor : block.color.color,
                            block.color.color.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size - 4, height: size - 4)

            // Shine effect
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size - 6, height: size - 6)

            // Highlight glow
            if isHighlighted {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: size - 4, height: size - 4)
                    .shadow(color: .white.opacity(0.5), radius: 5)
            }
        }
        .scaleEffect(isMatched ? 1.3 : (isHighlighted ? 1.08 : 1.0))
        .opacity(isMatched ? 0 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHighlighted)
        .animation(.easeOut(duration: 0.2), value: isMatched)
    }
}

// MARK: - Preview

#Preview {
    let grid = GameGrid(rows: 10, columns: 8, colorCount: 5)

    return GameBoardView(
        grid: grid,
        onBlockTap: { _, _ in }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
