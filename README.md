# Block Blast - Multiplayer iOS Game

A fun and addictive multiplayer block-matching puzzle game built with SwiftUI and GameKit.

## Features

### Game Modes
- **Endless Mode**: Play until no valid moves remain
- **Timed Mode**: Score as high as possible in 2 minutes
- **Limited Moves**: Clear blocks strategically in 30 moves
- **Multiplayer**: Real-time 1v1 battles via Game Center

### Gameplay
- Tap groups of 2 or more same-colored blocks to clear them
- Blocks fall down to fill gaps, new blocks spawn from top
- Build combos by clearing blocks in quick succession
- Earn power-ups by clearing large groups

### Power-ups
- **Bomb** 💥: Clears a 3x3 area
- **Lightning** ⚡: Clears an entire row
- **Rainbow** ✨: Clears all blocks of one color
- **Shuffle** 🔀: Shuffles your board
- **Freeze** ❄️: Freezes opponent (multiplayer only)

### Difficulty Levels
- **Easy**: 4 colors, 8x6 grid
- **Medium**: 5 colors, 10x8 grid
- **Hard**: 6 colors, 10x8 grid
- **Expert**: 6 colors, 12x10 grid

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Game Center account (for multiplayer)

## Project Structure

```
BlockBlast/
├── BlockBlastApp.swift      # App entry point
├── ContentView.swift        # Main navigation view
├── Models/
│   ├── Block.swift          # Block and color definitions
│   ├── GameGrid.swift       # Grid management and logic
│   └── GameState.swift      # Score, level, power-ups
├── Views/
│   ├── MainMenuView.swift   # Main menu UI
│   ├── GameView.swift       # Single-player game screen
│   ├── GameBoardView.swift  # Block grid rendering
│   ├── GameOverView.swift   # Game over screen
│   ├── MultiplayerGameView.swift  # Multiplayer game screen
│   └── MatchmakingView.swift      # Finding opponents
├── ViewModels/
│   └── GameManager.swift    # Game state management
├── Multiplayer/
│   └── MultiplayerManager.swift  # GameKit integration
├── Utilities/
│   ├── HapticsManager.swift # Haptic feedback
│   └── SoundManager.swift   # Sound effects
└── Assets.xcassets/         # App icons and colors
```

## Setup

1. Open `BlockBlast.xcodeproj` in Xcode
2. Select your development team in project settings
3. Update the bundle identifier if needed
4. Build and run on a device or simulator

## Game Center Setup

To enable multiplayer functionality:

1. Enable Game Center capability in Xcode
2. Create a Game Center group in App Store Connect
3. Add leaderboard with ID: `blockblast_multiplayer`
4. Configure match rules for 2-player matches

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clean separation of concerns
- **GameKit**: Apple's multiplayer gaming framework
- **Combine**: Reactive state management

## Customization

### Adding New Block Colors
Edit `BlockColor` enum in `Block.swift` to add new colors.

### Adjusting Difficulty
Modify `Difficulty` enum in `GameState.swift` to change grid sizes and color counts.

### Adding Sound Effects
Place audio files in bundle and register them in `SoundManager.swift`.

## License

MIT License - feel free to use this code for learning or your own projects!
