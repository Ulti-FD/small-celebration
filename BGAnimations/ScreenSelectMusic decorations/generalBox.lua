local t = Def.ActorFrame {
    Name = "GeneralBoxFile",
    LoginMessageCommand = function(self)
        self:playcommand("UpdateLoginStatus")
    end,
    LogOutMessageCommand = function(self)
        self:playcommand("UpdateLoginStatus")
    end,
    LoginFailedMessageCommand = function(self)
        self:playcommand("UpdateLoginStatus")
    end,
    OnlineUpdateMessageCommand = function(self)
        self:playcommand("UpdateLoginStatus")
    end
}

local ratios = {
    LeftGap = 1140 / 1920, -- left side of screen to left edge of frame
    TopGap = 468 / 1080, -- top of screen to top of frame
    Width = 780 / 1920,
    Height = 612 / 1080,
    LowerLipHeight = 57 / 1080,
}

local actuals = {
    LeftGap = ratios.LeftGap * SCREEN_WIDTH,
    TopGap = ratios.TopGap * SCREEN_HEIGHT,
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    LowerLipHeight = ratios.LowerLipHeight * SCREEN_HEIGHT
}

-- the page names in the order they go
local choiceNames = {
    "General",
    "Scores",
    "Profile",
    "Goals",
    "Playlists",
    "Tags",
}
SCUFF.generaltabcount = #choiceNames

local choiceTextSize = 0.8
local buttonHoverAlpha = 0.6
local buttonActiveStrokeColor = color("0.85,0.85,0.85,0.8")
local textzoomFudge = 5

-- controls the focus of the frame
-- starts true because it starts visible on the screen
-- goes false when forced away, such as when pressing search
local focused = true

local function createChoices()
    local selectedIndex = 1

    local function createChoice(i)
        return UIElements.TextButton(1, 1, "Common Normal") .. {
            Name = "ButtonTab_"..choiceNames[i],
            InitCommand = function(self)
                local txt = self:GetChild("Text")
                local bg = self:GetChild("BG")

                -- this position is the center of the text
                -- divides the space into slots for the choices then places them half way into them
                -- should work for any count of choices
                -- and the maxwidth will make sure they stay nonoverlapping
                self:x((actuals.Width / #choiceNames) * (i-1) + (actuals.Width / #choiceNames / 2))
                txt:zoom(choiceTextSize)
                txt:maxwidth(actuals.Width / #choiceNames / choiceTextSize - textzoomFudge)
                txt:settext(choiceNames[i])
                bg:zoomto(actuals.Width / #choiceNames, actuals.LowerLipHeight)
            end,
            UpdateSelectedIndexCommand = function(self)
                local txt = self:GetChild("Text")
                if selectedIndex == i then
                    txt:strokecolor(buttonActiveStrokeColor)
                else
                    txt:strokecolor(color("0,0,0,0"))
                end
            end,
            ClickCommand = function(self, params)
                if self:IsInvisible() then return end
                if params.update == "OnMouseDown" then
                    selectedIndex = i
                    MESSAGEMAN:Broadcast("GeneralTabSet", {tab = i})
                    self:GetParent():playcommand("UpdateSelectedIndex")
                end
            end,
            RolloverUpdateCommand = function(self, params)
                if self:IsInvisible() then return end
                if params.update == "in" then
                    self:diffusealpha(buttonHoverAlpha)
                else
                    self:diffusealpha(1)
                end
            end
        }
    end
    local t = Def.ActorFrame {
        Name = "Choices",
        InitCommand = function(self)
            self:y(actuals.Height - actuals.LowerLipHeight / 2)
            self:playcommand("UpdateSelectedIndex")
            self:draworder(3)
        end,
        BeginCommand = function(self)
            local snm = SCREENMAN:GetTopScreen():GetName()
            local anm = self:GetName()
            -- this keeps track of whether or not the user is allowed to use the keyboard to change tabs
            CONTEXTMAN:RegisterToContextSet(snm, "Main1", anm)

            -- enable the possibility to press the keyboard to switch tabs
            SCREENMAN:GetTopScreen():AddInputCallback(function(event)
                -- if locked out, dont allow
                if not CONTEXTMAN:CheckContextSet(snm, "Main1") then return end
                if event.type == "InputEventType_FirstPress" then
                    -- must be a number and control not held down
                    if event.char and tonumber(event.char) and not INPUTFILTER:IsControlPressed() then
                        local n = tonumber(event.char)
                        if n == 0 then n = 10 end
                        -- n must be a valid option or we must not have focus on the general box (not in search for example)
                        if n >= 1 and n <= #choiceNames or not focused then
                            selectedIndex = n
                            MESSAGEMAN:Broadcast("GeneralTabSet", {tab = n})
                            self:GetParent():hurrytweening(0.5):playcommand("UpdateSelectedIndex")
                        end
                    elseif event.DeviceInput.button == "DeviceButton_space" and focused and SCUFF.generaltab == SCUFF.generaltabindex then
                        -- toggle chart preview if the general tab is the current tab visible
                        SCUFF.preview.active = not SCUFF.preview.active
                        -- this should propagate off to the right places
                        self:GetParent():playcommand("ToggleChartPreview")
                    end
                end
            end)
        end
    }
    for i = 1, #choiceNames do
        t[#t+1] = createChoice(i)
    end
    return t
end

t[#t+1] = Def.ActorFrame {
    Name = "Container",
    InitCommand = function(self)
        self:xy(actuals.LeftGap, actuals.TopGap)
    end,
    GeneralTabSetMessageCommand = function(self)
        focused = true
    end,
    PlayerInfoFrameTabSetMessageCommand = function(self)
        focused = false
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
        Name = "Lip",
        InitCommand = function(self)
            self:halign(0):valign(1)
            self:y(actuals.Height)
            self:zoomto(actuals.Width, actuals.LowerLipHeight)
            self:diffuse(color("#111111"))
            self:diffusealpha(0.6)
            self:draworder(3)
        end
    },
    createChoices(),
    LoadActorWithParams("generalPages/general.lua", {ratios = ratios, actuals = actuals}) .. {
        BeginCommand = function(self)
            -- this will cause the general tab to become visible first on screen startup
            self:playcommand("GeneralTabSet", {tab = SCUFF.generaltabindex})
            -- skip animation
            self:finishtweening()
        end
    },
    LoadActorWithParams("generalPages/scores.lua", {ratios = ratios, actuals = actuals}),
    LoadActorWithParams("generalPages/profile.lua", {ratios = ratios, actuals = actuals}),
    LoadActorWithParams("generalPages/goals.lua", {ratios = ratios, actuals = actuals}),
    LoadActorWithParams("generalPages/playlists.lua", {ratios = ratios, actuals = actuals}),
    LoadActorWithParams("generalPages/tags.lua", {ratios = ratios, actuals = actuals}),
}

return t
