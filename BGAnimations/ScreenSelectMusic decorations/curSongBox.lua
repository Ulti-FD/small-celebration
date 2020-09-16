local displayScore
local lastHovered
local t = Def.ActorFrame {
    Name = "CurSongBoxFile",
    WheelSettledMessageCommand = function(self, params)
        -- update displayscore
        -- it sets to nil properly by itself
        displayScore = GetDisplayScore()

        lastHovered = params.hovered

        -- cascade visual update to everything
        self:playcommand("Set", {song = params.song, group = params.group, hovered = params.hovered, steps = params.steps})
    end,
    CurrentRateChangedMessageCommand = function(self)
        self:playcommand("Set", {song = GAMESTATE:GetCurrentSong(), hovered = lastHovered, steps = GAMESTATE:GetCurrentSteps(PLAYER_1)})
    end,
    ChangedStepsMessageCommand = function(self, params)
        self:playcommand("Set", {song = GAMESTATE:GetCurrentSong(), hovered = lastHovered, steps = params.steps})
    end
}

local ratios = {
    LeftGap = 1055 / 1920, -- distance from left side of screen to left side of frame
    TopGap = 131 / 1080, -- distance from top of screen to top of frame
    Height = 345 / 1080,
    Width = 777 / 1920,
    BannerHeight = 243 / 1080,
    LowerLipHeight = 34 / 1080,
    LeftTextLeftGap = 10 / 1920,
    TextLowerGap1 = 6 / 1080, -- subtracting 2 here because thats about how much letters go "down"
    TextLowerGap2 = 39 / 1080, -- these gaps are from bottom frame to bottom text
    TextLowerGap3 = 75 / 1080,
    BPMTextRightGap = 62 / 1920,
    BPMNumberRightGap = 12 / 1920, -- from right edge to right edge of numbers
    BPMWidth = 50 / 1920, -- from right edge of bpm number to right edge of bpm text
    LengthTextRightGap = 197 / 1920,
    LengthNumberRightGap = 135 / 1920, -- from right edge to right edge of numbers
    LengthWidth = 62 / 1920, -- from right edge of len number to right edge of len text

    DiffFrameLeftGap = 429 / 1920,
    DiffFrameRightGap = 12 / 1920, -- from right edge of frame to right edge of rightmost item
}

local actuals = {
    LeftGap = ratios.LeftGap * SCREEN_WIDTH,
    TopGap = ratios.TopGap * SCREEN_HEIGHT,
    Height = ratios.Height * SCREEN_HEIGHT,
    Width = ratios.Width * SCREEN_WIDTH,
    BannerHeight = ratios.BannerHeight * SCREEN_HEIGHT,
    LowerLipHeight = ratios.LowerLipHeight * SCREEN_HEIGHT,
    LeftTextLeftGap = ratios.LeftTextLeftGap * SCREEN_WIDTH,
    TextLowerGap1 = ratios.TextLowerGap1 * SCREEN_HEIGHT,
    TextLowerGap2 = ratios.TextLowerGap2 * SCREEN_HEIGHT,
    TextLowerGap3 = ratios.TextLowerGap3 * SCREEN_HEIGHT,
    BPMTextRightGap = ratios.BPMTextRightGap * SCREEN_WIDTH,
    BPMNumberRightGap = ratios.BPMNumberRightGap * SCREEN_WIDTH,
    BPMWidth = ratios.BPMWidth * SCREEN_WIDTH,
    LengthTextRightGap = ratios.LengthTextRightGap * SCREEN_WIDTH,
    LengthNumberRightGap = ratios.LengthNumberRightGap * SCREEN_WIDTH,
    LengthWidth = ratios.LengthWidth * SCREEN_WIDTH,

    DiffFrameLeftGap = ratios.DiffFrameLeftGap * SCREEN_WIDTH,
    DiffFrameRightGap = ratios.DiffFrameRightGap * SCREEN_WIDTH,
}

local textsize = 0.8
local textzoomFudge = 5

local buttonHoverAlpha = 0.8

t[#t+1] = Def.ActorFrame {
    Name = "Frame",
    InitCommand = function(self)
        self:xy(actuals.LeftGap, actuals.TopGap)
    end,
    BeginCommand = function(self)
        -- the math with the logic inline will make increments be 0.1x
        -- holding Select will do 0.05x increments
        local selectPressed = false
        SCREENMAN:GetTopScreen():AddInputCallback(function(event)
            if event.type == "InputEventType_FirstPress" then
                if event.button == "EffectUp" then
                    changeMusicRate(0.05 * (selectPressed and 1 or 2))
                elseif event.button == "EffectDown" then
                    changeMusicRate(-0.05 * (selectPressed and 1 or 2))
                elseif event.button == "Select" then
                    selectPressed = true
                end
            elseif event.type == "InputEventType_Release" then
                if event.button == "Select" then
                    selectPressed = false
                end
            end
        end)
    end,

    Def.Quad {
        Name = "BG",
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:zoomto(actuals.Width, actuals.Height)
            self:diffuse(color("#111111"))
            self:diffusealpha(0.6)
        end
    },
    Def.Quad {
        Name = "LowerLip",
        InitCommand = function(self)
            self:halign(0):valign(1)
            self:y(actuals.Height)
            self:zoomto(actuals.Width, actuals.LowerLipHeight)
            self:diffuse(color("#111111"))
            self:diffusealpha(0.6)
        end
    },
    Def.Sprite {
        Name = "Banner",
        InitCommand = function(self)
            self:halign(0):valign(0)
            self:scaletoclipped(actuals.Width, actuals.BannerHeight)
        end,
        SetCommand = function(self, params)
            self:finishtweening()
            self:smooth(0.05)
            self:diffusealpha(1)
            if params.song then
                local bnpath = params.song:GetBannerPath()
                if not bnpath then
                    bnpath = THEME:GetPathG("Common", "fallback banner")
                end
                self:LoadBackground(bnpath)
            else
                local bnpath = SONGMAN:GetSongGroupBannerPath(params.hovered)
                if not bnpath or bnpath == "" then
                    bnpath = THEME:GetPathG("Common", "fallback banner")
                end
                self:LoadBackground(bnpath)
            end
        end
    },
    LoadFont("Common Normal") .. {
        Name = "TitleAuthor",
        InitCommand = function(self)
            self:halign(0):valign(1)
            self:xy(actuals.LeftTextLeftGap, actuals.Height - actuals.TextLowerGap3)
            self:zoom(textsize)
            self:maxwidth((actuals.DiffFrameLeftGap - actuals.LeftTextLeftGap) / textsize - textzoomFudge)
            self:settext("Song Title - Song Author")
        end,
        SetCommand = function(self, params)
            if params.song then
                local title = params.song:GetDisplayMainTitle()
                local artist = params.song:GetDisplayArtist()
                self:settextf("%s - %s", title, artist)
            else
                self:settext("")
            end
        end,
        DisplayLanguageChangedMessageCommand = function(self)
            self:playcommand("Set", {song = GAMESTATE:GetCurrentSong()})
        end
    },
    LoadFont("Common Normal") .. {
        Name = "SubTitle",
        InitCommand = function(self)
            self:halign(0):valign(1)
            self:xy(actuals.LeftTextLeftGap, actuals.Height - actuals.TextLowerGap2)
            self:zoom(textsize)
            self:maxwidth((actuals.DiffFrameLeftGap - actuals.LeftTextLeftGap) / textsize - textzoomFudge)
            self:settext("Song SubTitle (1995)")
        end,
        SetCommand = function(self, params)
            if params.song then
                self:settext(params.song:GetDisplaySubTitle())
            else
                self:settext("")
            end
        end,
        DisplayLanguageChangedMessageCommand = function(self)
            self:playcommand("Set", {song = GAMESTATE:GetCurrentSong()})
        end
    },
    UIElements.TextButton(1, 1, "Common Normal") .. {
        Name = "Rate",
        InitCommand = function(self)
            self:xy(actuals.LeftTextLeftGap, actuals.Height - actuals.TextLowerGap1)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")

            txt:halign(0):valign(1)
            txt:zoom(textsize)
            txt:maxwidth((actuals.DiffFrameLeftGap - actuals.LeftTextLeftGap) / textsize - textzoomFudge)
            bg:halign(0):valign(1)
            bg:zoomy(actuals.LowerLipHeight)
            bg:y(actuals.TextLowerGap1)
        end,
        SetCommand = function(self, params)
            local txt = self:GetChild("Text")
            local bg = self:GetChild("BG")
            txt:settext(getCurRateDisplayString())
            bg:zoomx(txt:GetZoomedWidth())
        end,
        ClickCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == "OnMouseDown" then
                if params.event == "DeviceButton_left mouse button" then
                    changeMusicRate(0.05)
                elseif params.event == "DeviceButton_right mouse button" then
                    changeMusicRate(-0.05)
                end
            end
        end,
        RolloverUpdateCommand = function(self, params)
            if self:IsInvisible() then return end
            if params.update == 'in' then
                self:diffusealpha(buttonHoverAlpha)
            else
                self:diffusealpha(1)
            end
        end,
        MouseScrollMessageCommand = function(self, params)
            if self:IsInvisible() then return end
            if isOver(self:GetChild("BG")) then
                if params.direction == "Up" then
                    changeMusicRate(0.05)
                elseif params.direction == "Down" then
                    changeMusicRate(-0.05)
                end
            end
        end
    },
    
    LoadFont("Common Normal") .. {
        Name = "LengthText",
        InitCommand = function(self)
            self:halign(1):valign(1)
            self:xy(actuals.Width - actuals.LengthTextRightGap, actuals.Height - actuals.TextLowerGap1)
            self:zoom(textsize)
            self:settext("LENGTH")
        end
    },
    LoadFont("Common Normal") .. {
        Name = "LengthNumbers",
        InitCommand = function(self)
            self:halign(1):valign(1)
            self:xy(actuals.Width - actuals.LengthNumberRightGap, actuals.Height - actuals.TextLowerGap1)
            self:zoom(textsize)
            self:maxwidth(actuals.LengthWidth / textsize - textzoomFudge)
            self:settext("55:55")
        end,
        SetCommand = function(self, params)
            if params.steps then
                local len = GetPlayableTime()
                self:settext(SecondsToMMSS(len))
                self:diffuse(byMusicLength(len))
            else
                self:settext("--:--")
                self:diffuse(color("1,1,1,1"))
            end
        end
    },
    
    LoadFont("Common Normal") .. {
        Name = "BPMText",
        InitCommand = function(self)
            self:halign(1):valign(1)
            self:xy(actuals.Width - actuals.BPMTextRightGap, actuals.Height - actuals.TextLowerGap1)
            self:zoom(textsize)
            self:settext("BPM")
        end
    },
    Def.BPMDisplay {
        File = THEME:GetPathF("Common", "Normal"),
        Name = "BPMDisplay",
        InitCommand = function(self)
            self:halign(1):valign(1)
            self:xy(actuals.Width - actuals.BPMNumberRightGap, actuals.Height - actuals.TextLowerGap1)
            self:zoom(textsize)
            self:maxwidth(actuals.BPMWidth / textsize - textzoomFudge)
        end,
        SetCommand = function(self, params)
            -- it appears that SetFromSteps is broken...
            -- note to self.
            if params.steps then
                self:visible(true)
                self:SetFromSong(params.song)
            else
                self:visible(false)
            end
        end
    },
    LoadActorWithParams("stepsdisplay", {ratios = ratios, actuals = actuals})

}


return t