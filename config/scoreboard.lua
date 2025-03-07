-- 俄罗斯方块游戏 - 分数排行榜配置
-- config/scoreboard.lua

local ScoreboardConfig = {
    -- 最高分记录数量
    MAX_RECORDS = 10,
    
    -- 分数记录
    records = {},
    
    -- 保存文件路径
    SAVE_FILE = "tetris_scores.dat",
    
    -- 初始化排行榜
    init = function(self)
        self:load()
    end,
    
    -- 添加新分数
    addScore = function(self, score, level, lines)
        local newRecord = {
            score = score,
            level = level,
            lines = lines,
            date = os.date("%Y-%m-%d %H:%M")
        }
        
        -- 插入新记录
        table.insert(self.records, newRecord)
        
        -- 按分数排序
        table.sort(self.records, function(a, b)
            return a.score > b.score
        end)
        
        -- 保留前N条记录
        while #self.records > self.MAX_RECORDS do
            table.remove(self.records)
        end
        
        -- 保存记录
        self:save()
        
        -- 返回新记录在排行榜中的位置
        for i, record in ipairs(self.records) do
            if record == newRecord then
                return i
            end
        end
        
        return nil
    end,
    
    -- 保存排行榜
    save = function(self)
        local file = io.open(self.SAVE_FILE, "w")
        if not file then return false end
        
        for _, record in ipairs(self.records) do
            file:write(string.format("%d,%d,%d,%s\n", 
                record.score, 
                record.level, 
                record.lines, 
                record.date))
        end
        
        file:close()
        return true
    end,
    
    -- 加载排行榜
    load = function(self)
        self.records = {}
        
        local file = io.open(self.SAVE_FILE, "r")
        if not file then return false end
        
        for line in file:lines() do
            local score, level, lines, date = line:match("(%d+),(%d+),(%d+),(.+)")
            if score then
                table.insert(self.records, {
                    score = tonumber(score),
                    level = tonumber(level),
                    lines = tonumber(lines),
                    date = date
                })
            end
        end
        
        file:close()
        
        -- 按分数排序
        table.sort(self.records, function(a, b)
            return a.score > b.score
        end)
        
        return true
    end,
    
    -- 获取排行榜
    getRecords = function(self)
        return self.records
    end,
    
    -- 清空排行榜
    clear = function(self)
        self.records = {}
        self:save()
    end
}

return ScoreboardConfig