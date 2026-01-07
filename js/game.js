// Block Blast - Multiplayer Game
// Main game module

// ==================== CONSTANTS ====================
const BLOCK_COLORS = [
    { main: '#ff5555', light: '#ff7777', dark: '#cc3333' },  // Red
    { main: '#5599ff', light: '#77bbff', dark: '#3366cc' },  // Blue
    { main: '#55ff88', light: '#77ffaa', dark: '#33cc66' },  // Green
    { main: '#ffee55', light: '#ffff77', dark: '#ccbb33' },  // Yellow
    { main: '#bb55ff', light: '#dd77ff', dark: '#8833cc' },  // Purple
    { main: '#ff9955', light: '#ffbb77', dark: '#cc6633' },  // Orange
];

const DIFFICULTY_SETTINGS = {
    easy: { rows: 8, cols: 6, colors: 4 },
    medium: { rows: 10, cols: 8, colors: 5 },
    hard: { rows: 10, cols: 8, colors: 6 },
    expert: { rows: 12, cols: 10, colors: 6 }
};

const MODE_SETTINGS = {
    endless: { time: null, moves: null },
    timed: { time: 120, moves: null },
    moves: { time: null, moves: 30 }
};

// ==================== GAME STATE ====================
const gameState = {
    mode: 'endless',
    difficulty: 'medium',
    grid: [],
    rows: 10,
    cols: 8,
    colorCount: 5,
    score: 0,
    level: 1,
    combo: 0,
    maxCombo: 0,
    blocksCleared: 0,
    timeRemaining: null,
    movesRemaining: null,
    powerUps: { bomb: 1, lightning: 1, rainbow: 0, shuffle: 0, freeze: 1 },
    selectedPowerUp: null,
    isAnimating: false,
    isFrozen: false,
    frozenTime: 0,
    isMultiplayer: false,
    isPaused: false,
    gameOver: false
};

// ==================== CANVAS SETUP ====================
let canvas, ctx;
let blockSize = 40;
let gridOffsetX = 0, gridOffsetY = 0;
let highlightedBlocks = [];
let animationFrameId = null;
let lastTime = 0;

// ==================== AUDIO ====================
const AudioManager = {
    sounds: {},

    init() {
        // Create audio context on first interaction
        document.addEventListener('click', () => {
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }
        }, { once: true });
    },

    play(type) {
        if (!this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);

        const sounds = {
            clear: { freq: 440, duration: 0.1, type: 'sine' },
            combo: { freq: 660, duration: 0.15, type: 'sine' },
            powerup: { freq: 880, duration: 0.2, type: 'triangle' },
            invalid: { freq: 220, duration: 0.1, type: 'sawtooth' },
            gameover: { freq: 150, duration: 0.5, type: 'sawtooth' }
        };

        const sound = sounds[type] || sounds.clear;
        oscillator.type = sound.type;
        oscillator.frequency.setValueAtTime(sound.freq, this.audioContext.currentTime);
        gainNode.gain.setValueAtTime(0.1, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + sound.duration);

        oscillator.start();
        oscillator.stop(this.audioContext.currentTime + sound.duration);
    }
};

// ==================== STORAGE ====================
const Storage = {
    getHighScore(mode) {
        const scores = JSON.parse(localStorage.getItem('blockblast_scores') || '{}');
        return scores[mode] || 0;
    },

    setHighScore(mode, score) {
        const scores = JSON.parse(localStorage.getItem('blockblast_scores') || '{}');
        if (score > (scores[mode] || 0)) {
            scores[mode] = score;
            localStorage.setItem('blockblast_scores', JSON.stringify(scores));
            return true;
        }
        return false;
    }
};

// ==================== UI MANAGEMENT ====================
const UI = {
    screens: {},

    init() {
        this.screens = {
            menu: document.getElementById('menu-screen'),
            game: document.getElementById('game-screen'),
            multiplayer: document.getElementById('multiplayer-screen'),
            matchmaking: document.getElementById('matchmaking-screen'),
            gameover: document.getElementById('gameover-screen')
        };
    },

    showScreen(screenName) {
        Object.values(this.screens).forEach(screen => {
            screen.classList.remove('active');
        });
        this.screens[screenName].classList.add('active');
    },

    updateScore() {
        document.getElementById('score').textContent = gameState.score;
        document.getElementById('level').textContent = gameState.level;
        document.getElementById('cleared-count').textContent = gameState.blocksCleared;
    },

    updateStatus() {
        const indicator = document.getElementById('status-indicator');
        if (gameState.timeRemaining !== null) {
            const mins = Math.floor(gameState.timeRemaining / 60);
            const secs = Math.floor(gameState.timeRemaining % 60);
            indicator.textContent = `⏱ ${mins}:${secs.toString().padStart(2, '0')}`;
            indicator.style.color = gameState.timeRemaining <= 10 ? '#ff4444' : '#ff9955';
        } else if (gameState.movesRemaining !== null) {
            indicator.textContent = `🎯 ${gameState.movesRemaining} moves`;
            indicator.style.color = gameState.movesRemaining <= 5 ? '#ff4444' : '#5599ff';
        } else {
            indicator.textContent = '∞ Endless';
            indicator.style.color = '#bb55ff';
        }
    },

    updatePowerUps() {
        document.getElementById('bomb-count').textContent = gameState.powerUps.bomb;
        document.getElementById('lightning-count').textContent = gameState.powerUps.lightning;
        document.getElementById('rainbow-count').textContent = gameState.powerUps.rainbow;
        document.getElementById('shuffle-count').textContent = gameState.powerUps.shuffle;

        document.querySelectorAll('.power-up-btn').forEach(btn => {
            const power = btn.dataset.power;
            btn.disabled = gameState.powerUps[power] <= 0;
            btn.classList.toggle('active', gameState.selectedPowerUp === power);
        });
    },

    showCombo(combo, x, y) {
        const popup = document.getElementById('combo-popup');
        popup.textContent = `${combo}x COMBO!`;
        popup.style.left = `${x}px`;
        popup.style.top = `${y}px`;
        popup.classList.remove('hidden');

        setTimeout(() => popup.classList.add('hidden'), 600);
    },

    showScorePopup(score, x, y) {
        const popup = document.getElementById('score-popup');
        popup.textContent = `+${score}`;
        popup.style.left = `${x}px`;
        popup.style.top = `${y}px`;
        popup.classList.remove('hidden');

        setTimeout(() => popup.classList.add('hidden'), 600);
    },

    showFreeze(show) {
        document.getElementById('freeze-overlay').classList.toggle('hidden', !show);
    },

    updateFreezeTimer(time) {
        document.getElementById('freeze-timer').textContent = time.toFixed(1);
    },

    showGameOver(isWin = false) {
        const isNewHigh = Storage.setHighScore(gameState.mode, gameState.score);

        document.getElementById('gameover-title').textContent = isWin ? 'VICTORY!' : 'GAME OVER';
        document.getElementById('gameover-title').style.background = isWin
            ? 'linear-gradient(90deg, #55ff88, #00cc6a)'
            : 'linear-gradient(90deg, #ff4444, #ff9955)';

        document.getElementById('new-high-score').classList.toggle('hidden', !isNewHigh);
        document.getElementById('final-score').textContent = gameState.score;
        document.getElementById('final-level').textContent = gameState.level;
        document.getElementById('final-cleared').textContent = gameState.blocksCleared;
        document.getElementById('final-combo').textContent = gameState.maxCombo;

        this.showScreen('gameover');
    }
};

// ==================== GRID MANAGEMENT ====================
const Grid = {
    create() {
        const settings = DIFFICULTY_SETTINGS[gameState.difficulty];
        gameState.rows = settings.rows;
        gameState.cols = settings.cols;
        gameState.colorCount = settings.colors;
        gameState.grid = [];

        for (let row = 0; row < gameState.rows; row++) {
            gameState.grid[row] = [];
            for (let col = 0; col < gameState.cols; col++) {
                gameState.grid[row][col] = this.randomColor();
            }
        }
    },

    randomColor() {
        return Math.floor(Math.random() * gameState.colorCount);
    },

    getBlock(row, col) {
        if (row < 0 || row >= gameState.rows || col < 0 || col >= gameState.cols) {
            return null;
        }
        return gameState.grid[row][col];
    },

    findConnected(row, col) {
        const color = this.getBlock(row, col);
        if (color === null) return [];

        const connected = [];
        const visited = new Set();
        const queue = [[row, col]];

        while (queue.length > 0) {
            const [r, c] = queue.shift();
            const key = `${r},${c}`;

            if (visited.has(key)) continue;
            if (r < 0 || r >= gameState.rows || c < 0 || c >= gameState.cols) continue;
            if (gameState.grid[r][c] !== color) continue;

            visited.add(key);
            connected.push({ row: r, col: c });

            queue.push([r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]);
        }

        return connected;
    },

    removeBlocks(positions) {
        positions.forEach(pos => {
            gameState.grid[pos.row][pos.col] = null;
        });
    },

    applyGravity() {
        const movements = [];

        for (let col = 0; col < gameState.cols; col++) {
            let writeRow = gameState.rows - 1;

            for (let row = gameState.rows - 1; row >= 0; row--) {
                if (gameState.grid[row][col] !== null) {
                    if (row !== writeRow) {
                        movements.push({
                            fromRow: row,
                            toRow: writeRow,
                            col: col,
                            color: gameState.grid[row][col]
                        });
                        gameState.grid[writeRow][col] = gameState.grid[row][col];
                        gameState.grid[row][col] = null;
                    }
                    writeRow--;
                }
            }
        }

        return movements;
    },

    fillEmpty() {
        const newBlocks = [];

        for (let col = 0; col < gameState.cols; col++) {
            for (let row = 0; row < gameState.rows; row++) {
                if (gameState.grid[row][col] === null) {
                    gameState.grid[row][col] = this.randomColor();
                    newBlocks.push({ row, col });
                }
            }
        }

        return newBlocks;
    },

    hasValidMoves() {
        for (let row = 0; row < gameState.rows; row++) {
            for (let col = 0; col < gameState.cols; col++) {
                if (this.findConnected(row, col).length >= 2) {
                    return true;
                }
            }
        }
        return false;
    },

    clearArea(centerRow, centerCol, radius = 1) {
        const cleared = [];
        for (let r = centerRow - radius; r <= centerRow + radius; r++) {
            for (let c = centerCol - radius; c <= centerCol + radius; c++) {
                if (r >= 0 && r < gameState.rows && c >= 0 && c < gameState.cols) {
                    if (gameState.grid[r][c] !== null) {
                        cleared.push({ row: r, col: c });
                        gameState.grid[r][c] = null;
                    }
                }
            }
        }
        return cleared;
    },

    clearRow(row) {
        const cleared = [];
        for (let col = 0; col < gameState.cols; col++) {
            if (gameState.grid[row][col] !== null) {
                cleared.push({ row, col });
                gameState.grid[row][col] = null;
            }
        }
        return cleared;
    },

    clearColor(color) {
        const cleared = [];
        for (let row = 0; row < gameState.rows; row++) {
            for (let col = 0; col < gameState.cols; col++) {
                if (gameState.grid[row][col] === color) {
                    cleared.push({ row, col });
                    gameState.grid[row][col] = null;
                }
            }
        }
        return cleared;
    },

    shuffle() {
        const blocks = [];
        for (let row = 0; row < gameState.rows; row++) {
            for (let col = 0; col < gameState.cols; col++) {
                if (gameState.grid[row][col] !== null) {
                    blocks.push(gameState.grid[row][col]);
                }
            }
        }

        // Fisher-Yates shuffle
        for (let i = blocks.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [blocks[i], blocks[j]] = [blocks[j], blocks[i]];
        }

        let idx = 0;
        for (let row = 0; row < gameState.rows; row++) {
            for (let col = 0; col < gameState.cols; col++) {
                if (gameState.grid[row][col] !== null) {
                    gameState.grid[row][col] = blocks[idx++];
                }
            }
        }
    }
};

// ==================== RENDERING ====================
const Renderer = {
    init() {
        canvas = document.getElementById('game-canvas');
        ctx = canvas.getContext('2d');
        this.resize();
        window.addEventListener('resize', () => this.resize());
    },

    resize() {
        const container = document.getElementById('game-container');
        const maxWidth = container.clientWidth - 20;
        const maxHeight = container.clientHeight - 20;

        blockSize = Math.min(
            Math.floor(maxWidth / gameState.cols),
            Math.floor(maxHeight / gameState.rows)
        );

        canvas.width = blockSize * gameState.cols;
        canvas.height = blockSize * gameState.rows;

        gridOffsetX = (container.clientWidth - canvas.width) / 2;
        gridOffsetY = (container.clientHeight - canvas.height) / 2;
    },

    drawBlock(x, y, colorIndex, highlighted = false, scale = 1) {
        const color = BLOCK_COLORS[colorIndex];
        const padding = 2;
        const size = blockSize - padding * 2;
        const offset = (1 - scale) * size / 2;

        const bx = x * blockSize + padding + offset;
        const by = y * blockSize + padding + offset;
        const bs = size * scale;
        const radius = bs * 0.2;

        // Shadow
        ctx.fillStyle = color.dark;
        this.roundRect(bx, by + 3, bs, bs, radius);

        // Main block
        const gradient = ctx.createLinearGradient(bx, by, bx + bs, by + bs);
        gradient.addColorStop(0, highlighted ? color.light : color.main);
        gradient.addColorStop(1, color.main);
        ctx.fillStyle = gradient;
        this.roundRect(bx, by, bs, bs, radius);

        // Highlight
        ctx.fillStyle = `rgba(255, 255, 255, ${highlighted ? 0.4 : 0.2})`;
        this.roundRect(bx + 2, by + 2, bs * 0.4, bs * 0.3, radius * 0.5);

        // Border for highlighted
        if (highlighted) {
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.8)';
            ctx.lineWidth = 2;
            this.roundRect(bx, by, bs, bs, radius, true);
        }
    },

    roundRect(x, y, w, h, r, stroke = false) {
        ctx.beginPath();
        ctx.moveTo(x + r, y);
        ctx.lineTo(x + w - r, y);
        ctx.quadraticCurveTo(x + w, y, x + w, y + r);
        ctx.lineTo(x + w, y + h - r);
        ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
        ctx.lineTo(x + r, y + h);
        ctx.quadraticCurveTo(x, y + h, x, y + h - r);
        ctx.lineTo(x, y + r);
        ctx.quadraticCurveTo(x, y, x + r, y);
        ctx.closePath();
        if (stroke) {
            ctx.stroke();
        } else {
            ctx.fill();
        }
    },

    render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Draw grid background
        ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);

        // Draw blocks
        for (let row = 0; row < gameState.rows; row++) {
            for (let col = 0; col < gameState.cols; col++) {
                const colorIndex = gameState.grid[row][col];
                if (colorIndex !== null) {
                    const isHighlighted = highlightedBlocks.some(
                        b => b.row === row && b.col === col
                    );
                    this.drawBlock(col, row, colorIndex, isHighlighted);
                }
            }
        }

        // Draw power-up targeting cursor if active
        if (gameState.selectedPowerUp) {
            ctx.strokeStyle = 'rgba(255, 215, 0, 0.5)';
            ctx.lineWidth = 3;
            ctx.setLineDash([5, 5]);
            ctx.strokeRect(0, 0, canvas.width, canvas.height);
            ctx.setLineDash([]);
        }
    }
};

// ==================== GAME LOGIC ====================
const Game = {
    init() {
        AudioManager.init();
        UI.init();
        Renderer.init();
        this.setupEventListeners();
        this.updateHighScoreDisplay();
    },

    setupEventListeners() {
        // Menu buttons
        document.querySelectorAll('.mode-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.mode-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                gameState.mode = btn.dataset.mode;
                this.updateHighScoreDisplay();
            });
        });

        document.querySelectorAll('.diff-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.diff-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                gameState.difficulty = btn.dataset.diff;
            });
        });

        document.getElementById('play-btn').addEventListener('click', () => this.startGame());
        document.getElementById('multiplayer-btn').addEventListener('click', () => UI.showScreen('matchmaking'));
        document.getElementById('back-to-menu-btn').addEventListener('click', () => UI.showScreen('menu'));

        // Game controls
        document.getElementById('pause-btn').addEventListener('click', () => this.togglePause());
        document.getElementById('resume-btn').addEventListener('click', () => this.togglePause());
        document.getElementById('quit-btn').addEventListener('click', () => this.quitGame());

        // Canvas interaction
        canvas.addEventListener('click', (e) => this.handleClick(e));
        canvas.addEventListener('mousemove', (e) => this.handleHover(e));
        canvas.addEventListener('mouseleave', () => { highlightedBlocks = []; });

        // Touch support
        canvas.addEventListener('touchstart', (e) => {
            e.preventDefault();
            const touch = e.touches[0];
            this.handleClick(touch);
        });

        // Power-ups
        document.querySelectorAll('.power-up-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const power = btn.dataset.power;
                if (power === 'shuffle') {
                    this.usePowerUp('shuffle');
                } else {
                    gameState.selectedPowerUp = gameState.selectedPowerUp === power ? null : power;
                    UI.updatePowerUps();
                }
            });
        });

        // Game over buttons
        document.getElementById('play-again-btn').addEventListener('click', () => this.startGame());
        document.getElementById('menu-btn').addEventListener('click', () => UI.showScreen('menu'));

        // Matchmaking
        document.getElementById('quick-match-btn').addEventListener('click', () => Multiplayer.quickMatch());
        document.getElementById('create-room-btn').addEventListener('click', () => Multiplayer.createRoom());
        document.getElementById('join-room-btn').addEventListener('click', () => {
            const code = document.getElementById('room-input').value;
            if (code) Multiplayer.joinRoom(code);
        });
    },

    updateHighScoreDisplay() {
        const highScore = Storage.getHighScore(gameState.mode);
        document.getElementById('high-score-display').textContent = highScore;
    },

    startGame() {
        // Reset state
        gameState.score = 0;
        gameState.level = 1;
        gameState.combo = 0;
        gameState.maxCombo = 0;
        gameState.blocksCleared = 0;
        gameState.isAnimating = false;
        gameState.isFrozen = false;
        gameState.gameOver = false;
        gameState.selectedPowerUp = null;
        gameState.powerUps = { bomb: 1, lightning: 1, rainbow: 0, shuffle: 0, freeze: 1 };

        // Apply mode settings
        const modeSettings = MODE_SETTINGS[gameState.mode];
        gameState.timeRemaining = modeSettings.time;
        gameState.movesRemaining = modeSettings.moves;

        // Create grid
        Grid.create();
        Renderer.resize();

        // Update UI
        UI.showScreen('game');
        UI.updateScore();
        UI.updateStatus();
        UI.updatePowerUps();

        // Start game loop
        lastTime = performance.now();
        this.gameLoop();

        AudioManager.play('powerup');
    },

    gameLoop(timestamp = 0) {
        if (gameState.gameOver || gameState.isPaused) return;

        const deltaTime = (timestamp - lastTime) / 1000;
        lastTime = timestamp;

        // Update timer
        if (gameState.timeRemaining !== null) {
            gameState.timeRemaining -= deltaTime;
            UI.updateStatus();

            if (gameState.timeRemaining <= 0) {
                this.endGame();
                return;
            }
        }

        // Update freeze
        if (gameState.isFrozen) {
            gameState.frozenTime -= deltaTime;
            UI.updateFreezeTimer(gameState.frozenTime);

            if (gameState.frozenTime <= 0) {
                gameState.isFrozen = false;
                UI.showFreeze(false);
            }
        }

        Renderer.render();
        animationFrameId = requestAnimationFrame((t) => this.gameLoop(t));
    },

    handleClick(e) {
        if (gameState.isAnimating || gameState.isFrozen || gameState.gameOver) return;

        const rect = canvas.getBoundingClientRect();
        const x = (e.clientX || e.pageX) - rect.left;
        const y = (e.clientY || e.pageY) - rect.top;

        const col = Math.floor(x / blockSize);
        const row = Math.floor(y / blockSize);

        if (row < 0 || row >= gameState.rows || col < 0 || col >= gameState.cols) return;

        if (gameState.selectedPowerUp) {
            this.usePowerUp(gameState.selectedPowerUp, row, col);
            gameState.selectedPowerUp = null;
            UI.updatePowerUps();
            return;
        }

        const connected = Grid.findConnected(row, col);

        if (connected.length >= 2) {
            this.clearBlocks(connected);
        } else {
            AudioManager.play('invalid');
            // Shake animation
            canvas.style.animation = 'shake 0.3s';
            setTimeout(() => canvas.style.animation = '', 300);
        }
    },

    handleHover(e) {
        if (gameState.isAnimating || gameState.isFrozen) {
            highlightedBlocks = [];
            return;
        }

        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;

        const col = Math.floor(x / blockSize);
        const row = Math.floor(y / blockSize);

        if (row < 0 || row >= gameState.rows || col < 0 || col >= gameState.cols) {
            highlightedBlocks = [];
            return;
        }

        const connected = Grid.findConnected(row, col);
        highlightedBlocks = connected.length >= 2 ? connected : [];
    },

    async clearBlocks(positions) {
        gameState.isAnimating = true;

        // Calculate score
        const baseScore = positions.length * 10;
        const comboMultiplier = 1 + gameState.combo * 0.5;
        const sizeBonus = positions.length > 5 ? (positions.length - 5) * 5 : 0;
        const scoreGained = Math.floor((baseScore + sizeBonus) * comboMultiplier);

        gameState.score += scoreGained;
        gameState.blocksCleared += positions.length;
        gameState.combo++;
        gameState.maxCombo = Math.max(gameState.maxCombo, gameState.combo);

        // Level up every 1000 points
        gameState.level = Math.floor(gameState.score / 1000) + 1;

        // Decrement moves
        if (gameState.movesRemaining !== null) {
            gameState.movesRemaining--;
            UI.updateStatus();
        }

        // Award power-ups for large clears
        if (positions.length >= 7) {
            gameState.powerUps.bomb++;
            UI.updatePowerUps();
        }
        if (positions.length >= 10) {
            gameState.powerUps.rainbow++;
            UI.updatePowerUps();
        }

        UI.updateScore();

        // Show popups
        const centerX = canvas.offsetLeft + (positions.reduce((sum, p) => sum + p.col, 0) / positions.length) * blockSize;
        const centerY = canvas.offsetTop + (positions.reduce((sum, p) => sum + p.row, 0) / positions.length) * blockSize;

        UI.showScorePopup(scoreGained, centerX, centerY);
        if (gameState.combo > 1) {
            UI.showCombo(gameState.combo, centerX, centerY - 40);
        }

        AudioManager.play(gameState.combo > 2 ? 'combo' : 'clear');

        // Animate removal
        Grid.removeBlocks(positions);
        Renderer.render();

        await this.delay(100);

        // Apply gravity
        Grid.applyGravity();
        Renderer.render();

        await this.delay(150);

        // Fill empty spaces
        Grid.fillEmpty();
        Renderer.render();

        await this.delay(100);

        gameState.isAnimating = false;

        // Check game over
        this.checkGameOver();
    },

    usePowerUp(type, row = null, col = null) {
        if (gameState.powerUps[type] <= 0) return;

        gameState.powerUps[type]--;
        UI.updatePowerUps();
        AudioManager.play('powerup');

        let cleared = [];

        switch (type) {
            case 'bomb':
                if (row !== null && col !== null) {
                    cleared = Grid.clearArea(row, col, 1);
                }
                break;
            case 'lightning':
                if (row !== null) {
                    cleared = Grid.clearRow(row);
                }
                break;
            case 'rainbow':
                if (row !== null && col !== null) {
                    const color = Grid.getBlock(row, col);
                    if (color !== null) {
                        cleared = Grid.clearColor(color);
                    }
                }
                break;
            case 'shuffle':
                Grid.shuffle();
                Renderer.render();
                break;
            case 'freeze':
                // Multiplayer only
                if (gameState.isMultiplayer) {
                    Multiplayer.sendFreeze();
                }
                break;
        }

        if (cleared.length > 0) {
            this.processCleared(cleared);
        }
    },

    async processCleared(positions) {
        gameState.isAnimating = true;

        const scoreGained = positions.length * 15;
        gameState.score += scoreGained;
        gameState.blocksCleared += positions.length;

        UI.updateScore();
        Renderer.render();

        await this.delay(150);
        Grid.applyGravity();
        Renderer.render();

        await this.delay(150);
        Grid.fillEmpty();
        Renderer.render();

        await this.delay(100);
        gameState.isAnimating = false;

        this.checkGameOver();
    },

    checkGameOver() {
        let isOver = false;

        if (gameState.mode === 'moves' && gameState.movesRemaining <= 0) {
            isOver = true;
        } else if (!Grid.hasValidMoves()) {
            isOver = true;
        }

        if (isOver) {
            this.endGame();
        } else {
            // Reset combo if no chain
            setTimeout(() => {
                if (!gameState.isAnimating) {
                    gameState.combo = 0;
                }
            }, 500);
        }
    },

    endGame() {
        gameState.gameOver = true;
        cancelAnimationFrame(animationFrameId);
        AudioManager.play('gameover');
        UI.showGameOver();
    },

    togglePause() {
        gameState.isPaused = !gameState.isPaused;
        document.getElementById('pause-modal').classList.toggle('hidden', !gameState.isPaused);
        document.getElementById('pause-score').textContent = gameState.score;

        if (!gameState.isPaused) {
            lastTime = performance.now();
            this.gameLoop();
        }
    },

    quitGame() {
        gameState.gameOver = true;
        gameState.isPaused = false;
        document.getElementById('pause-modal').classList.add('hidden');
        cancelAnimationFrame(animationFrameId);
        UI.showScreen('menu');
    },

    applyFreeze(duration = 3) {
        gameState.isFrozen = true;
        gameState.frozenTime = duration;
        UI.showFreeze(true);
    },

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
};

// ==================== MULTIPLAYER ====================
const Multiplayer = {
    socket: null,
    roomCode: null,
    isHost: false,

    connect() {
        // In a real implementation, connect to a WebSocket server
        // For demo purposes, we'll simulate local multiplayer
        console.log('Multiplayer would connect to server here');
    },

    quickMatch() {
        document.getElementById('searching-indicator').classList.remove('hidden');
        document.getElementById('waiting-indicator').classList.add('hidden');

        // Simulate finding a match
        setTimeout(() => {
            this.startMatch('Player2');
        }, 2000);
    },

    createRoom() {
        this.roomCode = Math.random().toString(36).substring(2, 8).toUpperCase();
        document.getElementById('room-code').textContent = this.roomCode;
        document.getElementById('searching-indicator').classList.add('hidden');
        document.getElementById('waiting-indicator').classList.remove('hidden');
        this.isHost = true;
    },

    joinRoom(code) {
        this.roomCode = code.toUpperCase();
        document.getElementById('searching-indicator').classList.remove('hidden');

        // Simulate joining
        setTimeout(() => {
            this.startMatch('Host');
        }, 1000);
    },

    startMatch(opponentName) {
        document.getElementById('opponent-name').textContent = opponentName;
        gameState.isMultiplayer = true;

        // Setup multiplayer game
        Game.startGame();
        UI.showScreen('multiplayer');

        // Clone canvas for multiplayer view
        const mpCanvas = document.getElementById('mp-game-canvas');
        mpCanvas.width = canvas.width;
        mpCanvas.height = canvas.height;

        // Start sync loop
        this.syncLoop();
    },

    syncLoop() {
        if (!gameState.isMultiplayer || gameState.gameOver) return;

        // In real implementation, send game state to server
        // and receive opponent state

        // Update multiplayer UI
        document.getElementById('mp-my-score').textContent = gameState.score;

        // Simulate opponent score
        const opponentScore = Math.floor(gameState.score * (0.8 + Math.random() * 0.4));
        document.getElementById('mp-opponent-score').textContent = opponentScore;

        setTimeout(() => this.syncLoop(), 100);
    },

    sendFreeze() {
        // Send freeze to opponent via server
        console.log('Sending freeze to opponent');
    },

    endMatch(won) {
        const modal = document.getElementById('mp-result-modal');
        document.getElementById('mp-result-title').textContent = won ? 'VICTORY!' : 'DEFEAT';
        document.getElementById('mp-result-title').style.color = won ? '#55ff88' : '#ff4444';
        document.getElementById('mp-final-my-score').textContent = gameState.score;
        document.getElementById('mp-final-opponent-score').textContent =
            document.getElementById('mp-opponent-score').textContent;

        modal.classList.remove('hidden');

        document.getElementById('mp-rematch-btn').addEventListener('click', () => {
            modal.classList.add('hidden');
            UI.showScreen('matchmaking');
        });

        document.getElementById('mp-menu-btn').addEventListener('click', () => {
            modal.classList.add('hidden');
            gameState.isMultiplayer = false;
            UI.showScreen('menu');
        });
    }
};

// ==================== START ====================
document.addEventListener('DOMContentLoaded', () => {
    Game.init();
});

// Add shake animation
const style = document.createElement('style');
style.textContent = `
    @keyframes shake {
        0%, 100% { transform: translateX(0); }
        20%, 60% { transform: translateX(-5px); }
        40%, 80% { transform: translateX(5px); }
    }
`;
document.head.appendChild(style);
