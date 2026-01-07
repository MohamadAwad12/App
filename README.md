# Block Blast - Multiplayer Web Game

A fun and addictive multiplayer block-matching puzzle game that runs in any browser.

## Play Now

Simply open `index.html` in your browser to play!

Or start a local server:
```bash
# Using Python
python -m http.server 8000

# Using Node.js
npx serve
```

Then open http://localhost:8000

## Features

### Game Modes
- **Endless**: Play until no valid moves remain
- **Timed**: Score as high as possible in 2 minutes
- **Limited Moves**: Clear blocks strategically in 30 moves
- **Multiplayer**: Real-time 1v1 battles (requires server)

### Gameplay
- Tap/click groups of 2+ same-colored blocks to clear them
- Blocks fall down to fill gaps, new blocks spawn from top
- Build combos by clearing blocks quickly
- Earn power-ups by clearing large groups (7+ blocks)

### Power-ups
- 💥 **Bomb**: Clears a 3x3 area
- ⚡ **Lightning**: Clears an entire row
- 🌈 **Rainbow**: Clears all blocks of one color
- 🔀 **Shuffle**: Shuffles your board
- ❄️ **Freeze**: Freezes opponent (multiplayer only)

### Difficulty Levels
| Level  | Grid Size | Colors |
|--------|-----------|--------|
| Easy   | 8×6       | 4      |
| Medium | 10×8      | 5      |
| Hard   | 10×8      | 6      |
| Expert | 12×10     | 6      |

## Project Structure

```
BlockBlast/
├── index.html          # Main HTML file
├── manifest.json       # PWA manifest
├── css/
│   └── style.css      # All styles
├── js/
│   └── game.js        # Game logic
└── assets/            # Icons and images
```

## Technical Details

- **Pure JavaScript**: No frameworks or dependencies
- **Canvas API**: Smooth block rendering and animations
- **Web Audio API**: Sound effects
- **LocalStorage**: High score persistence
- **PWA Ready**: Can be installed as an app
- **Mobile Friendly**: Touch controls and responsive design

## Controls

- **Mouse/Touch**: Click or tap blocks to clear them
- **Power-ups**: Click power-up buttons then click target location

## Multiplayer Setup

For real multiplayer functionality, you'll need a WebSocket server:

1. Set up a Node.js server with Socket.io
2. Update the `Multiplayer.connect()` function in `game.js`
3. Implement room management and state synchronization

## Converting to iOS App

To package as an iOS app, use Capacitor:

```bash
npm init -y
npm install @capacitor/core @capacitor/cli @capacitor/ios
npx cap init "Block Blast" com.blockblast.game
npx cap add ios
npx cap sync
npx cap open ios
```

## Browser Support

- Chrome 60+
- Firefox 55+
- Safari 11+
- Edge 79+

## License

MIT License - feel free to use this code for learning or your own projects!
