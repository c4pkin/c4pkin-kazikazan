document.addEventListener('DOMContentLoaded', function() {

    let canvas = document.getElementById('scratch-card-canvas');
    let ctx = canvas.getContext('2d');
    let prizeText = document.getElementById('prize-text');
    let prizeAmount = document.getElementById('prize-amount');
    let closeBtn = document.getElementById('close-btn');
    
    let isDrawing = false;
    let lastX = 0;
    let lastY = 0;
    let cardActive = false;
    let revealedPercentage = 0;
    let scratchedPixels = 0;
    let totalPixels = 0;
    let currentPrize = 0;
    let money = 0;
    
    const emojis = ['💰', '💎', '🏆', '🚗', '🏠', '⭐', '🎮', '🎁', '💵'];
    const prizes = {
        '💰': 500,
        '💎': 1000,
        '🏆': 2000,
        '🚗': 5000,
        '🏠': 10000,
        '⭐': 3000,
        '🎮': 1500,
        '🎁': 2500,
        '💵': 750
    };
    
    function setupCanvas() {
        let cardContainer = document.querySelector('.card');
        canvas.width = cardContainer.offsetWidth;
        canvas.height = cardContainer.offsetHeight;
        totalPixels = canvas.width * canvas.height;
        
        ctx.fillStyle = '#5c3dc3';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
        drawPattern();
    }
    
    function drawPattern() {
        ctx.font = '24px Arial';
        ctx.fillStyle = '#7e59dd';
        
        for (let y = 20; y < canvas.height; y += 40) {
            for (let x = 20; x < canvas.width; x += 40) {
                ctx.fillText("$", x, y);
            }
        }
    }
    
    function generateEmojiGrid() {
        let grid = [];
        for (let i = 0; i < 3; i++) {
            let row = [];
            for (let j = 0; j < 3; j++) {

                let randomIndex = Math.floor(Math.random() * emojis.length);
                row.push(emojis[randomIndex]);
            }
            grid.push(row);
        }
        return grid;
    }
    
    function checkWinningCombinations(grid) {
        let winningEmoji = null;
        
        for (let i = 0; i < 3; i++) {
            if (grid[i][0] === grid[i][1] && grid[i][1] === grid[i][2]) {
                winningEmoji = grid[i][0];
                return { win: true, emoji: winningEmoji };
            }
        }
        
        for (let j = 0; j < 3; j++) {
            if (grid[0][j] === grid[1][j] && grid[1][j] === grid[2][j]) {
                winningEmoji = grid[0][j];
                return { win: true, emoji: winningEmoji };
            }
        }
        
        if (grid[0][0] === grid[1][1] && grid[1][1] === grid[2][2]) {
            winningEmoji = grid[0][0];
            return { win: true, emoji: winningEmoji };
        }
        
        if (grid[0][2] === grid[1][1] && grid[1][1] === grid[2][0]) {
            winningEmoji = grid[0][2];
            return { win: true, emoji: winningEmoji };
        }
        
        return { win: false, emoji: null };
    }
    
    function displayEmojiGrid(grid) {
        const gridSize = 3;
        const cellSize = 60;
        const startX = (canvas.width - (gridSize * cellSize)) / 2;
        const startY = (canvas.height - (gridSize * cellSize)) / 2;

        prizeText.innerHTML = '';

        const gridContainer = document.createElement('div');
        gridContainer.style.display = 'grid';
        gridContainer.style.gridTemplateColumns = 'repeat(3, 1fr)';
        gridContainer.style.gap = '5px';
        gridContainer.style.fontSize = '40px';
        
        for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 3; j++) {
                const emojiSpan = document.createElement('span');
                emojiSpan.textContent = grid[i][j];
                gridContainer.appendChild(emojiSpan);
            }
        }
        
        prizeText.appendChild(gridContainer);
    }
    
    function createNewCard() {
      
        revealedPercentage = 0;
        scratchedPixels = 0;
        
        setupCanvas();
        
        const emojiGrid = generateEmojiGrid();

        const result = checkWinningCombinations(emojiGrid);

        displayEmojiGrid(emojiGrid);

        if (result.win) {
            currentPrize = prizes[result.emoji];
        } else {
            currentPrize = 0;
        }

        prizeAmount.textContent = "Kazı ve Gör!";
        
        cardActive = true;
    }

    function calculateScratchPercentage() {
        let imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        let pixels = imageData.data;
        
        scratchedPixels = 0;
        for (let i = 0; i < pixels.length; i += 4) {

            if (pixels[i + 3] === 0) {
                scratchedPixels++;
            }
        }
        
        revealedPercentage = (scratchedPixels / totalPixels) * 100;
        
        if (revealedPercentage > 50 && cardActive) {
            revealPrize();
        }
    }
    
    function revealPrize() {
        cardActive = false;
        
        if (currentPrize > 0) {
            prizeAmount.textContent = "$" + currentPrize.toLocaleString();
            
            money += currentPrize;
            
            prizeText.classList.add('win-animation');
            setTimeout(() => {
                prizeText.classList.remove('win-animation');
            }, 1500);
            
            fetch(`https://c4pkin-kazikazan/prizeWon`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    amount: currentPrize
                })
            }).catch(error => {});
        } else {
            prizeAmount.textContent = "Kazanamadın!";
        }
    }

    canvas.addEventListener('mousedown', function(e) {
        if (!cardActive) return;
        
        isDrawing = true;
        [lastX, lastY] = [e.offsetX, e.offsetY];
    });
    
    canvas.addEventListener('mousemove', function(e) {
        if (!isDrawing || !cardActive) return;

        ctx.globalCompositeOperation = 'destination-out';
        ctx.beginPath();
        ctx.lineWidth = 30;
        ctx.lineCap = 'round';
        ctx.moveTo(lastX, lastY);
        ctx.lineTo(e.offsetX, e.offsetY);
        ctx.stroke();
        
        [lastX, lastY] = [e.offsetX, e.offsetY];
        
        calculateScratchPercentage();
    });
    
    canvas.addEventListener('mouseup', () => {
        isDrawing = false;
    });
    
    canvas.addEventListener('mouseout', () => {
        isDrawing = false;
    });
    
    closeBtn.addEventListener('click', function() {
        fetch(`https://c4pkin-kazikazan/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        }).catch(error => {});
    });

    window.addEventListener('message', function(event) {
        let data = event.data;
        
        if (data.type === 'OPEN_SCRATCH_CARD') {
            document.querySelector('.container').style.display = 'block';
            money = data.money || 0;
            setupCanvas();
            createNewCard();
        } else if (data.type === 'CLOSE_SCRATCH_CARD') {
            document.querySelector('.container').style.display = 'none';
        } else if (data.type === 'UPDATE_MONEY') {
            money = data.money || 0;
        }
    });
    
    document.querySelector('.container').style.display = 'none';
    
    setupCanvas();
});