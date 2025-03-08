-- 俄罗斯方块游戏 - 基于LÖVE框架
-- main.lua - 游戏主入口

-- 导入游戏模块
local Game = require 'game'
local FontConfig = require 'fonts.config'

-- 游戏全局变量
local game
local defaultFont

-- LÖVE初始化函数
function love.load()
    -- 设置随机种子
    math.randomseed(os.time())
    
    -- 加载默认字体
    defaultFont = love.graphics.newFont(FontConfig.DEFAULT_FONT_PATH, FontConfig.NORMAL_SIZE)
    love.graphics.setFont(defaultFont)
    
    -- 设置窗口标题
    love.window.setTitle("俄罗斯方块")
    
    -- 设置窗口大小
    love.window.setMode(800, 650, {
        vsync = true,
        resizable = false,
        minwidth = 800,
        minheight = 650
    })
    
    -- 初始化游戏
    game = Game.new()
end

-- LÖVE更新函数 - 每帧调用
function love.update(dt)
    game:update(dt)
end

-- LÖVE绘制函数
function love.draw()
    game:draw()
end

-- 键盘按下事件
function love.keypressed(key)
    if key == "escape" then
        -- 如果在排行榜界面，按ESC返回主菜单
        if game.state == "highscores" then
            game.state = "menu"
        else
            love.event.quit()
        end
    else
        game:keypressed(key)
    end
end

-- 键盘释放事件
function love.keyreleased(key)
    game:keyreleased(key)
end