-- 俄罗斯方块游戏 - 难度配置
-- config/difficulty.lua

local DifficultyConfig = {
    -- 难度级别
    LEVELS = {
        {
            name = "简单",
            dropSpeed = 1.0,
            scoreMultiplier = 1.0
        },
        {
            name = "中等",
            dropSpeed = 0.7,
            scoreMultiplier = 1.5
        },
        {
            name = "困难",
            dropSpeed = 0.4,
            scoreMultiplier = 2.0
        },
        {
            name = "专家",
            dropSpeed = 0.2,
            scoreMultiplier = 3.0
        }
    },
    
    -- 当前选择的难度级别
    currentLevel = 1,
    
    -- 初始化难度设置
    init = function(self)
        -- 如果需要从配置文件加载难度设置，可以在这里实现
        -- 目前仅确保当前难度级别在有效范围内
        if self.currentLevel < 1 or self.currentLevel > #self.LEVELS then
            self.currentLevel = 1
        end
    end,
    
    -- 获取当前难度设置
    getCurrentLevel = function(self)
        return self.LEVELS[self.currentLevel]
    end,
    
    -- 设置难度级别
    setLevel = function(self, level)
        if level >= 1 and level <= #self.LEVELS then
            self.currentLevel = level
            return true
        end
        return false
    end,
    
    -- 获取下一个难度级别
    nextLevel = function(self)
        local nextLevel = self.currentLevel + 1
        if nextLevel > #self.LEVELS then
            nextLevel = 1
        end
        self:setLevel(nextLevel)
        return self:getCurrentLevel()
    end
}

return DifficultyConfig