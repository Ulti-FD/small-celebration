local t = Def.ActorFrame {Name = "PlayerInfoFrame"}

local visEnabled = Var("visualizer")

local ratios = {
    Height = 109 / 1080,
    Width = 1,
    AvatarWidth = 109 / 1920, -- this should end up square
    ConnectionLogoLeftGap = 76 / 1920,
    ConnectionLogoSize = 36 / 1920, -- this is 36x36
    LeftTextLeftGap = 8 / 1920, -- this is after the avatar
    LeftTextTopGap1 = 24 / 1080, -- from top to center of line 1
    LeftTextTopGap2 = 49 / 1080, -- from top to center of line 2
    LeftTextTopGap3 = 72 / 1080, -- from top to center of line 3
    LeftTextTopGap4 = 95 / 1080, -- from top to center of line 4
    RightTextLeftGap = 412 / 1920, -- this is from avatar to right text
    RightTextTopGap1 = 25 / 1080, -- why did this have to be different from Left line 1
    RightTextTopGap2 = 54 / 1080, -- from top to center of line 2
    RightTextTopGap3 = 89 / 1080, -- from top to center of line 3
    VisualizerLeftGap = 707 / 1920, -- from left side of screen to leftmost bin
    VisualizerWidth = 693 / 1920,
    IconUpperGap = 36 / 1080,
    IconExitWidth = 47 / 1920,
    IconExitHeight = 36 / 1080,
    IconExitRightGap = 38 / 1920, -- from right side of screen to right end of icon
    IconSettingsWidth = 44 / 1920,
    IconSettingsHeight = 35 / 1080,
    IconSettingsRightGap = 123 / 1920,
    IconHelpWidth = 36 / 1920,
    IconHelpHeight = 36 / 1080,
    IconHelpRightGap = 205 / 1920,
    IconDownloadsWidth = 51 / 1920,
    IconDownloadsHeight = 36 / 1080,
    IconDownloadsRightGap = 278 / 1920,
    IconRandomWidth = 41 / 1920,
    IconRandomHeight = 36 / 1080,
    IconRandomRightGap = 367 / 1920,
    IconSearchWidth = 36 / 1920,
    IconSearchHeight = 36 / 1080,
    IconSearchRightGap = 446 / 1920,
}

local actuals = {
    Height = ratios.Height * SCREEN_HEIGHT,
    Width = ratios.Width * SCREEN_WIDTH,
    AvatarWidth = ratios.AvatarWidth * SCREEN_WIDTH,
    ConnectionLogoLeftGap = ratios.ConnectionLogoLeftGap * SCREEN_WIDTH,
    ConnectionLogoSize = ratios.ConnectionLogoSize * SCREEN_WIDTH,
    LeftTextLeftGap = ratios.LeftTextLeftGap * SCREEN_WIDTH,
    LeftTextTopGap1 = ratios.LeftTextTopGap1 * SCREEN_HEIGHT,
    LeftTextTopGap2 = ratios.LeftTextTopGap2 * SCREEN_HEIGHT,
    LeftTextTopGap3 = ratios.LeftTextTopGap3 * SCREEN_HEIGHT,
    LeftTextTopGap4 = ratios.LeftTextTopGap4 * SCREEN_HEIGHT,
    RightTextLeftGap = ratios.RightTextLeftGap * SCREEN_WIDTH,
    RightTextTopGap1 = ratios.RightTextTopGap1 * SCREEN_HEIGHT,
    RightTextTopGap2 = ratios.RightTextTopGap2 * SCREEN_HEIGHT,
    RightTextTopGap3 = ratios.RightTextTopGap3 * SCREEN_HEIGHT,
    VisualizerLeftGap = ratios.VisualizerLeftGap * SCREEN_WIDTH,
    VisualizerWidth = ratios.VisualizerWidth * SCREEN_WIDTH,
    IconUpperGap = ratios.IconUpperGap * SCREEN_HEIGHT,
    IconExitWidth = ratios.IconExitWidth * SCREEN_WIDTH,
    IconExitHeight = ratios.IconExitHeight * SCREEN_HEIGHT,
    IconExitRightGap = ratios.IconExitRightGap * SCREEN_WIDTH,
    IconSettingsWidth = ratios.IconSettingsWidth * SCREEN_WIDTH,
    IconSettingsHeight = ratios.IconSettingsHeight * SCREEN_HEIGHT,
    IconSettingsRightGap = ratios.IconSettingsRightGap * SCREEN_WIDTH,
    IconHelpWidth = ratios.IconHelpWidth * SCREEN_WIDTH,
    IconHelpHeight = ratios.IconHelpHeight * SCREEN_HEIGHT,
    IconHelpRightGap = ratios.IconHelpRightGap * SCREEN_WIDTH,
    IconDownloadsWidth = ratios.IconDownloadsWidth * SCREEN_WIDTH,
    IconDownloadsHeight = ratios.IconDownloadsHeight * SCREEN_HEIGHT,
    IconDownloadsRightGap = ratios.IconDownloadsRightGap * SCREEN_WIDTH,
    IconRandomWidth = ratios.IconRandomWidth * SCREEN_WIDTH,
    IconRandomHeight = ratios.IconRandomHeight * SCREEN_HEIGHT,
    IconRandomRightGap = ratios.IconRandomRightGap * SCREEN_WIDTH,
    IconSearchWidth = ratios.IconSearchWidth * SCREEN_WIDTH,
    IconSearchHeight = ratios.IconSearchHeight * SCREEN_HEIGHT,
    IconSearchRightGap = ratios.IconSearchRightGap * SCREEN_WIDTH,
}

local visualizerBins = 126
local leftTextBigSize = 0.7
local leftTextSmallSize = 0.65
local rightTextSize = 0.7
local textzoomFudge = 5 -- for gaps in maxwidth

local profile = GetPlayerOrMachineProfile(PLAYER_1)
local pname = profile:GetDisplayName()
local pcount = SCOREMAN:GetTotalNumberOfScores()
local parrows = profile:GetTotalTapsAndHolds()
local ptime = profile:GetTotalSessionSeconds()
local offlinerating = profile:GetPlayerRating()
local onlinerating = DLMAN:IsLoggedIn() and DLMAN:GetSkillsetRating("Overall") or 0

t[#t+1] = Def.Quad {
    Name = "BG",
    InitCommand = function(self)
        self:halign(0):valign(0)
        self:zoomto(actuals.Width, actuals.Height)
        self:diffuse(color("0,0,0,0.8"))
    end
}

t[#t+1] = Def.Sprite {
    Name = "Avatar",
    InitCommand = function(self)
        self:halign(0):valign(0)
    end,
    BeginCommand = function(self)
        self:Load(getAvatarPath(PLAYER_1))
        self:zoomto(actuals.AvatarWidth, actuals.AvatarWidth)
    end
}

t[#t+1] = Def.Sprite {
    Name = "ConnectionSprite",
    InitCommand = function(self)
        self:halign(0):valign(1)
        self:xy(actuals.ConnectionLogoLeftGap, actuals.Height)
    end,
    BeginCommand = function(self)
        self:Load(THEME:GetPathG("", "loggedin"))
        self:zoomto(actuals.ConnectionLogoSize, actuals.ConnectionLogoSize)
    end
}

t[#t+1] = Def.ActorFrame {
    Name = "LeftText",
    InitCommand = function(self)
        self:x(actuals.AvatarWidth + actuals.LeftTextLeftGap)
    end,

    LoadFont("Common Normal") .. {
        Name = "NameRank",
        InitCommand = function(self)
            self:y(actuals.LeftTextTopGap1)
            self:halign(0)
            self:zoom(leftTextBigSize)
            self:maxwidth((actuals.RightTextLeftGap - actuals.LeftTextLeftGap) / leftTextBigSize - textzoomFudge)
            self:settextf("%s (#9999)", pname)
        end
    },
    LoadFont("Common Normal") .. {
        Name = "Playcount",
        InitCommand = function(self)
            self:y(actuals.LeftTextTopGap2)
            self:halign(0)
            self:zoom(leftTextSmallSize)
            self:maxwidth((actuals.RightTextLeftGap - actuals.LeftTextLeftGap) / leftTextSmallSize - textzoomFudge)
            self:settextf("%d plays", pcount)
        end
    },
    LoadFont("Common Normal") .. {
        Name = "Arrows",
        InitCommand = function(self)
            self:y(actuals.LeftTextTopGap3)
            self:halign(0)
            self:zoom(leftTextSmallSize)
            self:maxwidth((actuals.RightTextLeftGap - actuals.LeftTextLeftGap) / leftTextSmallSize - textzoomFudge)
            self:settextf("%d arrows smashed", parrows)
        end
    },
    LoadFont("Common Normal") .. {
        Name = "Playtime",
        InitCommand = function(self)
            self:y(actuals.LeftTextTopGap4)
            self:halign(0)
            self:zoom(leftTextSmallSize)
            self:maxwidth((actuals.RightTextLeftGap - actuals.LeftTextLeftGap) / leftTextSmallSize - textzoomFudge)
            self:settextf("%s playtime", SecondsToHHMMSS(ptime))
        end
    }
}

t[#t+1] = Def.ActorFrame {
    Name = "RightText",
    InitCommand = function(self)
        self:x(actuals.AvatarWidth + actuals.RightTextLeftGap)
    end,

    LoadFont("Common Normal") .. {
        Name = "Header",
        InitCommand = function(self)
            self:y(actuals.RightTextTopGap1)
            self:halign(0)
            self:zoom(rightTextSize)
            self:maxwidth((actuals.VisualizerLeftGap - actuals.RightTextLeftGap - actuals.AvatarWidth) / rightTextSize - textzoomFudge)
            self:settext("Player Ratings:")
        end
    },
    LoadFont("Common Normal") .. {
        Name = "OnlineRating",
        InitCommand = function(self)
            self:y(actuals.RightTextTopGap2)
            self:halign(0)
            self:zoom(rightTextSize)
            self:maxwidth((actuals.VisualizerLeftGap - actuals.RightTextLeftGap - actuals.AvatarWidth) / rightTextSize - textzoomFudge)
            self:settextf("Online - %5.2f", onlinerating)
        end
    },
    LoadFont("Common Normal") .. {
        Name = "OfflineRating",
        InitCommand = function(self)
            self:y(actuals.RightTextTopGap3)
            self:halign(0)
            self:zoom(rightTextSize)
            self:maxwidth((actuals.VisualizerLeftGap - actuals.RightTextLeftGap - actuals.AvatarWidth) / rightTextSize - textzoomFudge)
            self:settextf("Offline - %5.2f", offlinerating)
        end
    }
}

t[#t+1] = Def.ActorFrame {
    Name = "Icons",
    InitCommand = function(self)
        self:xy(SCREEN_WIDTH, actuals.IconUpperGap)
    end,

    Def.Sprite {
        Name = "Exit",
        Texture = THEME:GetPathG("", "exit"),
        InitCommand = function(self)
            self:halign(1):valign(0)
            self:x(-actuals.IconExitRightGap)
            self:zoomto(actuals.IconExitWidth, actuals.IconExitHeight)
        end
    },
    Def.Sprite {
        Name = "Settings",
        Texture = THEME:GetPathG("", "settings"),
        InitCommand = function(self)
            self:halign(1):valign(0)
            self:x(-actuals.IconSettingsRightGap)
            self:zoomto(actuals.IconSettingsWidth, actuals.IconSettingsHeight)
        end
    },
    Def.Sprite {
        Name = "Help",
        Texture = THEME:GetPathG("", "gameinfoandhelp"),
        InitCommand = function(self)
            self:halign(1):valign(0)
            self:x(-actuals.IconHelpRightGap)
            self:zoomto(actuals.IconHelpWidth, actuals.IconHelpHeight)
        end
    },
    Def.Sprite {
        Name = "Downloads",
        Texture = THEME:GetPathG("", "packdownloads"),
        InitCommand = function(self)
            self:halign(1):valign(0)
            self:x(-actuals.IconDownloadsRightGap)
            self:zoomto(actuals.IconDownloadsWidth, actuals.IconDownloadsHeight)
        end
    },
    Def.Sprite {
        Name = "Random",
        Texture = THEME:GetPathG("", "random"),
        InitCommand = function(self)
            self:halign(1):valign(0)
            self:x(-actuals.IconRandomRightGap)
            self:zoomto(actuals.IconRandomWidth, actuals.IconRandomHeight)
        end
    },
    Def.Sprite {
        Name = "Search",
        Texture = THEME:GetPathG("", "search"),
        InitCommand = function(self)
            self:halign(1):valign(0)
            self:x(-actuals.IconSearchRightGap)
            self:zoomto(actuals.IconSearchWidth, actuals.IconSearchHeight)
        end
    }
}


if visEnabled then
    local intervals = {0, 10, 26, 48, 60, 92, 120, 140, 240, 400, 800, 1600, 2600, 3500, 4000}
    t[#t+1] = audioVisualizer:new {
        x = actuals.VisualizerLeftGap,
        y = actuals.Height,
        width = actuals.VisualizerWidth,
        maxHeight = actuals.Height / 1.8,
        freqIntervals = audioVisualizer.multiplyIntervals(intervals, 9),
        color = color("1,1,1,1"),
        onBarUpdate = function(self)
            -- hmm
        end
    }
end

return t