-- 俄罗斯方块游戏 - 音频配置
-- audio/config.lua

local AudioConfig = {
    -- 音效文件路径
    MOVE_SOUND = "audio/move.wav",
    ROTATE_SOUND = "audio/rotate.wav",
    DROP_SOUND = "audio/drop.wav",
    CLEAR_SOUND = "audio/clear.wav",
    GAMEOVER_SOUND = "audio/gameover.wav",

    -- 音效对象
    sounds = {},

    -- 初始化音效
    init = function(self)
        -- 加载所有音效
        self.sounds.move = love.audio.newSource(self.MOVE_SOUND, "static")
        self.sounds.rotate = love.audio.newSource(self.ROTATE_SOUND, "static")
        self.sounds.drop = love.audio.newSource(self.DROP_SOUND, "static")
        self.sounds.clear = love.audio.newSource(self.CLEAR_SOUND, "static")
        self.sounds.gameover = love.audio.newSource(self.GAMEOVER_SOUND, "static")

        -- 设置音量
        for _, sound in pairs(self.sounds) do
            sound:setVolume(0.5)
        end
    end,

    -- 播放音效
    play = function(self, soundName)
        if self.sounds[soundName] then
            self.sounds[soundName]:stop()
            self.sounds[soundName]:play()
        end
    end
}

return AudioConfig