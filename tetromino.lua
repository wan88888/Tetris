-- 俄罗斯方块游戏 - 方块模块
-- tetromino.lua

-- 方块类
local Tetromino = {}

-- 性能优化：预计算所有方块的所有旋转状态
local CACHED_ROTATIONS = {}

-- 方块形状定义 (1-7)
-- 每个方块由4x4的网格表示，1表示有方块，0表示空
local SHAPES = {
    -- I形方块 (青色)
    {
        {0, 0, 0, 0},
        {1, 1, 1, 1},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    -- J形方块 (蓝色)
    {
        {1, 0, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    -- L形方块 (橙色)
    {
        {0, 0, 1, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    -- O形方块 (黄色)
    {
        {0, 1, 1, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    -- S形方块 (绿色)
    {
        {0, 1, 1, 0},
        {1, 1, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    -- T形方块 (紫色)
    {
        {0, 1, 0, 0},
        {1, 1, 1, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    },
    -- Z形方块 (红色)
    {
        {1, 1, 0, 0},
        {0, 1, 1, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    }
}

-- 方块颜色定义
local COLORS = {
    {0, 1, 1},    -- 青色 (I)
    {0, 0, 1},    -- 蓝色 (J)
    {1, 0.5, 0},  -- 橙色 (L)
    {1, 1, 0},    -- 黄色 (O)
    {0, 1, 0},    -- 绿色 (S)
    {0.5, 0, 0.5},-- 紫色 (T)
    {1, 0, 0}     -- 红色 (Z)
}

-- 初始化预计算的旋转状态缓存
local function initRotationCache()
    if next(CACHED_ROTATIONS) ~= nil then
        return -- 已经初始化过了
    end
    
    for type = 1, 7 do
        CACHED_ROTATIONS[type] = {}
        
        -- 初始形状（0度旋转）
        CACHED_ROTATIONS[type][0] = {}
        for y = 1, 4 do
            CACHED_ROTATIONS[type][0][y] = {}
            for x = 1, 4 do
                CACHED_ROTATIONS[type][0][y][x] = SHAPES[type][y][x]
            end
        end
        
        -- 计算90度、180度和270度旋转
        for rotation = 1, 3 do
            CACHED_ROTATIONS[type][rotation] = {}
            for y = 1, 4 do
                CACHED_ROTATIONS[type][rotation][y] = {}
            end
            
            local prevRotation = CACHED_ROTATIONS[type][rotation-1]
            for y = 1, 4 do
                for x = 1, 4 do
                    -- 90度旋转公式：(x,y) -> (y,5-x)
                    CACHED_ROTATIONS[type][rotation][y][x] = prevRotation[5-x][y]
                end
            end
        end
    end
end

-- 获取方块颜色
function Tetromino.getColorForType(type)
    if type >= 1 and type <= 7 then
        return COLORS[type]
    else
        -- 默认返回白色
        return {1, 1, 1}
    end
end

-- 创建新方块实例
function Tetromino.new()
    -- 确保旋转缓存已初始化
    initRotationCache()
    
    local self = {}
    
    -- 随机选择方块类型 (1-7)
    self.type = math.random(1, 7)
    
    -- 当前旋转状态 (0-3)
    self.rotation = 0
    
    -- 方法绑定
    self.getShape = Tetromino.getShape
    self.getType = Tetromino.getType
    self.rotate = Tetromino.rotate
    
    return self
end

-- 获取方块形状（优化版，直接使用缓存）
function Tetromino:getShape()
    -- 直接返回预计算的旋转形状
    return CACHED_ROTATIONS[self.type][self.rotation]
end

-- 获取方块类型
function Tetromino:getType()
    return self.type
end

-- 旋转方块
function Tetromino:rotate()
    -- 更新旋转状态 (0-3)
    self.rotation = (self.rotation + 1) % 4
end

return Tetromino