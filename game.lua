-- 俄罗斯方块游戏 - 游戏核心模块
-- game.lua

-- 导入方块模块
local Tetromino = require 'tetromino'
local AudioConfig = require 'audio.config'
local DifficultyConfig = require 'config.difficulty'
local ScoreboardConfig = require 'config.scoreboard'

-- 游戏常量
local GRID_WIDTH = 10      -- 游戏网格宽度
local GRID_HEIGHT = 20     -- 游戏网格高度
local CELL_SIZE = 30       -- 单元格大小
local BOARD_OFFSET_X = 300 -- 游戏板X偏移
local BOARD_OFFSET_Y = 20  -- 游戏板Y偏移
local PREVIEW_OFFSET_X = 30 -- 预览区域X偏移
local PREVIEW_OFFSET_Y = 50 -- 预览区域Y偏移
local UI_OFFSET_X = 30      -- UI区域X偏移
local UI_OFFSET_Y = 250     -- UI区域Y偏移
local UI_PANEL_WIDTH = 280   -- UI面板宽度
local UI_TEXT_PADDING = 20   -- UI文字内边距

-- 游戏类
local Game = {}

-- 创建新游戏实例
function Game.new()
    local self = {}
    
    -- 初始化网格线
    _G.initGridLines()
    
    -- 游戏状态
    self.state = "menu" -- menu, playing, paused, gameover, highscores
    self.score = 0
    self.level = 1
    self.lines = 0
    
    -- 初始化难度和排行榜
    DifficultyConfig:init()
    ScoreboardConfig:init()
    
    -- 游戏速度 (秒/行)
    local currentLevel = DifficultyConfig:getCurrentLevel()
    self.dropSpeed = currentLevel.dropSpeed
    self.scoreMultiplier = currentLevel.scoreMultiplier
    self.dropTimer = 0
    
    -- 游戏网格 (0=空, 1-7=方块颜色)
    self.grid = {}
    for y = 1, GRID_HEIGHT do
        self.grid[y] = {}
        for x = 1, GRID_WIDTH do
            self.grid[y][x] = 0
        end
    end
    
    -- 当前方块和下一个方块
    self.currentTetromino = Tetromino.new()
    self.nextTetromino = Tetromino.new()
    
    -- 初始化当前方块位置
    self.tetrominoX = math.floor(GRID_WIDTH / 2) - 1
    self.tetrominoY = 0
    
    -- 方法绑定
    self.update = Game.update
    self.draw = Game.draw
    self.keypressed = Game.keypressed
    self.keyreleased = Game.keyreleased
    self.moveTetrominoDown = Game.moveTetrominoDown
    self.moveTetrominoLeft = Game.moveTetrominoLeft
    self.moveTetrominoRight = Game.moveTetrominoRight
    self.rotateTetromino = Game.rotateTetromino
    self.checkCollision = Game.checkCollision
    self.lockTetromino = Game.lockTetromino
    self.clearLines = Game.clearLines
    self.spawnTetromino = Game.spawnTetromino
    self.isGameOver = Game.isGameOver
    self.drawGrid = Game.drawGrid
    self.drawTetromino = Game.drawTetromino
    self.drawNextTetromino = Game.drawNextTetromino
    self.drawUI = Game.drawUI
    self.calculateHardDropPosition = Game.calculateHardDropPosition
    self.initDrawingResources = Game.initDrawingResources
    self.updateBlockBatches = Game.updateBlockBatches
    self.drawMenu = Game.drawMenu
    self.drawHighScores = Game.drawHighScores
    self.startGame = Game.startGame
    self.resetGame = Game.resetGame
    
    -- 预缓存绘图资源
    self:initDrawingResources()
    
    -- 主菜单选项
    self.menuItems = {
        "开始游戏",
        "难度: " .. DifficultyConfig:getCurrentLevel().name,
        "排行榜",
        "退出游戏"
    }
    self.selectedMenuItem = 1
    
    return self
end

-- 初始化绘图资源
function Game:initDrawingResources()
    -- 预创建方块Canvas和SpriteBatch
    self.blockCanvases = {}
    self.blockBatches = {}
    self.borderBatch = nil
    
    -- 创建边框Canvas
    local borderCanvas = love.graphics.newCanvas(CELL_SIZE, CELL_SIZE)
    love.graphics.setCanvas(borderCanvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", 0, 0, CELL_SIZE, CELL_SIZE)
    love.graphics.setCanvas()
    
    self.borderBatch = love.graphics.newSpriteBatch(borderCanvas, GRID_WIDTH * GRID_HEIGHT, "stream")
    
    -- 创建各种颜色的方块Canvas和SpriteBatch
    for i = 1, 7 do
        local blockCanvas = love.graphics.newCanvas(CELL_SIZE, CELL_SIZE)
        love.graphics.setCanvas(blockCanvas)
        love.graphics.clear()
        love.graphics.setColor(Tetromino.getColorForType(i))
        love.graphics.rectangle("fill", 0, 0, CELL_SIZE, CELL_SIZE)
        love.graphics.setCanvas()
        
        self.blockCanvases[i] = blockCanvas
        self.blockBatches[i] = love.graphics.newSpriteBatch(blockCanvas, GRID_WIDTH * GRID_HEIGHT, "stream")
    end
    
    -- 初始更新一次SpriteBatch
    self:updateBlockBatches()
 end

-- 更新方块批处理
function Game:updateBlockBatches()
    -- 清空所有批处理
    for i = 1, 7 do
        self.blockBatches[i]:clear()
    end
    self.borderBatch:clear()
    
    -- 填充SpriteBatch
    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            if self.grid[y][x] > 0 then
                local colorType = self.grid[y][x]
                local posX = BOARD_OFFSET_X + (x - 1) * CELL_SIZE
                local posY = BOARD_OFFSET_Y + (y - 1) * CELL_SIZE
                
                self.blockBatches[colorType]:add(posX, posY)
                self.borderBatch:add(posX, posY)
            end
        end
    end
end

-- 开始新游戏
function Game:startGame()
    -- 重置游戏状态
    self:resetGame()
    
    -- 设置游戏状态为进行中
    self.state = "playing"
    
    -- 应用当前难度设置
    local currentLevel = DifficultyConfig:getCurrentLevel()
    self.dropSpeed = currentLevel.dropSpeed
    self.scoreMultiplier = currentLevel.scoreMultiplier
end

-- 重置游戏
function Game:resetGame()
    -- 重置分数和行数
    self.score = 0
    self.level = 1
    self.lines = 0
    
    -- 重置游戏网格
    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            self.grid[y][x] = 0
        end
    end
    
    -- 重置方块
    self.currentTetromino = Tetromino.new()
    self.nextTetromino = Tetromino.new()
    self.tetrominoX = math.floor(GRID_WIDTH / 2) - 1
    self.tetrominoY = 0
    
    -- 更新方块批处理
    self:updateBlockBatches()
    
    -- 重置阴影
    self.needUpdateHardDrop = true
end

-- 更新游戏状态
function Game:update(dt)
    if self.state == "playing" then
    
    -- 更新下落计时器
    self.dropTimer = self.dropTimer + dt
    if self.dropTimer >= self.dropSpeed then
        self.dropTimer = 0
        self:moveTetrominoDown()
    end
end
end

-- 绘制主菜单
function Game:drawMenu()
    -- 获取字体配置
    local FontConfig = require 'fonts.config'
    
    -- 使用缓存的字体
    if not self.titleFont then
        self.titleFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 36)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("俄罗斯方块", 0, 100, love.graphics.getWidth(), "center")
    
    -- 恢复默认字体
    if not self.normalFont then
        self.normalFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 20)
    end
    love.graphics.setFont(self.normalFont)
    
    -- 更新菜单项
    self.menuItems[2] = "难度: " .. DifficultyConfig:getCurrentLevel().name
    
    -- 绘制菜单选项
    local menuY = 200
    local menuSpacing = 50
    
    for i, item in ipairs(self.menuItems) do
        -- 选中项使用不同颜色
        if i == self.selectedMenuItem then
            love.graphics.setColor(1, 0.8, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(item, 0, menuY + (i-1) * menuSpacing, love.graphics.getWidth(), "center")
    end
    
    -- 使用缓存的字体
    if not self.smallFont then
        self.smallFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 14)
    end
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf(
        "上下键选择，回车确认，空格切换难度",
        0,
        love.graphics.getHeight() - 50,
        love.graphics.getWidth(),
        "center"
    )
    love.graphics.setFont(self.normalFont)
end

-- 绘制排行榜
function Game:drawHighScores()
    -- 获取字体配置
    local FontConfig = require 'fonts.config'
    
    -- 使用缓存的字体
    if not self.titleFont then
        self.titleFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 36)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("排行榜", 0, 50, love.graphics.getWidth(), "center")
    
    -- 恢复默认字体
    if not self.normalFont then
        self.normalFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 20)
    end
    love.graphics.setFont(self.normalFont)
    
    -- 获取排行榜记录
    local records = ScoreboardConfig:getRecords()
    
    if #records == 0 then
        love.graphics.printf("暂无记录", 0, 200, love.graphics.getWidth(), "center")
    else
        -- 绘制表头
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("排名", 150, 120, 100, "left")
        love.graphics.printf("分数", 250, 120, 100, "left")
        love.graphics.printf("等级", 350, 120, 100, "left")
        love.graphics.printf("行数", 450, 120, 100, "left")
        love.graphics.printf("日期", 550, 120, 200, "left")
        
        -- 绘制记录
        for i, record in ipairs(records) do
            if i <= 10 then
                local y = 150 + (i-1) * 30
                love.graphics.setColor(1, 1, 1)
                love.graphics.printf(i, 150, y, 100, "left")
                love.graphics.printf(record.score, 250, y, 100, "left")
                love.graphics.printf(record.level, 350, y, 100, "left")
                love.graphics.printf(record.lines, 450, y, 100, "left")
                love.graphics.printf(record.date, 550, y, 200, "left")
            end
        end
    end
    
    -- 使用缓存的字体
    if not self.smallFont then
        self.smallFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 14)
    end
    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf(
        "按ESC返回主菜单",
        0,
        love.graphics.getHeight() - 50,
        love.graphics.getWidth(),
        "center"
    )
    if not self.normalFont then
        self.normalFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 20)
    end
    love.graphics.setFont(self.normalFont)
end

-- 绘制游戏
function Game:draw()
    -- 绘制背景
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- 根据游戏状态绘制不同内容
    if self.state == "menu" then
        self:drawMenu()
    elseif self.state == "highscores" then
        self:drawHighScores()
    else
        -- 绘制游戏网格
        self:drawGrid()
        
        -- 绘制硬降落预览
        local hardDropY = self:calculateHardDropPosition()
        if hardDropY then
            local originalY = self.tetrominoY
            self.tetrominoY = hardDropY
            love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
            self:drawTetromino()
            self.tetrominoY = originalY
        end
        
        -- 绘制当前方块
        love.graphics.setColor(1, 1, 1, 1)
        self:drawTetromino()
        
        -- 绘制下一个方块预览
        self:drawNextTetromino()
        
        -- 绘制UI
        self:drawUI()
        
        -- 绘制游戏状态提示
        if self.state == "paused" then
            -- 半透明黑色背景
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", BOARD_OFFSET_X, BOARD_OFFSET_Y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
            
            -- 绘制暂停菜单框
            local boxWidth = 200
            local boxHeight = 180
            local boxX = BOARD_OFFSET_X + (GRID_WIDTH * CELL_SIZE - boxWidth) / 2
            local boxY = BOARD_OFFSET_Y + (GRID_HEIGHT * CELL_SIZE - boxHeight) / 2
            
            -- 菜单框背景
            love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
            love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
            
            -- 菜单框边框
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
            
            -- 菜单选项
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("游戏暂停", boxX, boxY + 20, boxWidth, "center")
            love.graphics.printf("继续游戏 (P)", boxX, boxY + 70, boxWidth, "center")
            love.graphics.printf("返回主菜单 (M)", boxX, boxY + 110, boxWidth, "center")
            love.graphics.printf("退出游戏 (ESC)", boxX, boxY + 150, boxWidth, "center")
        elseif self.state == "gameover" then
            -- 半透明黑色背景
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", BOARD_OFFSET_X, BOARD_OFFSET_Y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
            
            -- 绘制游戏结束菜单框
            local boxWidth = 300
            local boxHeight = 200
            local boxX = BOARD_OFFSET_X + (GRID_WIDTH * CELL_SIZE - boxWidth) / 2
            local boxY = BOARD_OFFSET_Y + (GRID_HEIGHT * CELL_SIZE - boxHeight) / 2
            
            -- 菜单框背景
            love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
            love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
            
            -- 菜单框边框
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
            
            -- 游戏结束信息
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.printf("游戏结束", boxX, boxY + 20, boxWidth, "center")
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(string.format("最终得分: %d", self.score), boxX, boxY + 60, boxWidth, "center")
            love.graphics.printf(string.format("消除行数: %d", self.lines), boxX, boxY + 90, boxWidth, "center")
            
            -- 检查是否进入排行榜
            local rank = ScoreboardConfig:addScore(self.score, self.level, self.lines)
            if rank then
                love.graphics.printf(string.format("新排名: 第%d名", rank), boxX, boxY + 120, boxWidth, "center")
            end
            
            -- 菜单选项
            love.graphics.printf("重新开始 (R/Enter)", boxX, boxY + 150, boxWidth, "center")
            love.graphics.printf("返回主菜单 (M)", boxX, boxY + 180, boxWidth, "center")
        end
    end
end

-- 键盘按键处理
function Game:keypressed(key)
    if self.state == "menu" then
        if key == "up" then
            self.selectedMenuItem = self.selectedMenuItem - 1
            if self.selectedMenuItem < 1 then
                self.selectedMenuItem = #self.menuItems
            end
        elseif key == "down" then
            self.selectedMenuItem = self.selectedMenuItem + 1
            if self.selectedMenuItem > #self.menuItems then
                self.selectedMenuItem = 1
            end
        elseif key == "return" then
            -- 根据选择执行不同操作
            if self.selectedMenuItem == 1 then
                -- 开始游戏
                self:startGame()
            elseif self.selectedMenuItem == 2 then
                -- 切换难度
                local nextLevel = DifficultyConfig:nextLevel()
            elseif self.selectedMenuItem == 3 then
                -- 查看排行榜
                self.state = "highscores"
            elseif self.selectedMenuItem == 4 then
                -- 退出游戏
                love.event.quit()
            end
        elseif key == "space" and self.selectedMenuItem == 2 then
            -- 在难度选项上按空格切换难度
            local nextLevel = DifficultyConfig:nextLevel()
        end
    elseif self.state == "playing" then
        if key == "left" then
            self:moveTetrominoLeft()
        elseif key == "right" then
            self:moveTetrominoRight()
        elseif key == "up" then
            self:rotateTetromino()
        elseif key == "down" then
            self:moveTetrominoDown()
        elseif key == "space" then
            -- 硬降落
            while not self:moveTetrominoDown() do end
        elseif key == "p" then
            self.state = "paused"
        elseif key == "m" then
            self.state = "menu"
        elseif key == "r" then
            self:startGame()
        end
    elseif self.state == "paused" then
        if key == "p" then
            self.state = "playing"
        elseif key == "m" then
            self.state = "menu"
        end
    elseif self.state == "gameover" then
        if key == "return" or key == "r" then
            self:startGame()
        elseif key == "m" then
            self.state = "menu"
        end
    elseif self.state == "highscores" then
        if key == "escape" or key == "backspace" or key == "return" then
            self.state = "menu"
        end
    end
end

-- 绘制暂停状态
function Game:drawPaused()
    -- 获取字体配置
    local FontConfig = require 'fonts.config'
    
    -- 使用缓存的字体
    if not self.normalFont then
        self.normalFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 20)
    end
    
    -- 半透明黑色背景
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", BOARD_OFFSET_X, BOARD_OFFSET_Y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
    
    -- 绘制暂停提示框
    local boxWidth = 200
    local boxHeight = 100
    local boxX = BOARD_OFFSET_X + (GRID_WIDTH * CELL_SIZE - boxWidth) / 2
    local boxY = BOARD_OFFSET_Y + (GRID_HEIGHT * CELL_SIZE - boxHeight) / 2
    
    -- 提示框背景
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
    
    -- 提示文字
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.uiFont)
    love.graphics.printf("游戏暂停", boxX, boxY + 30, boxWidth, "center")
    love.graphics.printf("按P键继续", boxX, boxY + 60, boxWidth, "center")
end

-- 绘制游戏结束状态
function Game:drawGameOver()
    -- 获取字体配置
    local FontConfig = require 'fonts.config'
    
    -- 使用缓存的字体
    if not self.normalFont then
        self.normalFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 20)
    end
    
    -- 半透明黑色背景
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", BOARD_OFFSET_X, BOARD_OFFSET_Y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
    
    -- 绘制游戏结束提示框
    local boxWidth = 250
    local boxHeight = 150
    local boxX = BOARD_OFFSET_X + (GRID_WIDTH * CELL_SIZE - boxWidth) / 2
    local boxY = BOARD_OFFSET_Y + (GRID_HEIGHT * CELL_SIZE - boxHeight) / 2
    
    -- 提示框背景
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)
        
    -- 提示框边框
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
        
    -- 游戏结束提示文字
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.setFont(self.uiFont)
    love.graphics.printf(
        "游戏结束",
        boxX,
        boxY + 20,
        boxWidth,
        "center"
    )
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        "最终分数: " .. self.score,
        boxX,
        boxY + 60,
        boxWidth,
        "center"
    )
    
    love.graphics.printf(
        "按R键重新开始",
        boxX,
        boxY + 100,
        boxWidth,
        "center"
    )
end

-- 预生成网格线顶点数据
local gridLinesVertices = love.graphics.newMesh(4 * (GRID_WIDTH + GRID_HEIGHT + 2), "strip", "static")
function _G.initGridLines()
    local vertices = {}
    local index = 1
    
    -- 垂直线
    for x = 0, GRID_WIDTH do
        vertices[index] = {BOARD_OFFSET_X + x * CELL_SIZE, BOARD_OFFSET_Y}
        vertices[index + 1] = {BOARD_OFFSET_X + x * CELL_SIZE, BOARD_OFFSET_Y + GRID_HEIGHT * CELL_SIZE}
        index = index + 2
    end
    
    -- 水平线
    for y = 0, GRID_HEIGHT do
        vertices[index] = {BOARD_OFFSET_X, BOARD_OFFSET_Y + y * CELL_SIZE}
        vertices[index + 1] = {BOARD_OFFSET_X + GRID_WIDTH * CELL_SIZE, BOARD_OFFSET_Y + y * CELL_SIZE}
        index = index + 2
    end
    
    gridLinesVertices:setVertices(vertices)
end

-- 绘制游戏网格（优化版）
function Game:drawGrid()
    -- 绘制游戏区域背景
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", BOARD_OFFSET_X, BOARD_OFFSET_Y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
    
    -- 绘制网格线
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.draw(gridLinesVertices)
    
    -- 绘制已放置的方块
    love.graphics.setColor(1, 1, 1)
    for i = 1, 7 do
        love.graphics.draw(self.blockBatches[i])
    end
    love.graphics.draw(self.borderBatch)
end

-- 计算硬降落点位置（优化版）
function Game:calculateHardDropPosition()
    local originalY = self.tetrominoY
    local dropY = originalY
    
    -- 使用临时变量进行计算，避免修改和恢复游戏状态
    while true do
        dropY = dropY + 1
        
        -- 检查这个位置是否会碰撞，但不修改实际的tetrominoY
        local shape = self.currentTetromino:getShape()
        local minX, maxX, minY, maxY = 4, 1, 4, 1
        
        -- 快速确定方块的实际边界
        for y = 1, 4 do
            for x = 1, 4 do
                if shape[y][x] == 1 then
                    minX = math.min(minX, x)
                    maxX = math.max(maxX, x)
                    minY = math.min(minY, y)
                    maxY = math.max(maxY, y)
                end
            end
        end
        
        -- 快速边界检查
        if self.tetrominoX + minX < 1 or self.tetrominoX + maxX > GRID_WIDTH or
           dropY + minY < 1 or dropY + maxY > GRID_HEIGHT then
            dropY = dropY - 1
            break
        end
        
        -- 只检查实际占用的区域
        local collision = false
        for y = minY, maxY do
            for x = minX, maxX do
                if shape[y][x] == 1 then
                    local gridX = self.tetrominoX + x
                    local gridY = dropY + y
                    
                    if gridY > 0 and self.grid[gridY][gridX] > 0 then
                        collision = true
                        break
                    end
                end
            end
            if collision then break end
        end
        
        if collision then
            dropY = dropY - 1
            break
        end
    end
    
    return dropY
end

-- 绘制当前方块（优化版）
function Game:drawTetromino()
    if self.state ~= "playing" then
        return
    end
    
    local shape = self.currentTetromino:getShape()
    local colorType = self.currentTetromino:getType()
    local color = Tetromino.getColorForType(colorType)
    
    -- 绘制硬降落预览
    love.graphics.setColor(color[1], color[2], color[3], 0.3) -- 半透明
    
    -- 计算硬降落位置（只在需要时计算，避免每帧重复计算）
    if not self.hardDropY or self.needUpdateHardDrop then
        self.hardDropY = self:calculateHardDropPosition()
        self.needUpdateHardDrop = false
    end
    
    -- 绘制硬降落预览
    for y = 1, 4 do
        for x = 1, 4 do
            if shape[y][x] == 1 then
                local blockX = BOARD_OFFSET_X + (self.tetrominoX + x - 1) * CELL_SIZE
                local blockY = BOARD_OFFSET_Y + (self.hardDropY + y - 1) * CELL_SIZE
                
                love.graphics.rectangle("fill", blockX, blockY, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(1, 1, 1, 0.2)
                love.graphics.rectangle("line", blockX, blockY, CELL_SIZE, CELL_SIZE)
                love.graphics.setColor(color[1], color[2], color[3], 0.3) -- 恢复半透明颜色
            end
        end
    end
    
    -- 绘制当前方块
    love.graphics.setColor(color)
    
    for y = 1, 4 do
        for x = 1, 4 do
            if shape[y][x] == 1 then
                -- 计算方块在游戏板上的位置
                local blockX = BOARD_OFFSET_X + (self.tetrominoX + x - 1) * CELL_SIZE
                local blockY = BOARD_OFFSET_Y + (self.tetrominoY + y - 1) * CELL_SIZE
                
                -- 绘制方块
                love.graphics.rectangle("fill", blockX, blockY, CELL_SIZE, CELL_SIZE)
                
                -- 绘制方块边框
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("line", blockX, blockY, CELL_SIZE, CELL_SIZE)
                
                -- 绘制方块高光
                love.graphics.setColor(1, 1, 1, 0.2)
                love.graphics.line(blockX, blockY, blockX + CELL_SIZE, blockY)
                love.graphics.line(blockX, blockY, blockX, blockY + CELL_SIZE)
                
                -- 恢复方块颜色
                love.graphics.setColor(color)
            end
        end
    end
end

-- 绘制下一个方块预览
function Game:drawNextTetromino()
    -- 绘制预览区域背景
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 
        PREVIEW_OFFSET_X - 10, 
        PREVIEW_OFFSET_Y - 10, 
        UI_PANEL_WIDTH + 20, 
        180
    )
    
    -- 绘制预览区域边框
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", 
        PREVIEW_OFFSET_X - 10, 
        PREVIEW_OFFSET_Y - 10, 
        UI_PANEL_WIDTH + 20, 
        180
    )
    
    -- 绘制预览标题
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        "下一个方块",
        PREVIEW_OFFSET_X,
        PREVIEW_OFFSET_Y,
        UI_PANEL_WIDTH,
        "center"
    )
    
    -- 绘制下一个方块
    local shape = self.nextTetromino:getShape()
    local colorType = self.nextTetromino:getType()
    local color = Tetromino.getColorForType(colorType)
    
    love.graphics.setColor(color)
    
    -- 计算预览区域中心位置
    local previewCenterX = PREVIEW_OFFSET_X + UI_PANEL_WIDTH / 2
    local previewCenterY = PREVIEW_OFFSET_Y + 100
    
    -- 绘制方块
    for y = 1, 4 do
        for x = 1, 4 do
            if shape[y][x] == 1 then
                love.graphics.rectangle("fill", 
                    previewCenterX + (x - 2.5) * CELL_SIZE, 
                    previewCenterY + (y - 2.5) * CELL_SIZE, 
                    CELL_SIZE, 
                    CELL_SIZE
                )
                
                -- 绘制方块边框
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.rectangle("line", 
                    previewCenterX + (x - 2.5) * CELL_SIZE, 
                    previewCenterY + (y - 2.5) * CELL_SIZE, 
                    CELL_SIZE, 
                    CELL_SIZE
                )
                
                -- 恢复方块颜色
                love.graphics.setColor(color)
            end
        end
    end
end

-- 绘制UI
function Game:drawUI()
    -- 使用缓存的字体
    if not self.uiFont then
        self.uiFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, 16)
    end
    
    -- 绘制UI面板背景
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 
        UI_OFFSET_X - 10, 
        UI_OFFSET_Y - 10, 
        UI_PANEL_WIDTH + 20, 
        350
    )
    
    -- 绘制UI面板边框
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", 
        UI_OFFSET_X - 10, 
        UI_OFFSET_Y - 10, 
        UI_PANEL_WIDTH + 20, 
        350
    )
    
    -- 绘制游戏信息
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.uiFont)
    
    -- 游戏信息标题
    love.graphics.printf(
        "游戏信息",
        UI_OFFSET_X,
        UI_OFFSET_Y,
        UI_PANEL_WIDTH,
        "center"
    )
    
    -- 分数
    love.graphics.printf(
        string.format("分数: %d", self.score),
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 2,
        UI_PANEL_WIDTH,
        "left"
    )
    
    -- 等级
    love.graphics.printf(
        string.format("等级: %d", self.level),
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 3.5,
        UI_PANEL_WIDTH,
        "left"
    )
    
    -- 消除行数
    love.graphics.printf(
        string.format("消除行数: %d", self.lines),
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 5,
        UI_PANEL_WIDTH,
        "left"
    )
    
    -- 难度
    local currentLevel = DifficultyConfig:getCurrentLevel()
    love.graphics.printf(
        string.format("难度: %s", currentLevel.name),
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 6.5,
        UI_PANEL_WIDTH,
        "left"
    )
    
    -- 下落速度
    love.graphics.printf(
        string.format("下落速度: %.1f秒/行", currentLevel.dropSpeed),
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 8,
        UI_PANEL_WIDTH,
        "left"
    )
    
    -- 分数倍率
    love.graphics.printf(
        string.format("分数倍率: %.1fx", currentLevel.scoreMultiplier),
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 9.5,
        UI_PANEL_WIDTH,
        "left"
    )
    
    -- 操作说明标题
    love.graphics.printf(
        "操作说明",
        UI_OFFSET_X,
        UI_OFFSET_Y + UI_TEXT_PADDING * 11.5,
        UI_PANEL_WIDTH,
        "center"
    )
    
    -- 操作说明内容
    local controls = {
        "← →: 左右移动",
        "↑: 旋转",
        "↓: 加速下落",
        "空格: 直接下落",
        "P: 暂停/继续",
        "M: 返回主菜单",
        "R: 重新开始"
    }
    
    for i, control in ipairs(controls) do
        love.graphics.printf(
            control,
            UI_OFFSET_X,
            UI_OFFSET_Y + UI_TEXT_PADDING * (13 + i),
            UI_PANEL_WIDTH,
            "left"
        )
    end
end

-- 键盘按下事件处理
function Game:keypressed(key)
    if self.state == "gameover" then
        if key == "r" then
            -- 重新开始游戏
            local newGame = Game.new()
            for k, v in pairs(newGame) do
                self[k] = v
            end
        end
        return
    end
    
    if key == "p" then
        -- 暂停/继续游戏
        if self.state == "playing" then
            self.state = "paused"
        else
            self.state = "playing"
        end
        return
    end
    
    if self.state ~= "playing" then
        return
    end
    
    if key == "left" then
        self:moveTetrominoLeft()
    elseif key == "right" then
        self:moveTetrominoRight()
    elseif key == "down" then
        self:moveTetrominoDown()
    elseif key == "up" then
        self:rotateTetromino()
    elseif key == "space" then
        -- 硬降（直接下落到底部）
        while not self:moveTetrominoDown() do
            -- 继续下落直到不能下落
        end
    end
end

-- 键盘释放事件处理
function Game:keyreleased(key)
    -- 暂时不需要处理键盘释放事件
end

-- 向下移动方块
function Game:moveTetrominoDown()
    self.tetrominoY = self.tetrominoY + 1
    
    if self:checkCollision() then
        self.tetrominoY = self.tetrominoY - 1
        self:lockTetromino()
        self:clearLines()
        self:spawnTetromino()
        
        if self:isGameOver() then
            self.state = "gameover"
        end
        
        -- 更新方块批处理
        self:updateBlockBatches()
        return true -- 表示已锁定
    end
    
    -- 标记需要更新硬降落位置
    self.needUpdateHardDrop = true
    
    return false -- 表示未锁定
end

-- 向左移动方块
function Game:moveTetrominoLeft()
    self.tetrominoX = self.tetrominoX - 1
    
    if self:checkCollision() then
        self.tetrominoX = self.tetrominoX + 1
        return false
    end
    
    -- 标记需要更新硬降落位置
    self.needUpdateHardDrop = true
    
    return true
end

-- 向右移动方块
function Game:moveTetrominoRight()
    self.tetrominoX = self.tetrominoX + 1
    
    if self:checkCollision() then
        self.tetrominoX = self.tetrominoX - 1
        return false
    end
    
    -- 标记需要更新硬降落位置
    self.needUpdateHardDrop = true
    
    return true
end

-- 旋转方块
function Game:rotateTetromino()
    self.currentTetromino:rotate()
    
    if self:checkCollision() then
        -- 如果旋转后发生碰撞，尝试左右移动以适应旋转
        local originalX = self.tetrominoX
        
        -- 尝试向右移动
        self.tetrominoX = self.tetrominoX + 1
        if not self:checkCollision() then
            -- 标记需要更新硬降落位置
            self.needUpdateHardDrop = true
            return true
        end
        
        -- 尝试向左移动
        self.tetrominoX = originalX - 1
        if not self:checkCollision() then
            -- 标记需要更新硬降落位置
            self.needUpdateHardDrop = true
            return true
        end
        
        -- 如果都不行，恢复原位置并取消旋转
        self.tetrominoX = originalX
        self.currentTetromino:rotate()
        self.currentTetromino:rotate()
        self.currentTetromino:rotate()
        return false
    end
    
    -- 标记需要更新硬降落位置
    self.needUpdateHardDrop = true
    
    return true
end

-- 检查碰撞（优化版）
function Game:checkCollision()
    local shape = self.currentTetromino:getShape()
    local minX, maxX, minY, maxY = 4, 1, 4, 1
    
    -- 快速确定方块的实际边界
    for y = 1, 4 do
        for x = 1, 4 do
            if shape[y][x] == 1 then
                minX = math.min(minX, x)
                maxX = math.max(maxX, x)
                minY = math.min(minY, y)
                maxY = math.max(maxY, y)
            end
        end
    end
    
    -- 快速边界检查
    if self.tetrominoX + minX < 1 or self.tetrominoX + maxX > GRID_WIDTH or
       self.tetrominoY + minY < 1 or self.tetrominoY + maxY > GRID_HEIGHT then
        return true
    end
    
    -- 只检查实际占用的区域
    for y = minY, maxY do
        for x = minX, maxX do
            if shape[y][x] == 1 then
                local gridX = self.tetrominoX + x
                local gridY = self.tetrominoY + y
                
                if gridY > 0 and self.grid[gridY][gridX] > 0 then
                    return true
                end
            end
        end
    end
    
    return false
end

-- 锁定方块
function Game:lockTetromino()
    local shape = self.currentTetromino:getShape()
    local colorType = self.currentTetromino:getType()
    
    for y = 1, 4 do
        for x = 1, 4 do
            if shape[y][x] == 1 then
                local gridX = self.tetrominoX + x
                local gridY = self.tetrominoY + y
                
                if gridY > 0 and gridY <= GRID_HEIGHT and gridX > 0 and gridX <= GRID_WIDTH then
                    self.grid[gridY][gridX] = colorType
                end
            end
        end
    end
    
    -- 清除完整的行
    self:clearLines()
    
    -- 生成新方块
    self:spawnTetromino()
    
    -- 检查游戏是否结束
    if self:isGameOver() then
        self.state = "gameover"
    end
end

-- 清除完整的行
function Game:clearLines()
    local linesCleared = 0
    
    for y = GRID_HEIGHT, 1, -1 do
        local isLineFull = true
        
        for x = 1, GRID_WIDTH do
            if self.grid[y][x] == 0 then
                isLineFull = false
                break
            end
        end
        
        if isLineFull then
            -- 使用table.move高效移动行
            for moveY = y, 2, -1 do
                table.move(self.grid[moveY - 1], 1, GRID_WIDTH, 1, self.grid[moveY])
            end
            
            -- 清空最上面的行（优化：预先创建空行）
            for x = 1, GRID_WIDTH do
                self.grid[1][x] = 0
            end
            
            -- 行数加1，但y不变（因为当前行已经被上面的行替换）
            linesCleared = linesCleared + 1
            y = y + 1 -- 重新检查当前行，因为它现在包含了新的内容
        end
    end
    
    -- 更新分数和等级
    if linesCleared > 0 then
        -- 根据消除的行数计算得分
        local points = {40, 100, 300, 1200} -- 1行=40分，2行=100分，3行=300分，4行=1200分
        self.score = self.score + points[linesCleared] * self.level
        
        -- 更新总消除行数
        self.lines = self.lines + linesCleared
        
        -- 每消除10行提升一个等级
        self.level = math.floor(self.lines / 10) + 1
        
        -- 随着等级提高，下落速度加快
        self.dropSpeed = math.max(0.1, 1.0 - (self.level - 1) * 0.1)
        
        -- 播放消除音效
        AudioConfig:play("clear")
    end
end

-- 生成新方块
function Game:spawnTetromino()
    -- 当前方块变为下一个方块
    self.currentTetromino = self.nextTetromino
    
    -- 生成新的下一个方块
    self.nextTetromino = Tetromino.new()
    
    -- 重置方块位置
    self.tetrominoX = math.floor(GRID_WIDTH / 2) - 1
    self.tetrominoY = 0
end

-- 检查游戏是否结束
function Game:isGameOver()
    -- 如果新生成的方块一出现就发生碰撞，则游戏结束
    return self:checkCollision()
end

return Game