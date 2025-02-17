-- every time i look at this file my desire to continue modifying it gets worse
-- at least it isnt totally spaghetti code yet
-- hmm
local ratios = {
    RightWidth = 782 / 1920,
    LeftWidth = 783 / 1920,
    Height = 971 / 1080,
    TopLipHeight = 44 / 1080,
    BottomLipHeight = 99 / 1080,

    EdgePadding = 12 / 1920, -- distance from edges for text and items

    --
    -- right options
    OptionTextWidth = 275 / 1920, -- left edge of text to edge of area for text
    OptionTextListTopGap = 21 / 1080, -- bottom of right top lip to top of text
    OptionTextBuffer = 7 / 1920, -- distance from end of width to beginning of selection frame
    OptionSelectionFrameWidth = 250 / 1920, -- allowed area for option selection
    OptionBigTriangleHeight = 19 / 1080, -- visually the width most of the time because the triangles are usually turned
    OptionBigTriangleWidth = 20 / 1920,
    OptionSmallTriangleHeight = 12 / 1080,
    OptionSmallTriangleWidth = 13 / 1920,
    OptionSmallTriangleGap = 2 / 1920,
    OptionChoiceDirectionGap = 7 / 1920, -- gap between direction arrow pairs and between direction arrows and choices
    OptionChoiceAllottedWidth = 450 / 1920, -- width between the arrows for MultiChoices basically (or really long SingleChoices)
    OptionChoiceUnderlineThickness = 2 / 1080,

    -- for this area, this is the allowed height for all options including sub options
    -- when an option opens, it may only show as many sub options as there are lines after subtracting the amount of option categories
    -- so 1 category with 24 sub options has 25 lines
    -- 2 categories can then only have up to 23 sub options each to make 25 lines
    -- etc
    OptionAllottedHeight = 672 / 1080, -- from top of top option to bottom of bottom option
    NoteskinDisplayWidth = 240 / 1920, -- width of the text but lets fit the arrows within this
    NoteskinDisplayRightGap = 17 / 1920, -- distance from right edge of frame to right edge of display
    NoteskinDisplayReceptorTopGap = 29 / 1080, -- bottom of text to top of receptors
    NoteskinDisplayTopGap = 21 / 1080, -- bottom of right top lip to top of text
}

local actuals = {
    LeftWidth = ratios.LeftWidth * SCREEN_WIDTH,
    RightWidth = ratios.RightWidth * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    TopLipHeight = ratios.TopLipHeight * SCREEN_HEIGHT,
    BottomLipHeight = ratios.BottomLipHeight * SCREEN_HEIGHT,
    EdgePadding = ratios.EdgePadding * SCREEN_WIDTH,
    OptionTextWidth = ratios.OptionTextWidth * SCREEN_WIDTH,
    OptionTextListTopGap = ratios.OptionTextListTopGap * SCREEN_HEIGHT,
    OptionTextBuffer = ratios.OptionTextBuffer * SCREEN_WIDTH,
    OptionSelectionFrameWidth = ratios.OptionSelectionFrameWidth * SCREEN_WIDTH,
    OptionBigTriangleHeight = ratios.OptionBigTriangleHeight * SCREEN_HEIGHT,
    OptionBigTriangleWidth = ratios.OptionBigTriangleWidth * SCREEN_WIDTH,
    OptionSmallTriangleHeight = ratios.OptionSmallTriangleHeight * SCREEN_HEIGHT,
    OptionSmallTriangleWidth = ratios.OptionSmallTriangleWidth * SCREEN_WIDTH,
    OptionSmallTriangleGap = ratios.OptionSmallTriangleGap * SCREEN_WIDTH,
    OptionChoiceDirectionGap = ratios.OptionChoiceDirectionGap * SCREEN_WIDTH,
    OptionChoiceAllottedWidth = ratios.OptionChoiceAllottedWidth * SCREEN_WIDTH,
    OptionChoiceUnderlineThickness = ratios.OptionChoiceUnderlineThickness * SCREEN_HEIGHT,
    OptionAllottedHeight = ratios.OptionAllottedHeight * SCREEN_HEIGHT,
    NoteskinDisplayWidth = ratios.NoteskinDisplayWidth * SCREEN_WIDTH,
    NoteskinDisplayRightGap = ratios.NoteskinDisplayRightGap * SCREEN_WIDTH,
    NoteskinDisplayReceptorTopGap = ratios.NoteskinDisplayReceptorTopGap * SCREEN_HEIGHT,
    NoteskinDisplayTopGap = ratios.NoteskinDisplayTopGap * SCREEN_HEIGHT,
}

local visibleframeY = SCREEN_HEIGHT - actuals.Height
local animationSeconds = 0.1
local focused = false
local lefthidden = false

local titleTextSize = 0.8
local explanationTextSize = 0.8
local textZoomFudge = 5

local choiceTextSize = 0.8
local buttonHoverAlpha = 0.6
local previewOpenedAlpha = 0.6
local buttonActiveStrokeColor = color("0.85,0.85,0.85,0.8")
local previewButtonTextSize = 0.8

local keyinstructionsTextSize = 0.7
local bindingChoicesTextSize = 0.7
local currentlybindingTextSize = 0.7

local optionTitleTextSize = 0.7
local optionChoiceTextSize = 0.7
-- basically our font is bad and not on the baseline or equivalent to what a BitMapText:isOver says it is, so this is a modifier to the invisible text button size
-- could also be moved even further for whatever accessibility concerns
local textButtonHeightFudgeScalarMultiplier = 1.6
local optionRowAnimationSeconds = 0.15
local optionRowQuickAnimationSeconds = 0.07
-- theoretically this is how long it takes for text to write out when queued by the explanation text
-- but because the game isnt perfect this isnt true at all
-- (but changing this number does make a difference)
local explanationTextWriteAnimationSeconds = 0.2

local maxExplanationTextLines = 2

-- lost patience
-- undertaking this was a massive mistake
-- hope you people like it
SCUFF.showingNoteskins = false
SCUFF.showingPreview = false
SCUFF.showingColor = false
SCUFF.showingKeybinds = false

local t = Def.ActorFrame {
    Name = "SettingsFile",
    InitCommand = function(self)
        -- lets just say uh ... despite the fact that this file might want to be portable ...
        -- lets ... just .... assume it always goes in the same place ... and the playerInfoFrame is the same size always
        self:y(visibleframeY)
        self:diffusealpha(0)
    end,
    GeneralTabSetMessageCommand = function(self, params)
        -- if we ever get this message we need to hide the frame and just exit.
        focused = false
        self:finishtweening()
        self:smooth(animationSeconds)
        self:diffusealpha(0)
        self:playcommand("HideLeft")
        self:playcommand("HideRight")
        MESSAGEMAN:Broadcast("ShowWheel")
    end,
    PlayerInfoFrameTabSetMessageCommand = function(self, params)
        if params.tab and params.tab == "Settings" then
            --
            -- movement is delegated to the left and right halves
            -- right half immediately comes out
            -- left half comes out when selecting "Customize Playfield" or "Customize Keybinds" or some appropriate choice
            --
            self:diffusealpha(1)
            self:finishtweening()
            self:sleep(0.01)
            self:queuecommand("FinishFocusing")
            self:playcommand("ShowRight")
            self:playcommand("HideLeft")
            MESSAGEMAN:Broadcast("ShowWheel")
        else
            self:finishtweening()
            self:smooth(animationSeconds)
            self:diffusealpha(0)
            self:playcommand("HideLeft")
            self:playcommand("HideRight")
            MESSAGEMAN:Broadcast("ShowWheel")
            focused = false
        end
    end,
    FinishFocusingCommand = function(self)
        focused = true
        CONTEXTMAN:SetFocusedContextSet(SCREENMAN:GetTopScreen():GetName(), "Settings")
    end,
    ShowSettingsAltMessageCommand = function(self, params)
        if params and params.name then
            self:playcommand("ShowLeft", params)
        else
            self:playcommand("HideLeft")
        end
    end,
    OptionCursorUpdatedMessageCommand = function(self, params)
        if params and params.name then
            -- will only work when hovering certain options
            if SCUFF.optionsThatWillOpenTheLeftSideWhenHovered[params.name] ~= nil then
                MESSAGEMAN:Broadcast("ShowSettingsAlt", params)
            else
                -- if moving off of the noteskin tab (without keybinds)
                if SCUFF.showingNoteskins and not SCUFF.showingKeybinds then
                    self:playcommand("HideLeft")
                    -- HACK HACK HACK HACK HACK
                    MESSAGEMAN:Broadcast("ShowSettingsAlt")
                    CONTEXTMAN:SetFocusedContextSet(SCREENMAN:GetTopScreen():GetName(), "Settings")
                end
            end
        end
    end,
}


local function leftFrame()
    local offscreenX = -actuals.LeftWidth
    local onscreenX = 0

    local t = Def.ActorFrame {
        Name = "LeftFrame",
        InitCommand = function(self)
            self:x(offscreenX)
            self:diffusealpha(0)
        end,
        HideLeftCommand = function(self)
            -- move off screen left and go invisible
            self:finishtweening()
            self:smooth(animationSeconds)
            self:diffusealpha(0)
            self:x(offscreenX)
            lefthidden = true
        end,
        ShowLeftCommand = function(self, params)
            -- move on screen from left and go visible
            self:finishtweening()
            self:smooth(animationSeconds)
            self:diffusealpha(1)
            self:x(onscreenX)
            lefthidden = false
        end,

        Def.Quad {
            Name = "BG",
            InitCommand = function(self)
                self:valign(0):halign(0)
                self:zoomto(actuals.LeftWidth, actuals.Height)
                self:diffuse(color("#111111"))
                self:diffusealpha(0.6)
            end
        },
        Def.Quad {
            Name = "TopLip",
            InitCommand = function(self)
                self:valign(0):halign(0)
                self:zoomto(actuals.LeftWidth, actuals.TopLipHeight)
                self:diffuse(color("#111111"))
                self:diffusealpha(0.6)
            end
        },
        LoadFont("Common Normal") .. {
            Name = "HeaderText",
            InitCommand = function(self)
                self:halign(0)
                self:xy(actuals.EdgePadding, actuals.TopLipHeight / 2)
                self:zoom(titleTextSize)
                self:maxwidth((actuals.LeftWidth - actuals.EdgePadding*2) / titleTextSize - textZoomFudge)
                self:settext("")
            end,
            ShowLeftCommand = function(self, params)
                if params and params.name then
                    self:settext(params.name)
                end
            end,

        }
    }

    -- the noteskin page function as noteskin preview and keybindings
    local function createNoteskinPage()
        -- list of GameButtons we can map
        -- remember to pass calling indices through to ButtonIndexToCurGameColumn(x)
        local gameButtonsToMap = INPUTMAPPER:GetGameButtonsToMap()
        local currentController = 0
        local currentlyBinding = false
        local currentKey = ""
        local cursorIndex = 1

        -- entries into this list are not allowed to be bound
        local bannedKeys = {
            -- valid entries:
            -- "key" (all keyboard input)
            -- "mouse" (all mouse input)
            -- "cz" (the letter z)
            -- "left" (the left arrow on the keyboard)
            mouse = true,
        }

        -- function to remove all double+ binding and leave only defaults
        -- this goes out to all cheaters and losers
        -- if you want to use double bindings dont touch this settings menu
        local function setUpKeyBindings()
            INPUTBINDING:RemoveDoubleBindings(false)
            MESSAGEMAN:Broadcast("UpdatedBoundKeys")
        end

        -- just moves the cursor, for keyboard compatibility only
        local function selectKeybind(direction)
            local n = cursorIndex + direction
            if n > #gameButtonsToMap*2 then n = 1 end
            if n < 1 then n = #gameButtonsToMap*2 end

            cursorIndex = n
            MESSAGEMAN:Broadcast("UpdatedBoundKeys")
        end

        -- select this specific key to begin binding, lock input
        local function startBinding(buttonName, controller)
            currentKey = buttonName
            currentController = controller
            currentlyBinding = true
            MESSAGEMAN:Broadcast("StartedBinding", {key = currentKey, controller = controller})
        end
        local function stopBinding()
            currentlyBinding = false
            MESSAGEMAN:Broadcast("StoppedBinding")
        end

        -- for the currentKey, use this InputEventPlus to bind the pressed key to the button
        local function bindCurrentKey(event)
            if event == nil or event.DeviceInput == nil then return end -- ??
            local dev = event.DeviceInput.device
            if dev == nil then return end -- ???
            local key = event.DeviceInput.button
            if key == nil then return end -- ????
            local spldev = strsplit(dev, "_")
            if spldev == nil or #spldev ~= 2 then return end -- ?????
            local splkey = strsplit(key, "_")
            if splkey == nil or #splkey ~= 2 then return end -- ??????
            local pizzaHut = spldev[2]:lower()
            local tacoBell = splkey[2]:lower()
            -- numpad buttons and F keys are case sensitive
            if tacoBell:sub(1,2) == "kp" then
                tacoBell = tacoBell:gsub("kp", "KP")
            elseif tacoBell:sub(1,1) == "f" and tonumber(tacoBell:sub(2,2)) ~= nil then
                tacoBell = tacoBell:gsub("f", "F")
            end
            local combinationPizzaHutAndTacoBell = (pizzaHut .. "_" .. tacoBell)
            -- not gonna bother finding a better way to do all that
            if currentKey == nil or #currentKey == 0 then return end -- ???????
            if bannedKeys[tacoBell] or bannedKeys[pizzaHut] or bannedKeys[combinationPizzaHutAndTacoBell] then return true end -- ????????

            -- bind it
            INPUTMAPPER:SetInputMap(combinationPizzaHutAndTacoBell, currentKey, INPUTBINDING.defaultColumn, currentController)
            -- check to see if the button bound
            local result = INPUTMAPPER:GetButtonMapping(currentKey, currentController, INPUTBINDING.defaultColumn)
            return result ~= nil
        end

        local t = Def.ActorFrame {
            Name = "NoteSkinPageContainer",
            ShowLeftCommand = function(self, params)
                if params and (params.name == "Noteskin" or params.name == "Customize Keybinds") then
                    if params.name == "Customize Keybinds" then
                        SCUFF.showingKeybinds = true
                        setUpKeyBindings()
                        CONTEXTMAN:SetFocusedContextSet(SCREENMAN:GetTopScreen():GetName(), "Keybindings")
                    else
                        SCUFF.showingKeybinds = false
                    end
                    self:diffusealpha(1)
                    SCUFF.showingNoteskins = true
                else
                    self:playcommand("HideLeft")
                end
            end,
            HideLeftCommand = function(self)
                self:diffusealpha(0)
                SCUFF.showingNoteskins = false
                SCUFF.showingKeybinds = false
            end,
            BeginCommand = function(self)
                local snm = SCREENMAN:GetTopScreen():GetName()
                local anm = self:GetName()

                -- cursor input management for keybindings
                -- noteskin display is not relevant for this, just contains it for reasons
                CONTEXTMAN:RegisterToContextSet(snm, "Keybindings", anm)
                CONTEXTMAN:ToggleContextSet(snm, "Keybindings", false)

                SCREENMAN:GetTopScreen():AddInputCallback(function(event)
                    -- if locked out, dont allow
                    if not CONTEXTMAN:CheckContextSet(snm, "Keybindings") then return end
                    if event.type ~= "InputEventType_Release" then -- allow Repeat and FirstPress
                        local gameButton = event.button
                        local key = event.DeviceInput.button
                        local up = gameButton == "Up" or gameButton == "MenuUp"
                        local down = gameButton == "Down" or gameButton == "MenuDown"
                        local right = gameButton == "MenuRight" or gameButton == "Right"
                        local left = gameButton == "MenuLeft" or gameButton == "Left"
                        local enter = gameButton == "Start"
                        local ctrl = INPUTFILTER:IsBeingPressed("left ctrl") or INPUTFILTER:IsBeingPressed("right ctrl")
                        local back = key == "DeviceButton_escape"
                        local rightclick = key == "Devicebutton_mouse right button"

                        if not currentlyBinding and (up or left) then
                            selectKeybind(-1)
                            self:playcommand("Set")
                        elseif not currentlyBinding and (down or right) then
                            selectKeybind(1)
                            self:playcommand("Set")
                        elseif not currentlyBinding and enter then
                            local controller = cursorIndex > #gameButtonsToMap and 1 or 0
                            local buttonindex = controller == 0 and cursorIndex or cursorIndex - #gameButtonsToMap
                            startBinding(gameButtonsToMap[ButtonIndexToCurGameColumn(buttonindex)], controller)
                        elseif not currentlyBinding and back then
                            -- shortcut to exit back to settings
                            -- press twice to exit back to general
                            MESSAGEMAN:Broadcast("PlayerInfoFrameTabSet", {tab = "Settings"})
                        elseif currentlyBinding and (back or rightclick) then
                            -- cancel the binding process
                            -- update highlights
                            stopBinding()
                            self:playcommand("Set")
                        elseif currentlyBinding then
                            -- pressed a button that could potentially be bindable and we should bind it
                            local result = bindCurrentKey(event)
                            if result then
                                stopBinding()
                            else
                                ms.ok(currentKey)
                                ms.ok(currentController)
                                ms.ok("There was some error in attempting to bind the key... Report to developers")
                            end
                            self:playcommand("Set")
                        else
                            -- nothing happens
                            return
                        end
                    end
                end)
            end,
        }

        -- yeah these numbers are bogus (but are in fact based on the 4key numbers so they arent all that bad)
        local columnwidth = 64
        local noteskinwidthbaseline = 256
        local secondrowYoffset = 64
        local noteskinbasezoom = 1.5 -- pick a zoom that fits 4key in 16:9 aspect ratio
        local NSDirTable = GivenGameToFullNSkinElements(GAMESTATE:GetCurrentGame():GetName())
        local keybindBGSizeMultiplier = 0.97 -- this is multiplied with columnwidth
        local keybindBG2SizeMultiplier = 0.97 -- this is multiplied with columnwidth and keybindBGSizeMultiplier
        local keybindingTextZoom = 1
        -- calculation: find a zoom that fits for the current chosen column count the same way 4key on 16:9 does
        local aspectRatioProportion = (16/9) / (SCREEN_WIDTH / SCREEN_HEIGHT)
        local noteskinzoom = noteskinbasezoom / (#NSDirTable * columnwidth / noteskinwidthbaseline) / aspectRatioProportion

        -- finds noteskin index
        local function findNoteskinIndex(skin)
            local nsnames = NOTESKIN:GetNoteSkinNames()
            for i, name in ipairs(nsnames) do
                if name:lower() == skin:lower() then
                    return i
                end
            end
            return 1
        end

        local tt = Def.ActorFrame {
            Name = "SkinContainer",
            InitCommand = function(self)
                self:x(actuals.LeftWidth / 2)
                self:zoom(noteskinzoom)
                self:y(actuals.Height / 4)
            end,
            OnCommand = function(self)
                local ind = findNoteskinIndex(getPlayerOptions():NoteSkin())
                self:playcommand("SetSkinVisibility", {index = ind})
            end,
            UpdateVisibleSkinMessageCommand = function(self, params)
                local ind = findNoteskinIndex((params or {}).name or "")
                self:playcommand("SetSkinVisibility", {index = ind})
            end,
            ShowLeftCommand = function(self)
                if SCUFF.showingKeybinds then
                    self:x(actuals.LeftWidth / 3)
                    self:zoom(noteskinzoom / 2)
                else
                    self:x(actuals.LeftWidth / 2)
                    self:zoom(noteskinzoom)
                end
            end,
        }
        -- works almost exactly like the legacy PlayerOptions preview
        -- at this point in time we cannot load every Game's noteskin like I would like to
        for i, dir in ipairs(NSDirTable) do
            -- so the elements are centered
            -- add half a column width because elements are center aligned
            local leftoffset = -columnwidth * #NSDirTable / 2 + columnwidth / 2
            local tapForThisIteration = nil
            local receptorForThisIteration = nil

            -- load taps
            tt[#tt+1] = Def.ActorFrame {
                InitCommand = function(self)
                    self:x(leftoffset + columnwidth * (i-1))
                    self:y(secondrowYoffset)
                    tapForThisIteration = self
                end,
                Def.ActorFrame {
                    LoadNSkinPreview("Get", dir, "Tap Note", false) .. {
                        OnCommand = function(self)
                            for i = 1, #NOTESKIN:GetNoteSkinNames() do
                                local c = self:GetChild("N"..i)
                                c:visible(true)
                            end
                        end,
                        SetSkinVisibilityCommand = function(self, params)
                            if params and params.index then
                                local ind = params.index
                                -- noteskin displays are actually many sprites in one spot
                                -- for the chosen noteskin, display only the one we want
                                -- have to search the list to find it
                                for i = 1, #NOTESKIN:GetNoteSkinNames() do
                                    local c = self:GetChild("N"..i)
                                    if i == ind then
                                        c:diffusealpha(1)
                                    else
                                        c:diffusealpha(0)
                                    end
                                end
                            end
                        end,
                    }
                },
            }
            -- load receptors
            tt[#tt+1] = Def.ActorFrame {
                InitCommand = function(self)
                    self:x(leftoffset + columnwidth * (i-1))
                    receptorForThisIteration = self
                end,
                Def.ActorFrame {
                    LoadNSkinPreview("Get", dir, "Receptor", false) .. {
                        OnCommand = function(self)
                            for i = 1, #NOTESKIN:GetNoteSkinNames() do
                                local c = self:GetChild("N"..i)
                                c:visible(true)
                            end
                        end,
                        SetSkinVisibilityCommand = function(self, params)
                            if params and params.index then
                                local ind = params.index
                                -- noteskin displays are actually many sprites in one spot
                                -- for the chosen noteskin, display only the one we want
                                -- have to search the list to find it
                                for i = 1, #NOTESKIN:GetNoteSkinNames() do
                                    local c = self:GetChild("N"..i)
                                    if i == ind then
                                        c:diffusealpha(1)
                                    else
                                        c:diffusealpha(0)
                                    end
                                end
                            end
                        end,
                    }
                },
            }
            -- load shadow taps (doubles modes)
            tt[#tt+1] = Def.ActorProxy {
                InitCommand = function(self)
                    -- ActorProxy offsets only have to be relative to the original
                    -- set x to the same as the highest offset
                    self:x(columnwidth * (#NSDirTable))
                end,
                BeginCommand = function(self)
                    self:SetTarget(tapForThisIteration)
                end,
                ShowLeftCommand = function(self)
                    if SCUFF.showingKeybinds then
                        self:diffusealpha(1)
                    else
                        self:diffusealpha(0)
                    end
                end,
            }
            -- load shadow receptors (doubles modes)
            tt[#tt+1] = Def.ActorProxy {
                InitCommand = function(self)
                    -- ActorProxy offsets only have to be relative to the original
                    -- set x to the same as the highest offset
                    self:x(columnwidth * (#NSDirTable))
                end,
                BeginCommand = function(self)
                    self:SetTarget(receptorForThisIteration)
                end,
                ShowLeftCommand = function(self)
                    if SCUFF.showingKeybinds then
                        self:diffusealpha(1)
                    else
                        self:diffusealpha(0)
                    end
                end,
            }
            -- load keybinding display
            -- this is put into a function to prevent a lot of copy pasting and unmaintainability
            local function keybindingDisplay(i, isDoublesSide)
                -- the doubles side starting index is #NSDirTable+1
                local trueIndex = i + (isDoublesSide and #NSDirTable or 0)
                local controller = isDoublesSide and 1 or 0
                return Def.ActorFrame {
                    Name = "KeybindingFrame",
                    InitCommand = function(self)
                        self:x(leftoffset + columnwidth * (i-1))
                        if isDoublesSide then
                            self:addx(columnwidth * #NSDirTable)
                        end
                        self:y(secondrowYoffset * 2)
                    end,
                    ShowLeftCommand = function(self)
                        if SCUFF.showingKeybinds then
                            self:diffusealpha(1)
                        else
                            self:diffusealpha(0)
                        end
                    end,
                    UIElements.QuadButton(1, 1) .. {
                        Name = "KeybindBGBG",
                        InitCommand = function(self)
                            -- font color
                            self:diffuse(color("#FFFFFF"))
                            self:zoomto(columnwidth * keybindBGSizeMultiplier, columnwidth * keybindBGSizeMultiplier)
                            self:playcommand("Set")
                        end,
                        SetAlphaCommand = function(self)
                            if isOver(self) or cursorIndex == trueIndex then
                                self:diffusealpha(0.6 * buttonHoverAlpha)
                            else
                                self:diffusealpha(0.6)
                            end
                        end,
                        SetCommand = function(self)
                            self:playcommand("SetAlpha")
                        end,
                        UpdatedBoundKeysMessageCommand = function(self)
                            self:playcommand("SetAlpha")
                        end,
                        MouseOverCommand = function(self)
                            self:playcommand("SetAlpha")
                        end,
                        MouseOutCommand = function(self)
                            self:playcommand("SetAlpha")
                        end,
                        MouseDownCommand = function(self)
                            if not currentlyBinding then
                                local dist = trueIndex - cursorIndex
                                selectKeybind(dist)
                                startBinding(gameButtonsToMap[ButtonIndexToCurGameColumn(i)], controller)
                            end
                        end,
                    },
                    Def.Quad {
                        Name = "KeybindBG",
                        InitCommand = function(self)
                            -- generally bg color
                            self:diffuse(color("#111111"))
                            self:diffusealpha(0.6)
                            self:zoomto(columnwidth * keybindBGSizeMultiplier * keybindBG2SizeMultiplier, columnwidth * keybindBGSizeMultiplier * keybindBG2SizeMultiplier)
                        end,
                    },
                    LoadFont("Common Large") .. {
                        Name = "KeybindText",
                        InitCommand = function(self)
                            self:zoom(keybindingTextZoom)
                            self:maxwidth(columnwidth * keybindBGSizeMultiplier * keybindBGSizeMultiplier / keybindingTextZoom)
                            self:maxheight(columnwidth * keybindBGSizeMultiplier * keybindBG2SizeMultiplier / keybindingTextZoom)
                        end,
                        UpdatedBoundKeysMessageCommand = function(self)
                            self:playcommand("Set")
                        end,
                        SetCommand = function(self)
                            local newindex = ButtonIndexToCurGameColumn(i)
                            local buttonmapped = INPUTMAPPER:GetButtonMapping(gameButtonsToMap[newindex], controller, INPUTBINDING.defaultColumn)
                            if buttonmapped then
                                self:settext(buttonmapped:gsub("Key ", ""))
                            else
                                self:settext("none")
                            end
                        end,
                    }
                }
            end
            tt[#tt+1] = keybindingDisplay(i, false)
            tt[#tt+1] = keybindingDisplay(i, true)
        end
        t[#t+1] = tt

        -- more elements to keybinding screen
        -- many numbers which follow are fudged hard
        -- this function creates a menu binding element for only player 1
        local function menuBinding(key)
            return Def.ActorFrame {}
        end
        t[#t+1] = Def.ActorFrame {
            Name = "KeybindingTextElements",
            ShowLeftCommand = function(self)
                if SCUFF.showingKeybinds then
                    self:diffusealpha(1)
                else
                    self:diffusealpha(0)
                end
            end,

            LoadFont("Common Normal") .. {
                Name = "CurrentlyBinding",
                InitCommand = function(self)
                    self:valign(1)
                    self:xy(actuals.LeftWidth/2, actuals.Height/2)
                    self:maxwidth(actuals.LeftWidth / currentlybindingTextSize)
                    self:settext("Currently Binding:")
                end,
                SetCommand = function(self)
                    if currentlyBinding then
                        self:settextf("Currently Binding: %s (Controller %s)", currentKey, currentController)
                    else
                        self:settext("Currently Binding: ")
                    end
                end,
                StartedBindingMessageCommand = function(self)
                    self:playcommand("Set")
                end,
                StoppedBindingMessageCommand = function(self)
                    self:playcommand("Set")
                end,
            },
            LoadFont("Common Normal") .. {
                Name = "Instructions",
                InitCommand = function(self)
                    self:valign(0)
                    self:xy(actuals.LeftWidth/2, actuals.TopLipHeight * 1.2)
                    self:zoom(keyinstructionsTextSize)
                    self:wrapwidthpixels(actuals.LeftWidth - 10)
                    self:maxheight((actuals.Height / 4 - actuals.TopLipHeight * 1.5) / keyinstructionsTextSize)
                    self:settext("Select a button to rebind with mouse or keyboard.\nPress Escape or click to cancel binding.")
                end,
            },
            LoadFont("Common Normal") .. {
                Name = "StartBindingAll",
                InitCommand = function(self)
                    self:valign(0)
                    self:halign(0)
                    self:xy(actuals.EdgePadding, actuals.Height/2 + actuals.Height/4)
                    self:maxwidth(actuals.LeftWidth / bindingChoicesTextSize)
                    self:settext("Bind All")
                end,
            },
            LoadFont("Common Normal") .. {
                Name = "ToggleAdvancedKeybindings",
                InitCommand = function(self)
                    self:valign(0)
                    self:halign(0)
                    self:xy(actuals.EdgePadding, actuals.Height/2 + actuals.Height/4 + 30 * bindingChoicesTextSize)
                    self:maxwidth(actuals.LeftWidth / bindingChoicesTextSize)
                    self:settext("View Other Keybindings")
                end,
            },
            menuBinding(""),

        }

        return t
    end

    -- the notefield preview, an optional showcase of what mods are doing
    -- literally a copy of chart preview -- an ActorProxy
    local function createPreviewPage()
        local t = Def.ActorFrame {
            Name = "PreviewPageContainer",
            ShowLeftCommand = function(self, params)
                -- dont open the preview if left is already opened and it is being used
                if params and params.name == "Preview" and not SCUFF.showingNoteskins and not SCUFF.showingColor then
                    self:diffusealpha(1)
                    SCUFF.showingPreview = true
                    MESSAGEMAN:Broadcast("PreviewPageOpenStatusChanged", {opened = true})
                else
                    self:playcommand("HideLeft")
                end
            end,
            HideLeftCommand = function(self)
                self:diffusealpha(0)
                SCUFF.showingPreview = false
                MESSAGEMAN:Broadcast("PreviewPageOpenStatusChanged", {opened = false})
            end,

            -- the preview notefield (but not really)
            Def.ActorProxy {
                Name = "NoteField",
                InitCommand = function(self)
                    -- centered horizontally and vertically
                    self:x(actuals.LeftWidth / 2)
                    self:y(actuals.Height / 4)
                end,
                BeginCommand = function(self)
                    -- take the long road to find the actual chart preview actor
                    local realnotefieldpreview = SCREENMAN:GetTopScreen():safeGetChild(
                        "RightFrame",
                        "GeneralBoxFile",
                        "Container",
                        "GeneralPageFile",
                        "ChartPreviewFile",
                        "NoteField"
                    )
                    if realnotefieldpreview ~= nil then
                        self:SetTarget(realnotefieldpreview)
                        self:addx(-realnotefieldpreview:GetX())
                    else
                        print("It appears that chart preview is not where it should be ....")
                    end
                end,
            }
        }
        return t
    end

    local function createColorConfigPage()
        local t = Def.ActorFrame {
            Name = "ColorConfigPageContainer",
            ShowLeftCommand = function(self, params)
                if params and params.name == "ColorConfig" then
                    self:diffusealpha(1)
                    SCUFF.showingColor = true
                else
                    self:playcommand("HideLeft")
                end
            end,
            HideLeftCommand = function(self)
                self:diffusealpha(0)
                SCUFF.showingColor = false
            end,
        }
        return t
    end

    t[#t+1] = createNoteskinPage()
    t[#t+1] = createPreviewPage()
    t[#t+1] = createColorConfigPage()

    return t
end

local function rightFrame()
    -- to reach the explanation text from anywhere without all the noise
    local explanationHandle = nil
    local offscreenX = SCREEN_WIDTH
    local onscreenX = SCREEN_WIDTH - actuals.RightWidth

    local t = Def.ActorFrame {
        Name = "RightFrame",
        InitCommand = function(self)
            self:x(offscreenX)
            self:diffusealpha(0)
        end,
        HideRightCommand = function(self)
            -- move off screen right and go invisible
            self:finishtweening()
            self:smooth(animationSeconds)
            self:diffusealpha(0)
            self:x(offscreenX)
        end,
        ShowRightCommand = function(self)
            -- move on screen from right and go visible
            self:finishtweening()
            self:smooth(animationSeconds)
            self:diffusealpha(1)
            self:x(onscreenX)
        end,

        Def.Quad {
            Name = "BG",
            InitCommand = function(self)
                self:valign(0):halign(0)
                self:zoomto(actuals.RightWidth, actuals.Height)
                self:diffuse(color("#111111"))
                self:diffusealpha(0.6)
            end,
        },
        Def.Quad {
            Name = "TopLip",
            InitCommand = function(self)
                -- height is double normal top lip
                self:valign(0):halign(0)
                self:zoomto(actuals.RightWidth, actuals.TopLipHeight * 2)
                self:diffuse(color("#111111"))
                self:diffusealpha(0.6)
            end,
        },
        Def.Quad {
            Name = "BottomLip",
            InitCommand = function(self)
                -- height is double normal top lip
                self:valign(1):halign(0)
                self:y(actuals.Height)
                self:zoomto(actuals.RightWidth, actuals.BottomLipHeight)
                self:diffuse(color("#111111"))
                self:diffusealpha(0.6)
            end,
        },
        LoadFont("Common Normal") .. {
            Name = "HeaderText",
            InitCommand = function(self)
                self:halign(0)
                self:xy(actuals.EdgePadding, actuals.TopLipHeight / 2)
                self:zoom(titleTextSize)
                self:maxwidth((actuals.RightWidth - actuals.EdgePadding*2) / titleTextSize - textZoomFudge)
                self:settext("Options")
            end
        },
        LoadFont("Common Normal") .. {
            Name = "ExplanationText",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:xy(actuals.EdgePadding, actuals.Height - actuals.BottomLipHeight + actuals.EdgePadding)
                self:zoom(explanationTextSize)
                --self:maxwidth((actuals.RightWidth - actuals.EdgePadding*2) / explanationTextSize - textZoomFudge)
                self:wrapwidthpixels((actuals.RightWidth - actuals.EdgePadding * 2) / explanationTextSize)
                self:maxheight((actuals.BottomLipHeight - actuals.EdgePadding * 2) / explanationTextSize)
                self:settext(" ")
                explanationHandle = self
            end,
            SetExplanationCommand = function(self, params)
                if params and params.text and #params.text > 0 then
                    -- here we go ...
                    -- editors note 5 minutes later: i cant believe this works
                    -- this begins the explainloop below which will slowly write out the desired text
                    -- it fires a finishtweening when new text is queued here in case we are in the middle of looping
                    self.txt = params.text
                    self.pos = 0
                    self:finishtweening()
                    self:settext("")
                    self:queuecommand("_explainloop")
                else
                    self.txt = ""
                    self:settext("")
                end
            end,
            _explainloopCommand = function(self)
                self.pos = self.pos + 1
                local subtxt = self.txt:sub(1, self.pos)
                self:settext(subtxt)
                self:sleep(explanationTextWriteAnimationSeconds / #self.txt)
                if self.pos < #self.txt then
                    self:queuecommand("_explainloop")
                end
            end,
        },
        UIElements.TextButton(1, 1, "Common Normal") .. {
            Name = "PreviewToggle",
            InitCommand = function(self)
                local txt = self:GetChild("Text")
                local bg = self:GetChild("BG")
                txt:halign(0)
                txt:zoom(previewButtonTextSize)
                txt:maxwidth(actuals.RightWidth / 2 / previewButtonTextSize - textZoomFudge)
                txt:settext("Toggle Chart Preview")

                -- fudge movement due to font misalign
                bg:halign(0)
                bg:y(1)
                bg:zoomto(txt:GetZoomedWidth(), txt:GetZoomedHeight() * textButtonHeightFudgeScalarMultiplier)
                bg:diffusealpha(0.2)

                self:xy(actuals.EdgePadding, actuals.Height - actuals.BottomLipHeight - actuals.BottomLipHeight/4)
                -- is this being lazy or being big brained? ive stored a function within an actor instance
                self.alphaDeterminingFunction = function(self)
                    local isOpened = SCUFF.showingPreview
                    local canBeToggled = SCUFF.showingPreview or (not SCUFF.showingColor and not SCUFF.showingKeybinds and not SCUFF.showingNoteskins)
                    local alphamultiplier = (isOpened and canBeToggled) and previewOpenedAlpha or 1
                    local hovermultiplier = (isOver(bg) and canBeToggled) and buttonHoverAlpha or 1
                    local finalalpha = 1 * hovermultiplier * alphamultiplier
                    self:diffusealpha(finalalpha)
                end
            end,
            PreviewPageOpenStatusChangedMessageCommand = function(self, params)
                if self:IsInvisible() then return end
                if params and params.opened ~= nil then
                    self:alphaDeterminingFunction()
                end
            end,
            RolloverUpdateCommand = function(self, params)
                if self:IsInvisible() then return end
                self:alphaDeterminingFunction()
            end,
            ClickCommand = function(self, params)
                if self:IsInvisible() then return end
                if params.update == "OnMouseDown" then
                    if not SCUFF.showingColor and not SCUFF.showingKeybinds and not SCUFF.showingNoteskins and not SCUFF.showingPreview then
                        MESSAGEMAN:Broadcast("ShowSettingsAlt", {name = "Preview"})
                    elseif SCUFF.showingPreview then
                        MESSAGEMAN:Broadcast("PlayerInfoFrameTabSet", {tab = "Settings"})
                    end
                end
            end,
        }
    }

    -- -----
    -- Utility functions for options not necessarily needed for global use in /Scripts (could easily be put there instead though)

    -- set any mod as part of PlayerOptions at all levels in one easy function
    local function setPlayerOptionsModValueAllLevels(funcname, ...)
        -- you give a funcname like MMod, XMod, CMod and it just works
        local poptions = GAMESTATE:GetPlayerState():GetPlayerOptions("ModsLevel_Preferred")
        local stoptions = GAMESTATE:GetPlayerState():GetPlayerOptions("ModsLevel_Stage")
        local soptions = GAMESTATE:GetPlayerState():GetPlayerOptions("ModsLevel_Song")
        local coptions = GAMESTATE:GetPlayerState():GetPlayerOptions("ModsLevel_Current")
        poptions[funcname](poptions, ...)
        stoptions[funcname](stoptions, ...)
        soptions[funcname](soptions, ...)
        coptions[funcname](coptions, ...)
    end
    -- set any mod as part of SongOptions at all levels in one easy function
    local function setSongOptionsModValueAllLevels(funcname, ...)
        -- you give a funcname like MusicRate and it just works
        local poptions = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred")
        local stoptions = GAMESTATE:GetSongOptionsObject("ModsLevel_Stage")
        local soptions = GAMESTATE:GetSongOptionsObject("ModsLevel_Song")
        local coptions = GAMESTATE:GetSongOptionsObject("ModsLevel_Current")
        poptions[funcname](poptions, ...)
        stoptions[funcname](stoptions, ...)
        soptions[funcname](soptions, ...)
        coptions[funcname](coptions, ...)
    end

    --- for Speed Mods -- this has been adapted from the fallback script which does speed and mode at once
    local function getSpeedModeFromPlayerOptions()
        local poptions = GAMESTATE:GetPlayerState():GetPlayerOptions("ModsLevel_Preferred")
        if poptions:MaxScrollBPM() > 0 then
            return "M"
        elseif poptions:TimeSpacing() > 0 then
            return "C"
        else
            return "X"
        end
    end
    local function getSpeedValueFromPlayerOptions()
        local poptions = GAMESTATE:GetPlayerState():GetPlayerOptions("ModsLevel_Preferred")
        if poptions:MaxScrollBPM() > 0 then
            return math.round(poptions:MaxScrollBPM())
        elseif poptions:TimeSpacing() > 0 then
            return math.round(poptions:ScrollBPM())
        else
            return math.round(poptions:ScrollSpeed() * 100)
        end
    end

    -- for convenience to generate a choice table for a float interface setting
    local function floatSettingChoice(visibleName, funcName, enabledValue, offValue)
        return {
            Name = visibleName,
            ChosenFunction = function()
                local po = getPlayerOptions()
                if po[funcName](po) ~= offValue then
                    setPlayerOptionsModValueAllLevels(funcName, offValue)
                else
                    setPlayerOptionsModValueAllLevels(funcName, enabledValue)
                end
            end,
        }
    end

    -- for convenience to generate a choice table for a boolean interface setting
    local function booleanSettingChoice(visibleName, funcName)
        return {
            Name = visibleName,
            ChosenFunction = function()
                local po = getPlayerOptions()
                if po[funcName](po) == true then
                    setPlayerOptionsModValueAllLevels(funcName, false)
                else
                    setPlayerOptionsModValueAllLevels(funcName, true)
                end
            end,
        }
    end

    -- for convenience to generate a direction table for a setting which goes in either direction and wraps via PREFSMAN
    -- if the max value is reached, the min value is the next one
    local function preferenceIncrementDecrementDirections(preferenceName, minValue, maxValue, increment)
        return {
            Left = function()
                local x = clamp(PREFSMAN:GetPreference(preferenceName), minValue, maxValue)
                x = notShit.round(x - increment, 3)
                if x < minValue then x = maxValue end
                PREFSMAN:SetPreference(preferenceName, notShit.round(x, 3))
            end,
            Right = function()
                local x = clamp(PREFSMAN:GetPreference(preferenceName), minValue, maxValue)
                x = notShit.round(x + increment, 3)
                if x > maxValue then x = minValue end
                PREFSMAN:SetPreference(preferenceName, notShit.round(x, 3))
            end,
        }
    end

    local function basicNamedPreferenceChoice(preferenceName, displayName, chosenValue)
        return {
            Name = displayName,
            ChosenFunction = function()
                PREFSMAN:SetPreference(preferenceName, chosenValue)
            end,
        }
    end
    local function preferenceToggleDirections(preferenceName, trueValue, falseValue)
        return {
            Toggle = function()
                if PREFSMAN:GetPreference(preferenceName) == trueValue then
                    PREFSMAN:SetPreference(preferenceName, falseValue)
                else
                    PREFSMAN:SetPreference(preferenceName, trueValue)
                end
            end,
        }
    end
    local function preferenceToggleIndexGetter(preferenceName, oneValue)
        -- oneValue is what we expect for choice index 1 (the first one)
        return function()
            if PREFSMAN:GetPreference(preferenceName) == oneValue then
                return 1
            else
                return 2
            end
        end
    end
    -- convenience to create a Choices table for a variable number of choice names
    local function choiceSkeleton(...)
        local o = {}
        for _, name in ipairs({...}) do
            o[#o+1] = {
                Name = name,
            }
        end
        return o
    end

    local function initDisplayResolutions()
        local resolutions = {}
        local displaySpecs = GetDisplaySpecs()
        for _, spec in ipairs(displaySpecs) do
            for __, mode in ipairs(spec:GetSupportedModes()) do
                -- linear search? sure
                local add = true
                for ___, res in ipairs(resolutions) do
                    if res.w == mode:GetWidth() and res.h == mode:GetHeight() then add = false break end
                end
                if add then
                    resolutions[#resolutions+1] = {
                        w = mode:GetWidth(),
                        h = mode:GetHeight(),
                    }
                end
            end
        end
        return resolutions
    end

    --
    -- -----

    -- -----
    -- Extra data for option temporary storage or cross option interaction
    --
    local playerConfigData = playerConfig:get_data()
    local themeConfigData = themeConfig:get_data()
    local displaySpecs = GetDisplaySpecs()
    local optionData = {
        speedMod = {
            speed = getSpeedValueFromPlayerOptions(),
            mode = getSpeedModeFromPlayerOptions(),
        },
        noteSkins = {
            names = NOTESKIN:GetNoteSkinNames(),
        },
        receptorSize = playerConfigData.ReceptorSize,
        gameMode = {
            modes = GAMEMAN:GetEnabledGames(),
            current = GAMESTATE:GetCurrentGame():GetName(),
        },
        screenFilter = playerConfigData.ScreenFilter,
        language = {
            list = THEME:GetLanguages(),
            current = THEME:GetCurLanguage(),
        },
        instantSearch = themeConfigData.global.InstantSearch,
        wheelPosition = themeConfigData.global.WheelPosition,
        showBackgrounds = themeConfigData.global.ShowBackgrounds,
        showVisualizer = themeConfigData.global.ShowVisualizer,
        tipType = themeConfigData.global.TipType,
        display = {
            ratios = { -- hardcoded aspect ratio list
                {n = 3, d = 4},
                {n = 1, d = 1},
                {n = 5, d = 4},
                {n = 4, d = 3},
                {n = 16, d = 10},
                {n = 16, d = 9},
                {n = 8, d = 3},
                {n = 21, d = 9}
            },
            refreshRates = { -- hardcoded refresh rate list (i dont know what im doing)
                -- if you put floats here it is your fault if something breaks but go nuts if you want
                --REFRESH_DEFAULT, -- skip this, it is hardcoded as the first value
                59,
                60,
                70,
                72,
                75,
                80,
                85,
                90,
                100,
                120,
                144,
                150,
                240,
            },
            -- displayspec generated "compatible" ratios
            dRatios = GetDisplayAspectRatios(displaySpecs),
            wRatios = GetWindowAspectRatios(),
            -- displayspec generated "compatible" resolutions
            resolutions = initDisplayResolutions(),
            loadedAspectRatio = PREFSMAN:GetPreference("DisplayAspectRatio")
        },
        pickedTheme = THEME:GetCurThemeName(),
    }
    --
    -- -----

    -- -----
    -- Extra utility functions that require optionData to be initialized first
    local function setSpeedValueFromOptionData()
        local mode = optionData.speedMod.mode
        local speed = optionData.speedMod.speed
        if mode == "X" then
            -- the way we store stuff, xmod must divide by 100
            -- theres no quirk to it, thats just because we store the number as an int (not necessarily an int but yeah)
            -- so 0.01x XMod would be a CMod of 1 -- this makes even more sense if you just think about it
            setPlayerOptionsModValueAllLevels("XMod", speed/100)
        elseif mode == "C" then
            setPlayerOptionsModValueAllLevels("CMod", speed)
        elseif mode == "M" then
            setPlayerOptionsModValueAllLevels("MMod", speed)
        end
    end
    local function basicNamedOptionDataChoice(optionDataPropertyName, displayName, chosenValue)
        return {
            Name = displayName,
            ChosenFunction = function()
                optionData[optionDataPropertyName] = chosenValue
            end,
        }
    end
    local function optionDataToggleDirections(optionDataPropertyName, trueValue, falseValue)
        return {
            Toggle = function()
                if optionData[optionDataPropertyName] == trueValue then
                    optionData[optionDataPropertyName] = falseValue
                else
                    optionData[optionDataPropertyName] = trueValue
                end
            end,
        }
    end
    local function optionDataToggleIndexGetter(optionDataPropertyName, oneValue)
        -- oneValue is what we expect for choice index 1 (the first one)
        return function()
            if optionData[optionDataPropertyName] == oneValue then
                return 1
            else
                return 2
            end
        end
    end
    --
    -- -----

    local optionRowCount = 17 -- weird behavior if you mess with this and have too many options in a category
    local maxChoicesVisibleMultiChoice = 4 -- max number of choices visible in a MultiChoice OptionRow

    -- the names and order of the option pages
    -- these values must correspond to the keys of optionPageCategoryLists
    local pageNames = {
        "Player",
        "Graphics",
        "Sound",
        "Input",
        "Profiles",
    }

    -- mappings of option page names to lists of categories
    -- the keys in this table are option pages
    -- the values are tables -- the categories of each page in that order
    -- each category corresponds to a key in optionDefs (must be unique keys -- values of these tables have to be globally unique)
    -- the options of each category are in the order of the value tables in optionDefs
    local optionPageCategoryLists = {
        Player = {
            "Essential Options",
            "Appearance Options",
            "Invalidating Options",
        },
        Graphics = {
            "Global Options",
            "Theme Options",
        },
        Sound = {
            "Sound Options",
        },
        Input = {
            "Input Options",
        },
        Profiles = {
            "Profile Options",
        },
    }

    -- the mother of all tables.
    -- this is each option definition for every single option present in the right frame
    -- mapping option categories to lists of options
    -- LIMITATIONS: A category cannot have more sub options than the max number of lines minus the number of categories.
    --  example: 25 lines? 2 categories? up to 23 options per category.
    -- TYPE LIST:
    --  SingleChoice            -- scrolls through choices
    --  SingleChoiceModifier    -- scrolls through choices, shows 2 sets of arrows for each direction, allowing multiplier
    --  MultiChoice             -- shows all options at once, selecting any amount of them
    --  Button                  -- it's a button. you press enter on it.
    --
    -- OPTION DEFINITION EXAMPLE:
    --[[
        {
            Name = "option name" -- display name for the option
            Type = "type name" -- determines how to generate the actor to display the choices
            AssociatedOptions = {"other option name"} -- runs the index getter for these options when a choice is selected
            Choices = { -- option choice definitions -- each entry is another table -- if no choices are defined, visible choice comes from ChoiceIndexGetter
                {
                    Name = "choice1" -- display name for the choice
                    ChosenFunction = function() end -- what happens when choice is PICKED (not hovered)
                },
                {
                    Name = "choice2"
                    ...
                },
                ...
            },
            Directions = {
                -- table of direction functions -- these define what happens for each pressed direction button
                -- most options have only Left and Right
                -- if these functions are undefined and required by the option type, a default function moves the index of the choice rotationally
                -- some option types may allow for more directions or direction multipliers
                -- if Toggle is defined, this function is used for all direction presses
                Left = function() end,
                Right = function() end,
                Toggle = function() end, --- OPTIONAL -- WILL REPLACE ALL DIRECTION FUNCTIONALITY IF PRESENT
                ...
            },
            ChoiceIndexGetter = function() end -- a function to run to get the choice index or text, or return a table for multi selection options
            ChoiceGenerator = function() end -- an OPTIONAL function for generating the choices table if too long to write out (return a table)
            Explanation = "" -- an explanation that appears at the bottom of the screen
        }
    ]]
    local optionDefs = {
        -----
        -- PLAYER OPTIONS
        ["Essential Options"] = {
            {
                Name = "Scroll Type",
                Type = "SingleChoice",
                Explanation = "XMod - BPM multiplier based scrolling. CMod - Constant scrolling. MMod - BPM based with a max speed.",
                AssociatedOptions = {
                    "Scroll Speed",
                },
                Choices = choiceSkeleton("XMod", "CMod", "MMod"),
                Directions = {
                    Left = function()
                        -- traverse list left, set the speed mod again
                        -- order:
                        -- XMOD - CMOD - MMOD
                        local mode = optionData.speedMod.mode
                        if mode == "C" then
                            mode = "X"
                        elseif mode == "M" then
                            mode = "C"
                        elseif mode == "X" then
                            mode = "M"
                        end
                        optionData.speedMod.mode = mode
                        setSpeedValueFromOptionData()
                    end,
                    Right = function()
                        -- traverse list right, set the speed mod again
                        -- order:
                        -- XMOD - CMOD - MMOD
                        local mode = optionData.speedMod.mode
                        if mode == "C" then
                            mode = "M"
                        elseif mode == "M" then
                            mode = "X"
                        elseif mode == "X" then
                            mode = "C"
                        end
                        optionData.speedMod.mode = mode
                        setSpeedValueFromOptionData()
                    end,
                },
                ChoiceIndexGetter = function()
                    local mode = optionData.speedMod.mode
                    if mode == "X" then return 1
                    elseif mode == "C" then return 2
                    elseif mode == "M" then return 3 end
                end,
            },
            {
                Name = "Scroll Speed",
                Type = "SingleChoiceModifier",
                Explanation = "Change scroll speed value/modifier in increments of 1 or 50.",
                Directions = {
                    Left = function(multiplier)
                        local increment = -1
                        if multiplier then increment = -50 end
                        optionData.speedMod.speed = optionData.speedMod.speed + increment
                        if optionData.speedMod.speed <= 0 then optionData.speedMod.speed = 1 end
                        setSpeedValueFromOptionData()
                    end,
                    Right = function(multiplier)
                        local increment = 1
                        if multiplier then increment = 50 end
                        optionData.speedMod.speed = optionData.speedMod.speed + increment
                        if optionData.speedMod.speed <= 0 then optionData.speedMod.speed = 1 end
                        setSpeedValueFromOptionData()
                    end,
                },
                ChoiceIndexGetter = function()
                    local mode = optionData.speedMod.mode
                    local speed = optionData.speedMod.speed
                    if mode == "X" then
                        return mode .. notShit.round((speed/100), 2)
                    else
                        return mode .. speed
                    end
                end,
            },
            {
                Name = "Scroll Direction",
                Type = "SingleChoice",
                Explanation = "Direction of note scrolling: up or down.",
                Choices = choiceSkeleton("Upscroll", "Downscroll"),
                Directions = {
                    Toggle = function()
                        if not getPlayerOptions():UsingReverse() then
                            -- 1 is 100% reverse which means on
                            setPlayerOptionsModValueAllLevels("Reverse", 1)
                        else
                            -- 0 is 0% reverse which means off
                            setPlayerOptionsModValueAllLevels("Reverse", 0)
                        end
                        MESSAGEMAN:Broadcast("UpdateReverse")
                    end,
                },
                ChoiceIndexGetter = function()
                    if getPlayerOptions():UsingReverse() then
                        return 2
                    else
                        return 1
                    end
                end,
            },
            {
                Name = "Noteskin",
                Type = "SingleChoice",
                Explanation = "Skin of the notes.",
                ChoiceIndexGetter = function()
                    local currentSkinName = getPlayerOptions():NoteSkin()
                    for i, name in ipairs(optionData.noteSkins.names) do
                        if name == currentSkinName then
                            return i
                        end
                    end
                    -- if function gets this far, look for the default skin
                    currentSkinName = THEME:GetMetric("Common", "DefaultNoteSkinName")
                    for i, name in ipairs(optionData.noteSkins.names) do
                        if name == currentSkinName then
                            return i
                        end
                    end
                    -- if function gets this far, cant find anything so just return the first skin
                    return 1
                end,
                ChoiceGenerator = function()
                    local o = {}
                    local skinNames = NOTESKIN:GetNoteSkinNames()
                    for i, name in ipairs(skinNames) do
                        o[#o+1] = {
                            Name = name,
                            ChosenFunction = function()
                                setPlayerOptionsModValueAllLevels("NoteSkin", name)
                                MESSAGEMAN:Broadcast("UpdateVisibleSkin", {name = name})
                            end,
                        }
                    end
                    table.sort(
                        o,
                        function(a, b)
                            return a.Name:lower() < b.Name:lower()
                        end)

                    return o
                end,
            },
            {
                Name = "Receptor Size",
                Type = "SingleChoice",
                Explanation = "Size of receptors and notes. 50% Receptor Size may be called 100% Mini.",
                Directions = {
                    Left = function()
                        local sz = optionData.receptorSize
                        sz = sz - 1
                        if sz < 1 then sz = 200 end
                        optionData.receptorSize = sz
                    end,
                    Right = function()
                        local sz = optionData.receptorSize
                        sz = sz + 1
                        if sz > 200 then sz = 1 end
                        optionData.receptorSize = sz
                    end,
                },
                ChoiceIndexGetter = function()
                    return optionData.receptorSize .. "%"
                end,
            },
            {
                Name = "Judge Difficulty",
                Type = "SingleChoice",
                Explanation = "Timing Window Difficulty. Higher is harder. All scores are converted to Judge 4 later.",
                ChoiceIndexGetter = function()
                    local lowestJudgeDifficulty = 4
                    return GetTimingDifficulty() - (lowestJudgeDifficulty-1)
                end,
                ChoiceGenerator = function()
                    local o = {}
                    for i = 4, 8 do
                        o[#o+1] = {
                            Name = tostring(i),
                            ChosenFunction = function()
                                -- set judge
                                SetTimingDifficulty(i)
                            end,
                        }
                    end
                    o[#o+1] = {
                        Name = "Justice",
                        ChosenFunction = function()
                            -- sets j9
                            SetTimingDifficulty(9)
                        end,
                    }
                    return o
                end,
            },
            {
                Name = "Global Offset",
                Type = "SingleChoice",
                Explanation = "Global Audio Offset in seconds. Negative numbers are early.",
                Directions = preferenceIncrementDecrementDirections("GlobalOffsetSeconds", -5, 5, 0.001),
                ChoiceIndexGetter = function()
                    return notShit.round(PREFSMAN:GetPreference("GlobalOffsetSeconds"), 3) .. "s"
                end,
            },
            {
                Name = "Visual Delay",
                Type = "SingleChoice",
                Explanation = "Visual Note Delay in seconds. May be referred to as Judge Offset. Negative numbers are early.",
                Directions = preferenceIncrementDecrementDirections("VisualDelaySeconds", -5, 5, 0.001),
                ChoiceIndexGetter = function()
                    return notShit.round(PREFSMAN:GetPreference("VisualDelaySeconds"), 3) .. "s"
                end,
            },
            {
                Name = "Game Mode",
                Type = "SingleChoice",
                Explanation = "Dance - 3k/4k/8k | Solo - 6k | Pump - 5k/6k/10k | Beat - 5k+1/7k+1/10k+2/14k+2 | Kb7 - 7k | Popn - 5k/9k",
                ChoiceIndexGetter = function()
                    for i = 1, #optionData.gameMode.modes do
                        if optionData.gameMode.modes[i] == optionData.gameMode.current then
                            return i
                        end
                    end
                    return 1
                end,
                ChoiceGenerator = function()
                    local o = {}
                    for i, name in ipairs(optionData.gameMode.modes) do
                        o[#o+1] = {
                            Name = strCapitalize(name),
                            ChosenFunction = function()
                                --GAMEMAN:SetGame(name)
                                optionData.gameMode.current = name
                            end,
                        }
                    end
                    return o
                end,
            },
            {
                Name = "Fail Type",
                Type = "SingleChoice",
                Explanation = "Toggle failure in Gameplay. Setting Fail Off invalidates scores if a fail would have actually occurred.",
                ChoiceIndexGetter = function()
                    local failtypes = FailType
                    local failtype = getPlayerOptions():FailSetting()
                    for i, name in ipairs(failtypes) do
                        if name == failtype then return i end
                    end
                    return 1
                end,
                ChoiceGenerator = function()
                    -- get the list of fail types
                    local failtypes = FailType
                    local o = {}
                    for i, name in ipairs(failtypes) do
                        o[#o+1] = {
                            Name = THEME:GetString("OptionNames", ToEnumShortString(name)),
                            ChosenFunction = function()
                                setPlayerOptionsModValueAllLevels("FailSetting", name)
                            end,
                        }
                    end
                    return o
                end,
            },
            {
                Name = "Customize Playfield",
                Type = "Button",
                Explanation = "Customize Gameplay elements.",
                Choices = {
                    {
                        Name = "Customize Playfield",
                        ChosenFunction = function()
                            -- activate customize gameplay
                            -- go into gameplay
                        end,
                    }
                }
            },
            {
                Name = "Customize Keybinds",
                Type = "Button",
                Explanation = "Customize Keybinds.",
                Choices = {
                    {
                        Name = "Customize Keybinds",
                        ChosenFunction = function()
                            -- activate keybind screen
                            MESSAGEMAN:Broadcast("ShowSettingsAlt", {name = "Customize Keybinds"})
                        end,
                    }
                }
            },
        },
        --
        -----
        -- APPEARANCE OPTIONS
        ["Appearance Options"] = {
            {
                Name = "Appearance",
                Type = "MultiChoice",
                Explanation = "Hidden - Notes disappear before receptor. Sudden - Notes appear later than usual. Stealth - Invisible notes. Blink - Notes flash.",
                Choices = {
                    -- multiple choices allowed
                    floatSettingChoice("Hidden", "Hidden", 1, 0),
                    floatSettingChoice("HiddenOffset", "HiddenOffset", 1, 0),
                    floatSettingChoice("Sudden", "Sudden", 1, 0),
                    floatSettingChoice("SuddenOffset", "SuddenOffset", 1, 0),
                    floatSettingChoice("Stealth", "Stealth", 1, 0),
                    floatSettingChoice("Blink", "Blink", 1, 0)
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Hidden() ~= 0 then o[1] = true end
                    if po:HiddenOffset() ~= 0 then o[2] = true end
                    if po:Sudden() ~= 0 then o[3] = true end
                    if po:SuddenOffset() ~= 0 then o[4] = true end
                    if po:Stealth() ~= 0 then o[4] = true end
                    if po:Blink() ~= 0 then o[5] = true end
                    return o
                end,
            },
            {
                Name = "Perspective",
                Type = "SingleChoice",
                Explanation = "Controls tilt/skew of the Notefield.",
                Choices = {
                    -- the numbers in these defs are like the percentages you would put in metrics instead
                    -- 1 is 100%
                    -- Overhead does not use percentages.
                    -- adding an additional parameter to these functions does do something (approach rate) but is functionally useless
                    -- you are free to try these untested options for possible weird results:
                    -- setPlayerOptionsModValueAllLevels("Skew", x)
                    -- setPlayerOptionsModValueAllLevels("Tilt", x)
                    {
                        Name = "Overhead",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("Overhead", true)
                        end,
                    },
                    {
                        Name = "Incoming",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("Incoming", 1)
                        end,
                    },
                    {
                        Name = "Space",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("Space", 1)
                        end,
                    },
                    {
                        Name = "Hallway",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("Hallway", 1)
                        end,
                    },
                    {
                        Name = "Distant",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("Distant", 1)
                        end,
                    },
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    -- we unfortunately choose to hardcode these options and not allow an additional custom one
                    -- but the above choice definitions allow customizing the specific Perspective to whatever extent you want
                    local o = {}
                    if po:Overhead() then return 1
                    elseif po:Incoming() ~= nil then return 2
                    elseif po:Space() ~= nil then return 3
                    elseif po:Hallway() ~= nil then return 4
                    elseif po:Distant() ~= nil then return 5
                    end
                    return o
                end,
            },
            {
                Name = "Mirror",
                Type = "SingleChoice",
                Explanation = "Horizontally flip Notedata.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = {
                    Toggle = function()
                        local po = getPlayerOptions()
                        if po:Mirror() then
                            setPlayerOptionsModValueAllLevels("Mirror", false)
                        else
                            setPlayerOptionsModValueAllLevels("Mirror", true)
                        end
                    end,
                },
                ChoiceIndexGetter = function()
                    if getPlayerOptions():Mirror() then
                        return 1
                    else
                        return 2
                    end
                end,
            },
            {
                Name = "Hide Player UI",
                Type = "MultiChoice",
                Explanation = "Hide certain sets of elements from the Gameplay UI.",
                Choices = {
                    floatSettingChoice("Hide Receptors", "Dark", 1, 0),
                    floatSettingChoice("Hide Judgment & Combo", "Blind", 1, 0),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Dark() ~= 0 then o[1] = true end
                    if po:Blind() ~= 0 then o[2] = true end
                    return o
                end,
            },
            {
                Name = "Hidenote Judgment",
                Type = "SingleChoice",
                Explanation = "Notes must be hit with this judgment or better to disappear.",
                Choices = {
                    {
                        Name = "Miss",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("MinTNSToHideNotes", "TNS_Miss")
                        end,
                    },
                    {
                        Name = "Bad",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("MinTNSToHideNotes", "TNS_W5")
                        end,
                    },
                    {
                        Name = "Good",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("MinTNSToHideNotes", "TNS_W4")
                        end,
                    },
                    {
                        Name = "Great",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("MinTNSToHideNotes", "TNS_W3")
                        end,
                    },
                    {
                        Name = "Perfect",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("MinTNSToHideNotes", "TNS_W2")
                        end,
                    },
                    {
                        Name = "Marvelous",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("MinTNSToHideNotes", "TNS_W1")
                        end,
                    },
                },
                ChoiceIndexGetter = function()
                    local opt = PREFSMAN:GetPreference("MinTNSToHideNotes")
                    if opt == "TNS_Miss" then return 1
                    elseif opt == "TNS_W5" then return 2
                    elseif opt == "TNS_W4" then return 3
                    elseif opt == "TNS_W3" then return 4
                    elseif opt == "TNS_W2" then return 5
                    elseif opt == "TNS_W1" then return 6
                    else
                        return 4 -- this is the default option so default to this
                    end
                end,
            },
            {
                Name = "Default Centered NoteField",
                Type = "SingleChoice",
                Explanation = "Horizontally center the Notefield in Gameplay (Legacy Shortcut).",
                Choices = choiceSkeleton("Yes", "No"),
                Directions = preferenceToggleDirections("Center1Player", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("Center1Player", true),
            },
            {
                Name = "NoteField BG Opacity",
                Type = "SingleChoice",
                Explanation = "Set the opacity of the board behind the Notefield in Gameplay.",
                ChoiceGenerator = function()
                    local o = {}
                    for i = 0, 10 do -- 11 choices
                        o[#o+1] = {
                            Name = notShit.round(i*10,0).."%",
                            ChosenFunction = function()
                                optionData.screenFilter = notShit.round(i / 10, 1)
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local v = notShit.round(optionData.screenFilter, 1)
                    local ind = notShit.round(v * 10, 0) + 1
                    if ind > 0 and ind < 11 then -- this 11 should match the number of choices above
                        return ind
                    else
                        if ind <= 0 then
                            return 1
                        else
                            return 11
                        end
                    end
                end,
            },
            {
                Name = "Background Brightness",
                Type = "SingleChoice",
                Explanation = "Set the brightness of the background in Gameplay. 0% will disable background loading.",
                ChoiceGenerator = function()
                    local o = {}
                    for i = 0, 10 do -- 11 choices
                        o[#o+1] = {
                            Name = notShit.round(i*10,0).."%",
                            ChosenFunction = function()
                                PREFSMAN:SetPreference("BGBrightness", notShit.round(i / 10, 1))
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local v = notShit.round(PREFSMAN:GetPreference("BGBrightness"))
                    local ind = notShit.round(v * 10, 0) + 1
                    if ind > 0 and ind < 11 then -- this 11 should match the nubmer of choices above
                        return ind
                    else
                        if ind <= 0 then
                            return 1
                        else
                            return 11
                        end
                    end
                end,
            },
            {
                Name = "Replay Mod Emulation",
                Type = "SingleChoice",
                Explanation = "Toggle temporarily using compatible mods that replays used when watching them.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("ReplaysUseScoreMods", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("ReplaysUseScoreMods", true),
            },
            {
                Name = "Extra Scroll Mods",
                Type = "MultiChoice",
                Explanation = "Change scroll direction in more interesting ways.",
                Choices = {
                    floatSettingChoice("Split", "Split", 1, 0),
                    floatSettingChoice("Alternate", "Alternate", 1, 0),
                    floatSettingChoice("Cross", "Cross", 1, 0),
                    floatSettingChoice("Centered", "Centered", 1, 0),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Split() ~= 0 then o[1] = true end
                    if po:Alternate() ~= 0 then o[2] = true end
                    if po:Cross() ~= 0 then o[3] = true end
                    if po:Centered() ~= 0 then o[4] = true end
                    return o
                end,
            },
            {
                Name = "Fun Effects",
                Type = "MultiChoice",
                Explanation = "Visual scroll mods that are not for practical use.",
                Choices = {
                    floatSettingChoice("Drunk", "Drunk", 1, 0),
                    floatSettingChoice("Confusion", "Confusion", 1, 0),
                    floatSettingChoice("Tiny", "Tiny", 1, 0),
                    floatSettingChoice("Flip", "Flip", 1, 0),
                    floatSettingChoice("Invert", "Invert", 1, 0),
                    floatSettingChoice("Tornado", "Tornado", 1, 0),
                    floatSettingChoice("Tipsy", "Tipsy", 1, 0),
                    floatSettingChoice("Bumpy", "Bumpy", 1, 0),
                    floatSettingChoice("Beat", "Beat", 1, 0),
                    -- X-Mode is dead because it relies on player 2!! -- floatSettingChoice("X-Mode"),
                    floatSettingChoice("Twirl", "Twirl", 1, 0),
                    floatSettingChoice("Roll", "Roll", 1, 0),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Drunk() ~= 0 then o[1] = true end
                    if po:Confusion() ~= 0 then o[2] = true end
                    if po:Tiny() ~= 0 then o[3] = true end
                    if po:Flip() ~= 0 then o[4] = true end
                    if po:Invert() ~= 0 then o[5] = true end
                    if po:Tornado() ~= 0 then o[6] = true end
                    if po:Tipsy() ~= 0 then o[7] = true end
                    if po:Bumpy() ~= 0 then o[8] = true end
                    if po:Beat() ~= 0 then o[9] = true end
                    if po:Twirl() ~= 0 then o[10] = true end
                    if po:Roll() ~= 0 then o[11] = true end
                    return o
                end,
            },
            {
                Name = "Acceleration",
                Type = "MultiChoice",
                Explanation = "Scroll speed mods usually not for practical use.",
                Choices = {
                    floatSettingChoice("Boost", "Boost", 1, 0),
                    floatSettingChoice("Brake", "Brake", 1, 0),
                    floatSettingChoice("Wave", "Wave", 1, 0),
                    floatSettingChoice("Expand", "Expand", 1, 0),
                    floatSettingChoice("Boomerang", "Boomerang", 1, 0),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Boost() ~= 0 then o[1] = true end
                    if po:Brake() ~= 0 then o[2] = true end
                    if po:Wave() ~= 0 then o[3] = true end
                    if po:Expand() ~= 0 then o[4] = true end
                    if po:Boomerang() ~= 0 then o[5] = true end
                    return o
                end,
            }
        },
        --
        -----
        -- INVALIDATING OPTIONS
        ["Invalidating Options"] = {
            {
                Name = "Mines",
                Type = "SingleChoice",
                Explanation = "Toggle Mines. Extra Mines will replace entire rows of notes with mines.",
                Choices = {
                    {
                        Name = "On",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("NoMines", false)
                            setPlayerOptionsModValueAllLevels("Mines", false)
                        end,
                    },
                    {
                        Name = "Off",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("NoMines", true)
                            setPlayerOptionsModValueAllLevels("Mines", false)
                        end,
                    },
                    {
                        Name = "Extra Mines",
                        ChosenFunction = function()
                            setPlayerOptionsModValueAllLevels("NoMines", false)
                            setPlayerOptionsModValueAllLevels("Mines", true)
                        end,
                    }
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    if po:Mines() then
                        -- additive mines, invalidating
                        return 3
                    elseif po:NoMines() then
                        -- nomines, invalidating
                        return 2
                    else
                        -- regular mines, not invalidating
                        return 1
                    end
                end,
            },
            {
                Name = "Turn",
                Type = "MultiChoice",
                Explanation = "Modify Notedata by either shifting all notes or randomizing them.",
                Choices = {
                    booleanSettingChoice("Backwards", "Backwards"),
                    booleanSettingChoice("Left", "Left"),
                    booleanSettingChoice("Right", "Right"),
                    booleanSettingChoice("Shuffle", "Shuffle"),
                    booleanSettingChoice("Soft Shuffle", "SoftShuffle"),
                    booleanSettingChoice("Super Shuffle", "SuperShuffle"),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Backwards() then o[1] = true end
                    if po:Left() then o[2] = true end
                    if po:Right() then o[3] = true end
                    if po:Shuffle() then o[4] = true end
                    if po:SoftShuffle() then o[5] = true end
                    if po:SuperShuffle() then o[6] = true end
                    return o
                end,
            },
            {
                Name = "Pattern Transform",
                Type = "MultiChoice",
                Explanation = "Modify Notedata by inserting extra notes to create certain patterns.",
                Choices = {
                    booleanSettingChoice("Echo", "Echo"),
                    booleanSettingChoice("Stomp", "Stomp"),
                    booleanSettingChoice("Jack JS", "JackJS"),
                    booleanSettingChoice("Anchor JS", "AnchorJS"),
                    booleanSettingChoice("IcyWorld", "IcyWorld"),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Echo() then o[1] = true end
                    if po:Stomp() then o[2] = true end
                    if po:JackJS() then o[3] = true end
                    if po:AnchorJS() then o[4] = true end
                    if po:IcyWorld() then o[5] = true end
                    return o
                end,
            },
            {
                Name = "Hold Transform",
                Type = "MultiChoice",
                Explanation = "Modify holds in Notedata.",
                Choices = {
                    booleanSettingChoice("Planted", "Planted"),
                    booleanSettingChoice("Floored", "Floored"),
                    booleanSettingChoice("Twister", "Twister"),
                    booleanSettingChoice("Holds To Rolls", "HoldRolls"),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Planted() then o[1] = true end
                    if po:Floored() then o[2] = true end
                    if po:Twister() then o[3] = true end
                    if po:HoldRolls() then o[4] = true end
                    return o
                end,
            },
            {
                Name = "Remove",
                Type = "MultiChoice",
                Explanation = "Remove certain notes, patterns, or types of notes.",
                Choices = {
                    booleanSettingChoice("No Holds", "NoHolds"),
                    booleanSettingChoice("No Rolls", "NoRolls"),
                    booleanSettingChoice("No Jumps", "NoJumps"),
                    booleanSettingChoice("No Hands", "NoHands"),
                    booleanSettingChoice("No Lifts", "NoLifts"),
                    booleanSettingChoice("No Fakes", "NoFakes"),
                    booleanSettingChoice("No Quads", "NoQuads"),
                    booleanSettingChoice("No Stretch", "NoStretch"),
                    booleanSettingChoice("Little", "Little"),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:NoHolds() then o[1] = true end
                    if po:NoRolls() then o[2] = true end
                    if po:NoJumps() then o[3] = true end
                    if po:NoHands() then o[4] = true end
                    if po:NoLifts() then o[5] = true end
                    if po:NoFakes() then o[6] = true end
                    if po:NoQuads() then o[7] = true end
                    if po:NoStretch() then o[8] = true end
                    if po:Little() then o[9] = true end
                    return o
                end,
            },
            {
                Name = "Insert",
                Type = "MultiChoice",
                Explanation = "Modify Notedata by inserting extra notes to provide a certain feeling.",
                Choices = {
                    booleanSettingChoice("Wide", "Wide"),
                    booleanSettingChoice("Big", "Big"),
                    booleanSettingChoice("Quick", "Quick"),
                    booleanSettingChoice("BMR-ize", "BMRize"),
                    booleanSettingChoice("Skippy", "Skippy"),
                },
                ChoiceIndexGetter = function()
                    local po = getPlayerOptions()
                    local o = {}
                    if po:Wide() then o[1] = true end
                    if po:Big() then o[2] = true end
                    if po:Quick() then o[3] = true end
                    if po:BMRize() then o[4] = true end
                    if po:Skippy() then o[5] = true end
                    return o
                end,
            }
        },
        --
        -----
        -- GLOBAL GRAPHICS OPTIONS
        ["Global Options"] = {
            {
                Name = "Language",
                Type = "SingleChoice",
                Explanation = "Modify the game language.",
                ChoiceGenerator = function()
                    local o = {}
                    for i, l in ipairs(optionData.language.list) do
                        o[#o+1] = {
                            Name = l:upper(),
                            ChosenFunction = function()
                                optionData.language.current = l
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    for i, l in ipairs(optionData.language.list) do
                        if l == optionData.language.current then return i end
                    end
                    return 1
                end,
            },
            {
                Name = "Display Mode",
                Type = "SingleChoice",
                Explanation = "Change the game display mode. Borderless requires that you select your native fullscreen resolution.",
                -- the idea behind Display Mode is to also allow selecting a Display to show the game
                -- it is written into the lua side of the c++ options conf but unused everywhere as far as i know except maybe in linux
                -- so here lets just hardcode windowed/fullscreen until that feature becomes a certain reality
                -- and lets add borderless here so that the options are simplified just a bit
                Choices = {
                    {
                        Name = "Windowed",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("Windowed", true)
                            PREFSMAN:SetPreference("FullscreenIsBorderlessWindow", false)
                        end,
                    },
                    {
                        Name = "Fullscreen",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("Windowed", false)
                            PREFSMAN:SetPreference("FullscreenIsBorderlessWindow", false)
                        end,
                    },
                    {
                        -- funny thing about this preference is that it doesnt force fullscreen
                        -- so you have to pick the right resolution for it to work
                        Name = "Borderless",
                        ChosenFunction = function()
                            PREFSMAN:SetPreference("Windowed", false)
                            PREFSMAN:SetPreference("FullscreenIsBorderlessWindow", true)
                        end,
                    }

                },
                ChoiceIndexGetter = function()
                    if PREFSMAN:GetPreference("FullscreenIsBorderlessWindow") then
                        return 3
                    elseif PREFSMAN:GetPreference("Windowed") then
                        return 1
                    else
                        -- fullscreen exclusive
                        return 2
                    end
                end,
            },
            {
                Name = "Aspect Ratio",
                Type = "SingleChoice",
                Explanation = "Change the game aspect ratio.",
                ChoiceGenerator = function()
                    local o = {}
                    for _, ratio in ipairs(optionData.display.ratios) do
                        -- ratio is a fraction, d is denominator and n is numerator
                        local v = ratio.n / ratio.d
                        o[#o+1] = {
                            Name = ratio.n .. ":" .. ratio.d,
                            ChosenFunction = function()
                                PREFSMAN:SetPreference("DisplayAspectRatio", v)
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local closestdiff = 100
                    local closestindex = 1
                    local curRatio = PREFSMAN:GetPreference("DisplayAspectRatio")
                    for i, ratio in ipairs(optionData.display.ratios) do
                        -- ratio is a fraction, d is denominator and n is numerator
                        local v = ratio.n / ratio.d
                        local diff = math.abs(v - curRatio)
                        if diff < closestdiff then
                            closestdiff = diff
                            closestindex = i
                        end
                    end
                    return closestindex
                end,
            },
            {
                Name = "Display Resolution",
                Type = "SingleChoice",
                Explanation = "Change the game display resolution.",
                ChoiceGenerator = function()
                    local o = {}

                    -- i trust we didnt generate any duplicates but ....
                    -- ....... hope not
                    for _, resolution in ipairs(optionData.display.resolutions) do
                        -- resolution is a rectangle and contains a width w and a height h
                        o[#o+1] = {
                            Name = resolution.w .. "x" .. resolution.h,
                            ChosenFunction = function()
                                PREFSMAN:SetPreference("DisplayWidth", resolution.w)
                                PREFSMAN:SetPreference("DisplayHeight", resolution.h)
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local closestindex = 1
                    local mindist = -1
                    local w = PREFSMAN:GetPreference("DisplayWidth")
            		local h = PREFSMAN:GetPreference("DisplayHeight")
                    for i, resolution in ipairs(optionData.display.resolutions) do
                        -- resolution is a rectangle and contains a width w and a height h
                        local dist = math.sqrt((resolution.w - w)^2 + (resolution.h - h)^2)
                        if mindist == -1 or dist < mindist then
                            mindist = dist
                            closestindex = i
                        end
                    end
                    return closestindex
                end,
            },
            {
                Name = "Refresh Rate",
                Type = "SingleChoice",
                Explanation = "Change the game refresh rate. Set to default in most cases or if any issue occurs.",
                ChoiceGenerator = function()
                    local o = {
                        {
                            Name = "Default",
                            ChosenFunction = function()
                                PREFSMAN:SetPreference("RefreshRate", REFRESH_DEFAULT)
                            end,
                        }
                    }
                    for _, rate in ipairs(optionData.display.refreshRates) do
                        o[#o+1] = {
                            Name = tostring(rate),
                            ChosenFunction = function()
                                PREFSMAN:SetPreference("RefreshRate", rate)
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local rate = PREFSMAN:GetPreference("RefreshRate")
                    -- first choice element is this
                    if rate == REFRESH_DEFAULT then return 1 end

                    -- add 1 to index if found
                    for i, r in ipairs(optionData.display.refreshRates) do
                        if rate == r then return i+1 end
                    end

                    -- default
                    return 1
                end,
            },
            {
                Name = "Display Color Depth",
                Type = "SingleChoice",
                Explanation = "Change the color depth of the game according to your display. Usually not worth changing.",
                Choices = {
                    basicNamedPreferenceChoice("DisplayColorDepth", "16bit", 16),
                    basicNamedPreferenceChoice("DisplayColorDepth", "32bit", 32),
                },
                ChoiceIndexGetter = function()
                    local v = PREFSMAN:GetPreference("DisplayColorDepth")
                    if v == 16 then return 1
                    elseif v == 32 then return 2
                    end
                    return 1
                end,
            },
            {
                Name = "Force High Resolution Textures",
                Type = "SingleChoice",
                Explanation = "Force high resolution textures. Turning this off disables the (doubleres) image tag.",
                Choices = choiceSkeleton("Yes", "No"),
                Directions = preferenceToggleDirections("HighResolutionTextures", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("HighResolutionTextures", true),
            },
            {
                Name = "Texture Resolution",
                Type = "SingleChoice",
                Explanation = "Modify general texture resolution. Lower number will lower quality but may increase FPS.",
                Choices = {
                    basicNamedPreferenceChoice("MaxTextureResolution", "256", 256),
                    basicNamedPreferenceChoice("MaxTextureResolution", "512", 512),
                    basicNamedPreferenceChoice("MaxTextureResolution", "1024", 1024),
                    basicNamedPreferenceChoice("MaxTextureResolution", "2048", 2048),
                },
                ChoiceIndexGetter = function()
                    local v = PREFSMAN:GetPreference("MaxTextureResolution")
                    if v == 256 then return 1
                    elseif v == 512 then return 2
                    elseif v == 1024 then return 3
                    elseif v == 2048 then return 4
                    end
                    return 1
                end,
            },
            {
                Name = "Texture Color Depth",
                Type = "SingleChoice",
                Explanation = "Change the color depth of the textures in the game. Usually not worth changing.",
                Choices = {
                    basicNamedPreferenceChoice("TextureColorDepth", "16bit", 16),
                    basicNamedPreferenceChoice("TextureColorDepth", "32bit", 32),
                },
                ChoiceIndexGetter = function()
                    local v = PREFSMAN:GetPreference("TextureColorDepth")
                    if v == 16 then return 1
                    elseif v == 32 then return 2
                    end
                    return 1
                end,
            },
            {
                Name = "Movie Color Depth",
                Type = "SingleChoice",
                Explanation = "Change the color depth of the movie textures in the game. Usually not worth changing.",
                Choices = {
                    basicNamedPreferenceChoice("MovieColorDepth", "16bit", 16),
                    basicNamedPreferenceChoice("MovieColorDepth", "32bit", 32),
                },
                ChoiceIndexGetter = function()
                    local v = PREFSMAN:GetPreference("MovieColorDepth")
                    if v == 16 then return 1
                    elseif v == 32 then return 2
                    end
                    return 1
                end,
            },
            {
                Name = "VSync",
                Type = "SingleChoice",
                Explanation = "Restrict the game refresh rate and FPS to the refresh rate you have set.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("Vsync", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("Vsync", true),
            },
            {
                Name = "Instant Search",
                Type = "SingleChoice",
                Explanation = "Song search behavior - turning this on will instantly update the song wheel as you type in song search.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = optionDataToggleDirections("instantSearch", true, false),
                ChoiceIndexGetter = optionDataToggleIndexGetter("instantSearch", true),
            },
            {
                Name = "Fast Note Rendering",
                Type = "SingleChoice",
                Explanation = "Optimize gameplay note rendering. Disable snap based noteskin features (not snaps themselves). Major boost to FPS.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("FastNoteRendering", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("FastNoteRendering", true),
            },
            {
                Name = "Show Stats",
                Type = "SingleChoice",
                Explanation = "Show FPS display on screen.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("ShowStats", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("ShowStats", true),
            },
        },
        --
        -----
        -- THEME OPTIONS
        ["Theme Options"] = {
            {
                Name = "Theme",
                Type = "SingleChoice",
                Explanation = "Change the overall skin of the game.",
                ChoiceGenerator = function()
                    local o = {}
                    for _, name in ipairs(THEME:GetSelectableThemeNames()) do
                        o[#o+1] = {
                            Name = name,
                            ChosenFunction = function()
                                optionData.pickedTheme = name
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local cur = optionData.pickedTheme
                    for i, name in ipairs(THEME:GetSelectableThemeNames()) do
                        if name == cur then return i end
                    end
                    return 1
                end,
            },
            {
                Name = "Music Wheel Position",
                Type = "SingleChoice",
                Explanation = "Set the side of the screen for the music wheel.",
                Choices = choiceSkeleton("Left", "Right"),
                Directions = optionDataToggleDirections("wheelPosition", true, false),
                ChoiceIndexGetter = optionDataToggleIndexGetter("wheelPosition", true),
            },
            {
                Name = "Show Backgrounds",
                Type = "SingleChoice",
                Explanation = "Toggle showing backgrounds everywhere.",
                Choices = choiceSkeleton("Yes", "No"),
                Directions = optionDataToggleDirections("showBackgrounds", true, false),
                ChoiceIndexGetter = optionDataToggleIndexGetter("showBackgrounds", true),
            },
            {
                Name = "Easter Eggs & Toasties",
                Type = "SingleChoice",
                Explanation = "Toggle showing secret jokes and toasties.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("EasterEggs", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("EasterEggs", true),
            },
            {
                Name = "Music Visualizer",
                Type = "SingleChoice",
                Explanation = "Toggle showing the visualizer in the song select screen.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = optionDataToggleDirections("showVisualizer", true, false),
                ChoiceIndexGetter = optionDataToggleIndexGetter("showVisualizer", true),
            },
            {
                Name = "Mid Grades",
                Type = "SingleChoice",
                Explanation = "Toggle showing the grades in between the major grades. Requires game restart.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("UseMidGrades", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("UseMidGrades", true),
            },
            {
                Name = "SSRNorm Sort",
                Type = "SingleChoice",
                Explanation = "Toggle automatically sorting by and defaulting to the SSRNorm globally. The SSRNorm is the Judge 4 value of a highscore. Requires game restart.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("SortBySSRNormPercent", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("SortBySSRNormPercent", true),
            },
            {
                Name = "Show Lyrics",
                Type = "SingleChoice",
                Explanation = "Toggle showing lyrics for songs which contain compatible .lrc files.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("ShowLyrics", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("ShowLyrics", true),
            },
            {
                Name = "Transliteration",
                Type = "SingleChoice",
                Explanation = "Toggle showing author-defined translations on song metadata fields.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = {
                    Toggle = function()
                        if PREFSMAN:GetPreference("ShowNativeLanguage") then
                            PREFSMAN:SetPreference("ShowNativeLanguage", false)
                        else
                            PREFSMAN:SetPreference("ShowNativeLanguage", true)
                        end
                        MESSAGEMAN:Broadcast("DisplayLanguageChanged")
                    end,
                },
                ChoiceIndexGetter = preferenceToggleIndexGetter("ShowNativeLanguage", true),
            },
            {
                Name = "Tip Type",
                Type = "SingleChoice",
                Explanation = "Change the quips shown at the bottom of the evaluation screen.",
                Choices = choiceSkeleton("Tips", "Quotes"),
                Directions = optionDataToggleDirections("tipType", 1, 2),
                ChoiceIndexGetter = optionDataToggleIndexGetter("tipType", 1),
            },
            {
                Name = "Set BG Fit Mode",
                Type = "SingleChoice",
                Explanation = "Change the cropping strategy of background images.",
                ChoiceGenerator = function()
                    local o = {}
                    for _, fit in ipairs(BackgroundFitMode) do
                        o[#o+1] = {
                            Name = THEME:GetString("ScreenSetBGFit", ToEnumShortString(fit)),
                            ChosenFunction = function()
                                PREFSMAN:SetPreference("BackgroundFitMode", ToEnumShortString(fit))
                            end,
                        }
                    end
                    return o
                end,
                ChoiceIndexGetter = function()
                    local cur = PREFSMAN:GetPreference("BackgroundFitMode")
                    for i, fit in ipairs(BackgroundFitMode) do
                        if ToEnumShortString(fit) == cur then
                            return i
                        end
                    end
                    return 1
                end,
            },
            {
                Name = "Color Config",
                Type = "Button",
                Explanation = "Modify the colors of this theme.",
                Choices = {
                    {
                        Name = "Color Config",
                        ChosenFunction = function()
                            -- activate color config screen
                        end,
                    },
                }
            },
        },
        --
        -----
        -- SOUND OPTIONS
        ["Sound Options"] = {
            {
                Name = "Volume",
                Type = "SingleChoice",
                Explanation = "All sound volume.",
                Directions = preferenceIncrementDecrementDirections("SoundVolume", 0, 1, 0.01),
                ChoiceIndexGetter = function()
                    return notShit.round(PREFSMAN:GetPreference("SoundVolume") * 100, 0) .. "%"
                end,
            },
            {
                Name = "Menu Sounds",
                Type = "SingleChoice",
                Explanation = "Toggle sounds on menu items.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("MuteActions", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("MuteActions", false),
            },
            {
                Name = "Mine Sounds",
                Type = "SingleChoice",
                Explanation = "Toggle sounds for mine explosions.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("EnableMineHitSound", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("EnableMineHitSound", true),
            },
            {
                Name = "Pitch on Rates",
                Type = "SingleChoice",
                Explanation = "Toggle pitch changes for songs when using rates.",
                Choices = choiceSkeleton("On", "Off"),
                Directions = preferenceToggleDirections("EnablePitchRates", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("EnablePitchRates", true),
            },
            {
                Name = "Calibrate Audio Sync",
                Type = "Button",
                Explanation = "Calibrate the audio sync for the entire game.",
                Choices = {
                    {
                        Name = "Calibrate Audio Sync",
                        ChosenFunction = function()
                            -- go to machine sync screen
                            SCUFF.screenAfterSyncMachine = SCREENMAN:GetTopScreen():GetName()
                            SCREENMAN:SetNewScreen("ScreenGameplaySyncMachine")
                        end,
                    },
                },
            },
        },
        --
        -----
        -- INPUT OPTIONS
        ["Input Options"] = {
            {
                Name = "Back Delayed",
                Type = "SingleChoice",
                Explanation = "Modify the behavior of the back button in gameplay.",
                Choices = choiceSkeleton("Hold", "Instant"),
                Directions = preferenceToggleDirections("DelayedBack", true, false),
                ChoiceIndexGetter = preferenceToggleIndexGetter("DelayedBack", true),
            },
            {
                Name = "Input Debounce Time",
                Type = "SingleChoice",
                Explanation = "Set the amount of time required between each repeated input.",
                Directions = preferenceIncrementDecrementDirections("InputDebounceTime", 0, 1, 0.01),
                ChoiceIndexGetter = function()
                    return notShit.round(PREFSMAN:GetPreference("InputDebounceTime"), 2) .. "s"
                end,
            },
            {
                Name = "Test Input",
                Type = "Button",
                Explanation = "Enter a screen to test all input devices.",
                Choices = {
                    {
                        Name = "Test Input",
                        ChosenFunction = function()
                            -- go to test input screen
                        end,
                    }
                }
            },
        },
        --
        -----
        -- PROFILE OPTIONS
        ["Profile Options"] = {
            {
                Name = "Create Profile",
                Type = "Button",
                Explanation = "Create a new profile.",
                Choices = {
                    {
                        Name = "Create Profile",
                        ChosenFunction = function()
                            -- make a profile
                        end,
                    }
                }
            },
            {
                Name = "Rename Profile",
                Type = "Button",
                Explanation = "Rename an existing profile.",
                Choices = {
                    {
                        Name = "Rename Profile",
                        ChosenFunction = function()
                            -- rename a profile
                        end,
                    }
                }
            },
        },
    }
    -- check for choice generators on any option definitions and execute them
    for categoryName, categoryDefinition in pairs(optionDefs) do
        for i, optionDef in ipairs(categoryDefinition) do
            if optionDef.Choices == nil and optionDef.ChoiceGenerator ~= nil then
                optionDefs[categoryName][i].Choices = optionDef.ChoiceGenerator()
            end
        end
    end

    -- internal tracker for where the cursor can be and has been within a row
    -- the index of each entry is simply the row number on the right side of the screen
    -- for a context switch to the left, those are managed by each respective panel separately
    -- format: (each entry)
    --[[{
            NumChoices = x, -- number of choices, simply. 0 means this is a button to press. 1 is a SingleChoice. N is MultiChoice
            HighlightedChoice = x, -- position of the highlighted choice. 1 for Single/Button. N for MultiChoice. Account for the pagination (in other visual representations, not here).
            LinkedItem = x, -- either a category name or an optionDef
        } ]]
    local availableCursorPositions = {}
    local rightPaneCursorPosition = 1 -- current index of the above table

    -- container function/frame for all option rows
    local function createOptionRows()
        -- Unfortunate design choice:
        -- For every option row, we are going to place every single possible row type.
        -- This means there's a ton of invisible elements.
        -- Is this worth doing? This is better than telling the C++ to let us generate and destroy arbitrary Actors at runtime
        -- (I consider this dangerous and also too complex to implement)
        -- So instead we "carefully" manage all pieces of an option row...
        -- Luckily we can be intelligent about wasting space.
        -- First, we parse all of the optionData to see which choices need what elements.
        -- We pass that information on to the rows (we can precalculate which rows have what choices)
        -- This way we can avoid generating Actor elements which will never be used in a row

        -- Alternative to doing the above and below:
        -- just use ActorFrame.RemoveChild and ActorFrame.AddChildFromPath

        -- table of row index keys to lists of row types
        -- valid row types are in the giant option definition comment block
        local rowTypes = {}
        -- table of row index keys to counts of how many text objects to generate
        -- this should correlate to how many choices are possible in a row on any option page
        local rowChoiceCount = {}
        for _, optionPage in ipairs(pageNames) do
            for i, categoryName in ipairs(optionPageCategoryLists[optionPage]) do
                local categoryDefinition = optionDefs[categoryName]

                -- declare certain rows are categories
                -- (current row and the remaining rows after the set of options in this category)
                if rowTypes[i] ~= nil then
                    rowTypes[i]["Category"] = true
                else
                    rowTypes[i] = {Category = true}
                end
                for ii = (i+1), (#optionPageCategoryLists[optionPage]) do
                    local categoryRowIndex = ii + #categoryDefinition
                    if rowTypes[categoryRowIndex] ~= nil then
                        rowTypes[categoryRowIndex]["Category"] = true
                    else
                        rowTypes[categoryRowIndex] = {Category = true}
                    end
                end

                for j, optionDef in ipairs(categoryDefinition) do
                    local rowIndex = j + i -- skip the rows for option category names

                    -- option types for every row
                    if rowTypes[rowIndex] ~= nil then
                        rowTypes[rowIndex][optionDef.Type] = true
                    else
                        rowTypes[rowIndex] = {[optionDef.Type] = true}
                    end

                    -- option choice count for every row
                    local rcc = rowChoiceCount[rowIndex]
                    if rcc == nil then
                        rowChoiceCount[rowIndex] = 0
                        rcc = 0
                    end
                    local defcount = #(optionDef.Choices or {})
                    -- the only case we should show multiple choices is for MultiChoice...
                    if optionDef.Type ~= "MultiChoice" then defcount = 1 end
                    if rcc < defcount then
                        rowChoiceCount[rowIndex] = defcount
                    end
                end
            end
        end

        -- updates the explanation text.
        local function updateExplainText(self)
            if self.defInUse ~= nil and self.defInUse.Explanation ~= nil then
                if explanationHandle ~= nil then
                    if explanationHandle.txt ~= self.defInUse.Explanation then
                        explanationHandle:playcommand("SetExplanation", {text = self.defInUse.Explanation})
                    end
                else
                    explanationHandle:playcommand("SetExplanation", {text = ""})
                end
            else
                explanationHandle:playcommand("SetExplanation", {text = ""})
            end
        end

        ----- state variables, dont mess
        -- currently selected options page - from pageNames
        local selectedPageName = pageNames[1] -- default to first
        local selectedPageDef = optionPageCategoryLists[selectedPageName]
        -- currently opened option category - from optionPageCategoryLists
        local openedCategoryName = selectedPageDef[1] -- default to first
        local openedCategoryDef = optionDefs[openedCategoryName]
        -- index of the opened option category to know the index of the first valid option row to assign option defs
        local openedCategoryIndex = 1
        local optionRowContainer = nil

        -- fills out availableCursorPositions based on current conditions of the above variables
        local function generateCursorPositionMap()
            availableCursorPositions = {}
            rightPaneCursorPosition = 1

            -- theres a list of categories on the page (selectedPageDef)
            -- theres a category that is opened on this page (openedCategoryDef)
            -- add each category up to and including the opened category to the list
            -- then add each option to the list
            -- then add the rest of the categories to the list
            -- (this is the same as how we display the options below somewhere)
            -- we assume openedCategoryIndex is correct at all times
            -- also assume you cannot close an opened Category except by opening a different category or page

            -- add each category up to and including the opened category
            for i = 1, openedCategoryIndex do
                local opened = false
                if i == openedCategoryIndex then opened = true end
                availableCursorPositions[#availableCursorPositions+1] = {
                    NumChoices = 0,
                    HighlightedChoice = 1,
                    LinkedItem = {
                        Opened = opened,
                        Name = selectedPageDef[i],
                    },
                }
            end

            -- put the cursor on the first option after the opened category
            rightPaneCursorPosition = openedCategoryIndex+1

            -- add each option in the category
            for i = 1, #openedCategoryDef do
                local def = openedCategoryDef[i]
                local nchoices = 0
                if def.Type == "Button" then
                    nchoices = 0
                elseif def.Type == "SingleChoice" or def.Type == "SingleChoiceModifier" then
                    -- naturally we would let people hover and press the second set of buttons in SingleChoiceModifier but i would rather force that to be a ctrl+direction instead
                    -- that seems a little more fluid than moving to the directional button and pressing it
                    nchoices = 1
                elseif def.Type == "MultiChoice" then
                    nchoices = #(def.Choices or {})
                end
                availableCursorPositions[#availableCursorPositions+1] = {
                    NumChoices = nchoices,
                    HighlightedChoice = 1,
                    LinkedItem = def,
                }
            end

            -- add each category remaining after the last option
            for i = openedCategoryIndex+1, #selectedPageDef do
                availableCursorPositions[#availableCursorPositions+1] = {
                    NumChoices = 0,
                    HighlightedChoice = 1,
                    LinkedItem = {
                        Opened = false,
                        Name = selectedPageDef[i],
                    }
                }
            end

            -- and if things turn out broken at this point it isnt my fault
        end

        -- find the ActorFrame for an OptionRow by an Option Name
        local function getRowForCursorByName(name)
            if optionRowContainer == nil then return nil end

            for i, row in ipairs(optionRowContainer:GetChildren()) do
                if row.defInUse ~= nil and row.defInUse.Name == name then
                    return row
                end
            end
            return nil
        end

        -- find the (cursor) index of an OptionRow by an Option Name
        local function getRowIndexByName(name)
            if availableCursorPositions == nil then return nil end

            for i, cursorRowDef in ipairs(availableCursorPositions) do
                if cursorRowDef.LinkedItem ~= nil and cursorRowDef.LinkedItem.Name == name then
                    return i
                end
            end
            return 1
        end

        -- find the ActorFrame for the OptionRow that is currently hovered by the cursor
        local function getRowForCursorByCurrentPosition()
            -- correct error or just do index wrap around
            if rightPaneCursorPosition > #availableCursorPositions then rightPaneCursorPosition = 1 end
            if rightPaneCursorPosition < 1 then rightPaneCursorPosition = #availableCursorPositions end

            return optionRowContainer:GetChild("OptionRow_"..rightPaneCursorPosition)
        end

        local function getActorForCursorToHoverByCurrentConditions()
            local optionRowFrame = getRowForCursorByCurrentPosition()
            if optionRowFrame == nil then ms.ok("BAD CURSOR REPORT TO DEVELOPER") return end
            local optionRowDef = optionRowFrame.defInUse
            if optionRowDef == nil then ms.ok("BAD CURSOR ROWDEF REPORT TO DEVELOPER") return end

            -- place the cursor to highlight this item (usually ActorFrame containing BitmapText as child "Text")
            local actorToHover = nil

            -- based on the type, place the cursor in specific positions (the positions are memorized in availableCursorPositions too)
            if optionRowDef.Type == nil then
                -- optionDefs without Type should always be Category defs
                -- simply hover the title in this case
                -- pressing enter would open the category unless it is already opened
                actorToHover = optionRowFrame:GetChild("TitleText")
            else
                -- these are Option defs, not Categories
                if optionRowDef.Type == "Button" then
                    -- Button hovers the title text
                    -- pressing enter on it is a single action
                    actorToHover = optionRowFrame:GetChild("TitleText")
                elseif optionRowDef.Type == "SingleChoice" or optionRowDef.Type == "SingleChoiceModifier" then
                    -- SingleChoice[Modifier] hovers the single visible choice
                    -- pressing enter does nothing, only left and right function
                    actorToHover = optionRowFrame:safeGetChild("ChoiceFrame", "Choice_1")
                elseif optionRowDef.Type == "MultiChoice" then
                    -- MultiChoice hovers one of the visible choices
                    -- the visible choice is dependent on the value of availableCursorPositions[i].HighlightedChoice
                    -- account here, rather than in stored data, for pagination of the choices
                    -- otherwise a dead choice is picked and we look dumb
                    local cursorPosDef = availableCursorPositions[rightPaneCursorPosition]
                    local pagesize = math.min(maxChoicesVisibleMultiChoice, cursorPosDef.NumChoices)
                    if pagesize > cursorPosDef.HighlightedChoice then
                        -- if the cursor is on the first page no special math required
                        actorToHover = optionRowFrame:safeGetChild("ChoiceFrame", "Choice_"..cursorPosDef.HighlightedChoice)
                    else
                        -- if the cursor is not on the first page check to see where it lands
                        -- (i already spent 5 minutes thinking on the math for this and i got bored so what follows is the best you get)
                        local choiceIndex = cursorPosDef.HighlightedChoice % pagesize
                        if choiceIndex == 0 then choiceIndex = pagesize end -- really intuitive, right?
                        actorToHover = optionRowFrame:safeGetChild("ChoiceFrame", "Choice_"..choiceIndex)
                    end
                else
                    ms.ok("BAD CURSOR ROWDEF TYPE REPORT TO DEVELOPER")
                    return nil
                end
            end
            return actorToHover
        end

        -- place the cursor based on the current conditions of rightPaneCursorPosition and availableCursorPositions
        local function setCursorPositionByCurrentConditions()
            local optionRowFrame = getRowForCursorByCurrentPosition()
            if optionRowFrame == nil then ms.ok("BAD CURSOR REPORT TO DEVELOPER") return end
            local optionRowDef = optionRowFrame.defInUse
            if optionRowDef == nil then ms.ok("BAD CURSOR ROWDEF REPORT TO DEVELOPER") return end
            local actorToHover = getActorForCursorToHoverByCurrentConditions()

            if actorToHover == nil then
                ms.ok("BAD CURSOR PLACEMENT LOGIC OR DEF REPORT TO DEVELOPER")
                return
            end

            -- at the time of writing all actorToHover should be an ActorFrame with a child "Text"
            -- this is a TextButton
            local txt = actorToHover:GetChild("Text")
            local cursorActor = optionRowContainer:GetChild("OptionCursor")
            local xp = txt:GetTrueX() - optionRowContainer:GetTrueX()
            local beforeYPos = cursorActor:GetY()

            -- these positions should be relative to optionRowContainer so it should work out fine
            cursorActor:finishtweening()
            cursorActor:smooth(animationSeconds)
            cursorActor:xy(xp, optionRowFrame:GetY() + actorToHover:GetY() + txt:GetY())
            cursorActor:zoomto(txt:GetZoomedWidth(), txt:GetZoomedHeight() * 1.5)

            -- tell the game that we moved the option cursor to this row
            -- dont care if it didnt move
            MESSAGEMAN:Broadcast("OptionCursorUpdated", {name = optionRowDef.Name, choiceName = txt:GetText()})
        end

        -- function for pressing enter wherever the cursor is
        local function invokeCurrentCursorPosition()
            local actorToHover = getActorForCursorToHoverByCurrentConditions()
            local cursorPosDef = availableCursorPositions[rightPaneCursorPosition]

            if actorToHover == nil or cursorPosDef == nil or cursorPosDef.LinkedItem == nil then return end
            local linkdef = cursorPosDef.LinkedItem

            if linkdef.Opened == true then
                -- this means it is an opened category
                -- do nothing.
            elseif (linkdef.Opened ~= nil and linkdef.Opened == false) or linkdef.Type == "Button" then
                -- this means it is a closed category or it is a Button
                -- invoke on the text
                actorToHover:playcommand("Invoke")
            elseif linkdef.Type == "SingleChoice" or linkdef.Type == "SingleChoiceModifier" then
                -- this means it is a SingleChoice or SingleChoiceModifier
                -- do nothing.
            elseif linkdef.Type == "MultiChoice" then
                -- this means it is a MultiChoice
                -- invoke on the hovered Choice
                actorToHover:playcommand("Invoke")
            else
                -- ????
            end
        end

        -- function to set the cursor VERTICAL position
        local function setCursorPos(n)
            -- do nothing if not moving cursor
            if rightPaneCursorPosition == n then return end
            rightPaneCursorPosition = n

            local rowframe = getRowForCursorByCurrentPosition()
            updateExplainText(rowframe)

            -- update visible cursor
            setCursorPositionByCurrentConditions()
        end

        -- move the cursor position by a distance if needed
        local function changeCursorPos(n)
            local newpos = rightPaneCursorPosition + n
            -- not worth doing math to figure out if you moved 5 down from the last slide to put you on the 4th option from the top ......
            if newpos > #availableCursorPositions then newpos = 1 end
            if newpos < 1 then newpos = #availableCursorPositions end
            setCursorPos(newpos)
        end

        -- move the cursor left or right (IM OUT OF FUNCTION NAMES AND DIDNT PLAN TO MAKE THIS ONE UNTIL RIGHT NOW DONT KNOW WHAT I WAS THINKING NOT SORRY)
        local function cursorLateralMovement(n, useMultiplier)
            local currentCursorRowDef = availableCursorPositions[rightPaneCursorPosition]
            if currentCursorRowDef == nil then return end
            local currentCursorRowOptionDef = currentCursorRowDef.LinkedItem

            if currentCursorRowOptionDef == nil or currentCursorRowOptionDef.Type == nil or currentCursorRowOptionDef.Type == "Button" then
                -- Buttons and Categories dont have lateral movement actions
                return
            elseif currentCursorRowOptionDef.Type == "SingleChoice" then
                -- moving a SingleChoice left or right actually invokes it (same as clicking the arrows)
                local optionRowFrame = getRowForCursorByCurrentPosition()
                local invoker = nil
                if n > 0 then
                    -- run invoke on the right single arrow
                    invoker = optionRowFrame:GetChild("RightBigTriangleFrame")
                else
                    -- run invoke on the left single arrow
                    invoker = optionRowFrame:GetChild("LeftBigTriangleFrame")
                end
                if invoker == nil then ms.ok("TRIED TO MOVE OPTION WITHOUT ARROWS. HOW? CONTACT DEVELOPER") return end
                invoker:playcommand("Invoke")
            elseif currentCursorRowOptionDef.Type == "SingleChoiceModifier" then
                -- moving a SingleChoiceModifier left or right actually invokes it (same as clicking the arrows)
                local optionRowFrame = getRowForCursorByCurrentPosition()
                local invoker = nil
                if useMultiplier then
                    if n > 0 then
                        -- run invoke on the right double arrow
                        invoker = optionRowFrame:GetChild("RightTrianglePairFrame")
                    else
                        -- run invoke on the left double arrow
                        invoker = optionRowFrame:GetChild("LeftTrianglePairFrame")
                    end
                else
                    if n > 0 then
                        -- run invoke on the right single arrow
                        invoker = optionRowFrame:GetChild("RightBigTriangleFrame")
                    else
                        -- run invoke on the left single arrow
                        invoker = optionRowFrame:GetChild("LeftBigTriangleFrame")
                    end
                end
                if invoker == nil then ms.ok("TRIED TO MOVE OPTION WITHOUT ARROWS. HOW? CONTACT DEVELOPER") return end
                invoker:playcommand("Invoke")
            elseif currentCursorRowOptionDef.Type == "MultiChoice" then
                -- moving a MultiChoice does not invoke it, only moves the cursor. Enter would invoke on a Choice instead
                local newpos = currentCursorRowDef.HighlightedChoice + n
                -- wrap around
                if newpos > currentCursorRowDef.NumChoices then newpos = 1 end
                if newpos < 1 then newpos = currentCursorRowDef.NumChoices end
                currentCursorRowDef.HighlightedChoice = newpos

                -- heres the weird thing:
                -- if we move the cursor here so that it ends up on another page, we need to redraw the stuff
                -- so do a big brain and invoke the appropriate big triangle if that scenario arises
                local optionRowFrame = getRowForCursorByCurrentPosition()
                local validLower = 1 + (optionRowFrame.choicePage-1) * maxChoicesVisibleMultiChoice
                local validUpper = optionRowFrame.choicePage * maxChoicesVisibleMultiChoice
                if validUpper > #currentCursorRowOptionDef.Choices then validUpper = #currentCursorRowOptionDef.Choices end -- if last page missing elements
                if newpos < validLower or newpos > validUpper then
                    -- changed page, find it
                    local newpage = math.ceil(newpos / math.min(#currentCursorRowOptionDef.Choices, maxChoicesVisibleMultiChoice))
                    optionRowFrame:playcommand("SetChoicePage", {page = newpage})
                else
                    -- didnt change page probably
                end
            else
                -- impossible?
                return
            end

            -- update visible cursor
            setCursorPositionByCurrentConditions()
        end

        -- shortcuts for changeCursorPos
        local function cursorUp(n)
            changeCursorPos(-n)
        end
        local function cursorDown(n)
            changeCursorPos(n)
        end
        -- shortcuts for cursorLateralMovement
        local function cursorLeft(n, useMultiplier)
            cursorLateralMovement(-n, useMultiplier)
        end
        local function cursorRight(n, useMultiplier)
            cursorLateralMovement(n, useMultiplier)
        end

        -- function specifically for mouse hovering moving the cursor to run logic found in the above functions and more
        local function setCursorVerticalHorizontalPos(rowFrame, choice)
            if rowFrame == nil or rowFrame.defInUse == nil then return end -- apparently these can be nil? DONT KNOW HOW THATS PROBABLY REALLY BAD
            local n = getRowIndexByName(rowFrame.defInUse.Name)
            if choice == nil then choice = availableCursorPositions[n].HighlightedChoice end

            -- dont needlessly update
            if rightPaneCursorPosition == n and availableCursorPositions[n].HighlightedChoice == choice then
                return
            end

            rightPaneCursorPosition = n
            local rowframe = getRowForCursorByCurrentPosition()
            updateExplainText(rowframe)
            availableCursorPositions[n].HighlightedChoice = choice
            setCursorPositionByCurrentConditions()
        end

        -- putting these functions here to save on space below, less copy pasting, etc
        local function onHover(self)
            if self:IsInvisible() then return end
            self:diffusealpha(buttonHoverAlpha)
            local rowframe = self:GetParent()
            updateExplainText(rowframe)

            -- only the category triangle uses this which means the choice is 1
            setCursorVerticalHorizontalPos(rowframe, 1)
        end
        local function onUnHover(self)
            if self:IsInvisible() then return end
            self:diffusealpha(1)
        end
        local function onHoverParent(self)
            if self:GetParent():IsInvisible() then return end
            self:GetParent():diffusealpha(buttonHoverAlpha)
            local rowframe = self:GetParent():GetParent()
            updateExplainText(rowframe)

            -- only triangles use this which means use the choice that is already set
            setCursorVerticalHorizontalPos(rowframe, nil)
        end
        local function onUnHoverParent(self)
            if self:GetParent():IsInvisible() then return end
            self:GetParent():diffusealpha(1)
        end
        local function broadcastOptionUpdate(optionDef, choiceIndex)
            if type(choiceIndex) == "number" then
                if optionDef.Choices ~= nil and optionDef.Choices[choiceIndex] ~= nil then
                    -- a normal SingleChoice or SingleChoiceModifier
                    MESSAGEMAN:Broadcast("OptionUpdated", {name = optionDef.Name, choiceName = optionDef.Choices[choiceIndex].Name})
                else
                    -- a non-indexed option being updated directly
                    MESSAGEMAN:Broadcast("OptionUpdated", {name = optionDef.Name, choiceName = choiceIndex})
                end
            elseif type(choiceIndex) == "string" then
                -- a non-indexed option being updated directly
                MESSAGEMAN:Broadcast("OptionUpdated", {name = optionDef.Name, choiceName = choiceIndex})
            elseif type(choiceIndex) == "table" then
                -- in this case it is a MultiChoice being selected
                if choiceIndex.Name ~= nil then
                    MESSAGEMAN:Broadcast("OptionUpdated", {name = optionDef.Name, choiceName = choiceIndex.Name})
                end
            end
        end
        --

        local t = Def.ActorFrame {
            Name = "OptionRowContainer",
            InitCommand = function(self)
                self:y(actuals.TopLipHeight * 2 + actuals.OptionTextListTopGap)
                optionRowContainer = self
                self:playcommand("OpenPage", {page = 1})
            end,
            BeginCommand = function(self)
                local snm = SCREENMAN:GetTopScreen():GetName()
                local anm = self:GetName()

                -- cursor input management
                CONTEXTMAN:RegisterToContextSet(snm, "Settings", anm)
                CONTEXTMAN:ToggleContextSet(snm, "Settings", false)

                SCREENMAN:GetTopScreen():AddInputCallback(function(event)
                    -- if locked out, dont allow
                    if not CONTEXTMAN:CheckContextSet(snm, "Settings") then return end
                    if event.type ~= "InputEventType_Release" then -- allow Repeat and FirstPress
                        local gameButton = event.button
                        local key = event.DeviceInput.button
                        local up = gameButton == "Up" or gameButton == "MenuUp"
                        local down = gameButton == "Down" or gameButton == "MenuDown"
                        local right = gameButton == "MenuRight" or gameButton == "Right"
                        local left = gameButton == "MenuLeft" or gameButton == "Left"
                        local enter = gameButton == "Start"
                        local ctrl = INPUTFILTER:IsBeingPressed("left ctrl") or INPUTFILTER:IsBeingPressed("right ctrl")
                        local previewbutton = key == "DeviceButton_space"
                        local back = key == "DeviceButton_escape"

                        if up then
                            cursorUp(1)
                        elseif down then
                            cursorDown(1)
                        elseif left then
                            cursorLeft(1, ctrl)
                        elseif right then
                            cursorRight(1, ctrl)
                        elseif enter then
                            invokeCurrentCursorPosition()
                        elseif previewbutton then
                            -- allow turning off chart preview if on
                            -- allow turning it on if not in a position where doing so is impossible
                            if SCUFF.showingPreview then
                                MESSAGEMAN:Broadcast("PlayerInfoFrameTabSet", {tab = "Settings"})
                            elseif not SCUFF.showingPreview and not SCUFF.showingKeybinds and not SCUFF.showingNoteskins and not SCUFF.showingColor then
                                MESSAGEMAN:Broadcast("ShowSettingsAlt", {name = "Preview"})
                            end
                        elseif back then
                            -- shortcut to exit back to general
                            MESSAGEMAN:Broadcast("GeneralTabSet")
                        else
                            -- nothing happens
                            return
                        end
                    end
                end)

                -- initial cursor load
                generateCursorPositionMap()
                setCursorPositionByCurrentConditions()
                updateExplainText(getRowForCursorByCurrentPosition())
            end,
            OptionTabSetMessageCommand = function(self, params)
                self:playcommand("OpenPage", params)
            end,
            OpenPageCommand = function(self, params)
                local pageIndexToOpen = params.page
                selectedPageName = pageNames[pageIndexToOpen]
                selectedPageDef = optionPageCategoryLists[selectedPageName]
                self:playcommand("OpenCategory", {categoryName = selectedPageDef[1]})
            end,
            OpenCategoryCommand = function(self, params)
                local categoryNameToOpen = params.categoryName
                openedCategoryName = categoryNameToOpen
                openedCategoryDef = optionDefs[openedCategoryName]
                self:playcommand("UpdateRows")
            end,
            UpdateRowsCommand = function(self)
                openedCategoryIndex = 1
                for i = 1, #selectedPageDef do
                    if selectedPageDef[i] == openedCategoryName then
                        openedCategoryIndex = i
                    end
                end

                -- update all rows, redraw
                for i = 1, optionRowCount do
                    local row = self:GetChild("OptionRow_"..i)
                    row:playcommand("UpdateRow")
                end

                -- redrawing the rows means need to update the mapping of cursor positions
                -- this resets the cursor position also
                -- must take place after UpdateRow because cursor position is reliant on the row choice positions
                generateCursorPositionMap()
                setCursorPositionByCurrentConditions()
                updateExplainText(getRowForCursorByCurrentPosition())
            end,

            Def.Quad {
                Name = "OptionCursor",
                InitCommand = function(self)
                    self:halign(0)
                    self:zoomto(100,100)
                    self:diffusealpha(0.6)
                end,
            }
        }
        local function createOptionRow(i)
            local types = rowTypes[i] or {}
            -- SingleChoice             1 arrow, 1 choice
            -- SingleChoiceModifier     2 arrow, 1 choice
            -- MultiChoice              2 arrow, N choices
            -- Button                   no arrow, 1 choice
            -- generate elements based on how many choices and how many directional arrows are needed
            local arrowCount = (types["SingleChoiceModifier"] or types["MultiChoice"]) and 2 or (types["SingleChoice"] and 1 or 0)
            local choiceCount = rowChoiceCount[i] or 0

            local optionDef = nil
            local categoryDef = nil
            local previousDef = nil -- for tracking def changes to animate things in a slightly more intelligent way
            local previousPage = 1 -- for tracking page changes to animate things in a slightly more intelligent way
            local rowHandle = {} -- for accessing the row frame from other points of reference (within this function) instantly
            -- MultiChoice pagination
            rowHandle.choicePage = 1
            rowHandle.maxChoicePage = 1

            -- convenience to hit the AssociatedOptions optionDef stuff (primarily for speed mods but can be used for whatever)
            -- hyper inefficient function (dont care) (yes i do)
            local function updateAssociatedElements(thisDef)
                if thisDef ~= nil and thisDef.AssociatedOptions ~= nil then
                    -- for each option
                    for _, optionName in ipairs(thisDef.AssociatedOptions) do
                        -- for each possible row to match
                        for rowIndex = 1, optionRowCount do
                            local row = rowHandle:GetParent():GetChild("OptionRow_"..rowIndex)
                            if row ~= nil then
                                if row.defInUse ~= nil and row.defInUse.Name == optionName then
                                    row:playcommand("DrawRow")

                                    -- update cursor sizing and stuff
                                    -- (i know without testing it that this will break if the associated element is a MultiChoice. please dont do that thanks)
                                    local cursorRow = getRowForCursorByCurrentPosition()
                                    if cursorRow ~= nil and cursorRow:GetName() == row:GetName() then
                                        setCursorPositionByCurrentConditions()
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- convenience
            local function redrawChoiceRelatedElements()
                local rightpair = rowHandle:GetChild("RightTrianglePairFrame")
                local right = rowHandle:GetChild("RightBigTriangleFrame")
                local choices = rowHandle:GetChild("ChoiceFrame")
                if choices ~= nil then
                    choices:finishtweening()
                    choices:diffusealpha(0)
                    -- only animate the redraw for non single choices
                    -- the choice item shouldnt move so this isnt so weird
                    if optionDef ~= nil and optionDef.Type ~= "SingleChoice" and optionDef.Type ~= "SingleChoiceModifier" then
                        choices:smooth(optionRowQuickAnimationSeconds)
                    end
                    choices:diffusealpha(1)
                    choices:playcommand("DrawElement")
                end
                if right ~= nil then
                    right:playcommand("DrawElement")
                end
                if rightpair ~= nil then
                    rightpair:playcommand("DrawElement")
                end
                updateAssociatedElements(optionDef)

                -- if the cursor is on this row, update it because the width may have changed or something
                -- and for a multichoice if the cursor was in some position and we changed page, move it to a sane position
                local cursorRow = getRowForCursorByCurrentPosition()
                if cursorRow == nil then return end
                if cursorRow:GetName() == rowHandle:GetName() then
                    -- at this point we can assume rightPaneCursorPosition is the current cursor position
                    if optionDef.Type == "MultiChoice" then
                        local choicesPerPage = math.min(choiceCount, maxChoicesVisibleMultiChoice)
                        local cursorChoicePos = availableCursorPositions[rightPaneCursorPosition].HighlightedChoice
                        -- only have to take action if there is more than 1 page implied
                        if choicesPerPage < #optionDef.Choices then
                            local validLower = 1 + (rowHandle.choicePage-1) * maxChoicesVisibleMultiChoice
                            local validUpper = rowHandle.choicePage * maxChoicesVisibleMultiChoice
                            if validUpper > #optionDef.Choices then validUpper = #optionDef.Choices end -- if last page missing elements
                            if cursorChoicePos < validLower then
                                -- highlight is too high, move to the last one
                                availableCursorPositions[rightPaneCursorPosition].HighlightedChoice = validLower
                            elseif cursorChoicePos > validUpper then
                                -- highlight is too low, move to first one
                                availableCursorPositions[rightPaneCursorPosition].HighlightedChoice = validUpper
                            else
                                -- probably dont have to do anything? its in valid range...
                            end
                        end
                    end

                    setCursorPositionByCurrentConditions()
                end
            end

            -- index of the choice for this option, if no choices then this is useless
            -- this can also be a table of indices for MultiChoice
            -- this can also just be a random number or text for some certain implementations of optionDefs as long as they conform
            local currentChoiceSelection = 1
            -- move SingleChoice selection index (assuming a list of choices is present -- if not, another methodology is used)
            local function moveChoiceSelection(n)
                if optionDef == nil then return end

                -- make selection loop both directions
                local nn = currentChoiceSelection + n
                if nn <= 0 then
                    nn = n > 0 and 1 or #optionDef.Choices
                elseif nn > #optionDef.Choices then
                    nn = 1
                end
                currentChoiceSelection = nn
                if optionDef.Choices ~= nil and optionDef.Choices[currentChoiceSelection] ~= nil then
                    optionDef.Choices[currentChoiceSelection].ChosenFunction()
                    broadcastOptionUpdate(optionDef, currentChoiceSelection)
                end
                if rowHandle ~= nil then
                    redrawChoiceRelatedElements()
                end
            end

            -- paginate choices according to maxChoicesVisibleMultiChoice
            local function moveChoicePage(n)
                if rowHandle.maxChoicePage <= 1 then
                    return
                end

                -- math to make pages loop both directions
                local nn = (rowHandle.choicePage + n) % (rowHandle.maxChoicePage + 1)
                if nn == 0 then
                    nn = n > 0 and 1 or rowHandle.maxChoicePage
                end
                rowHandle.choicePage = nn
                if rowHandle ~= nil then
                    redrawChoiceRelatedElements()
                end
            end

            -- getter for all relevant children of the row
            -- expects that self is OptionRow_i
            local function getRowElements(self)
                -- directional arrows
                local leftpair = self:GetChild("LeftTrianglePairFrame")
                local left = self:GetChild("LeftBigTriangleFrame")
                local rightpair = self:GetChild("RightTrianglePairFrame")
                local right = self:GetChild("RightBigTriangleFrame")
                -- choices
                local choices = self:GetChild("ChoiceFrame")
                local title = self:GetChild("TitleText")
                local categorytriangle = self:GetChild("CategoryTriangle")
                return leftpair, left, rightpair, right, choices, title, categorytriangle
            end

            local t = Def.ActorFrame {
                Name = "OptionRow_"..i,
                InitCommand = function(self)
                    self:x(actuals.EdgePadding)
                    -- why the -1.5? to squish the options just a tiny bit and allow room for chart preview toggle
                    self:y((actuals.OptionAllottedHeight / #rowChoiceCount-1.5) * (i-1) + (actuals.OptionAllottedHeight / #rowChoiceCount / 2))
                    rowHandle = self
                end,
                SetChoicePageCommand = function(self, params)
                    local newpage = clamp(params.page, 1, rowHandle.maxChoicePage)
                    rowHandle.choicePage = newpage
                    redrawChoiceRelatedElements()
                end,
                UpdateRowCommand = function(self)
                    -- update row information, draw (this will reset the state of the row according to "global" conditions)
                    local firstOptionRowIndex = openedCategoryIndex + 1
                    local lastOptionRowIndex = firstOptionRowIndex + #openedCategoryDef - 1

                    -- track previous definition
                    previousDef = nil
                    if optionDef ~= nil then previousDef = optionDef end
                    if categoryDef ~= nil then previousDef = categoryDef end
                    previousPage = rowHandle.choicePage

                    -- reset state
                    optionDef = nil
                    categoryDef = nil
                    self.defInUse = nil
                    rowHandle.choicePage = 1
                    rowHandle.maxChoicePage = 1

                    if i >= firstOptionRowIndex and i <= lastOptionRowIndex then
                        -- this is an option and has an optionDef
                        local optionDefIndex = i - firstOptionRowIndex + 1
                        optionDef = openedCategoryDef[optionDefIndex]
                        if optionDef.Choices ~= nil then
                            rowHandle.maxChoicePage = math.ceil(#optionDef.Choices / maxChoicesVisibleMultiChoice)
                        end
                        self.defInUse = optionDef
                    else
                        -- this is a category or nothing at all
                        -- maybe generate a "categoryDef" which is really just a summary of what to display instead
                        local lastValidPossibleIndex = lastOptionRowIndex + (#selectedPageDef - openedCategoryIndex)
                        if i > lastValidPossibleIndex then
                            -- nothing.
                        else
                            -- this has a categoryDef
                            local adjustedCategoryIndex = i
                            -- subtract the huge list of optionDefs to grab the position of the category in the original list
                            if i > lastOptionRowIndex then
                                adjustedCategoryIndex = (i) - #openedCategoryDef
                            end
                            categoryDef = {
                                Opened = (openedCategoryIndex == i) and true or false,
                                Name = selectedPageDef[adjustedCategoryIndex]
                            }
                            self.defInUse = categoryDef
                        end
                    end

                    self:playcommand("DrawRow")
                end,
                DrawRowCommand = function(self)
                    -- redraw row
                    local leftPairArrows, leftArrow, rightPairArrows, rightArrow, choiceFrame, titleText, categoryTriangle = getRowElements(self)

                    if optionDef ~= nil and optionDef.ChoiceIndexGetter ~= nil then
                        currentChoiceSelection = optionDef.ChoiceIndexGetter()
                    end

                    -- blink the row if it updated
                    self:finishtweening()
                    self:diffusealpha(0)
                    -- if def was just defined, or def just changed, or choice page just changed -- show animation
                    if previousDef == nil or (optionDef ~= nil and optionDef.Name ~= previousDef.Name) or (categoryDef ~= nil and categoryDef.Name ~= previousDef.Name) or previousPage ~= rowHandle.choicePage then
                        self:smooth(optionRowAnimationSeconds)
                    end
                    self:diffusealpha(1)

                    -- this is done so that the redraw can be done in a particular order, left to right
                    -- also, not all of these actors are guaranteed to exist
                    -- and each actor may or may not rely on the previous one to be positioned in order to correctly draw
                    -- the strict ordering is required as a result
                    if categoryTriangle ~= nil then
                        categoryTriangle:playcommand("DrawElement")
                    end

                    if titleText ~= nil then
                        titleText:playcommand("DrawElement")
                    end

                    if leftPairArrows ~= nil then
                        leftPairArrows:playcommand("DrawElement")
                    end

                    if leftArrow ~= nil then
                        leftArrow:playcommand("DrawElement")
                    end

                    if choiceFrame ~= nil then
                        choiceFrame:playcommand("DrawElement")
                    end

                    if rightArrow ~= nil then
                        rightArrow:playcommand("DrawElement")
                    end

                    if rightPairArrows ~= nil then
                        rightPairArrows:playcommand("DrawElement")
                    end
                end,

                -- category title and option name
                UIElements.TextButton(1, 1, "Common Normal") .. {
                    Name = "TitleText",
                    InitCommand = function(self)
                        local txt = self:GetChild("Text")
                        local bg = self:GetChild("BG")
                        txt:halign(0)
                        txt:zoom(optionTitleTextSize)
                        txt:settext(" ")

                        bg:halign(0)
                        -- fudge movement due to font misalign
                        bg:y(1)
                        bg:zoomto(0, txt:GetZoomedHeight() * textButtonHeightFudgeScalarMultiplier)
                    end,
                    DrawElementCommand = function(self)
                        local txt = self:GetChild("Text")
                        local bg = self:GetChild("BG")

                        if optionDef ~= nil then
                            self:x(0)
                            txt:settext(optionDef.Name)
                            txt:maxwidth(actuals.OptionTextWidth / optionTitleTextSize - textZoomFudge)
                        elseif categoryDef ~= nil then
                            local newx = actuals.OptionBigTriangleWidth + actuals.OptionTextBuffer / 2
                            self:x(newx)
                            txt:settext(categoryDef.Name)
                            txt:maxwidth((actuals.OptionTextWidth - newx) / optionTitleTextSize - textZoomFudge)
                        else
                            txt:settext("")
                        end
                        bg:zoomx(txt:GetZoomedWidth())
                    end,
                    InvokeCommand = function(self)
                        -- behavior for interacting with the Option Row Title Text
                        if categoryDef ~= nil then
                            rowHandle:GetParent():playcommand("OpenCategory", {categoryName = categoryDef.Name})
                        elseif optionDef ~= nil then
                            if optionDef.Type == "Button" then
                                -- button
                                if optionDef.Choices and #optionDef.Choices >= 1 then
                                    optionDef.Choices[1].ChosenFunction()
                                    broadcastOptionUpdate(optionDef, 1)
                                end
                            else
                                -- ?
                            end
                        end
                    end,
                    RolloverUpdateCommand = function(self, params)
                        if self:IsInvisible() then return end
                        if params.update == "in" then
                            self:diffusealpha(buttonHoverAlpha)
                            updateExplainText(rowHandle)
                            setCursorVerticalHorizontalPos(rowHandle, nil)
                        else
                            self:diffusealpha(1)
                        end
                    end,
                    ClickCommand = function(self, params)
                        if self:IsInvisible() then return end
                        if params.update == "OnMouseDown" then
                            if optionDef ~= nil or categoryDef ~= nil then
                                self:playcommand("Invoke")
                            end
                        end
                    end,
                },
                UIElements.QuadButton(0, 1) .. {
                    Name = "MouseWheelRegion",
                    InitCommand = function(self)
                        self:halign(0)
                        self:diffusealpha(0)
                        self:zoomto(500, actuals.OptionAllottedHeight / optionRowCount)
                    end,
                    MouseScrollMessageCommand = function(self, params)
                        if isOver(self) and focused and (optionDef ~= nil or categoryDef ~= nil) then
                            if optionDef ~= nil then
                                if optionDef.Type == "SingleChoice" or optionDef.Type == "SingleChoiceModifier" or optionDef.Type == "MultiChoice" then
                                    if params.direction == "Up" then
                                        rowHandle:GetChild("RightBigTriangleFrame"):playcommand("Invoke")
                                    else
                                        rowHandle:GetChild("LeftBigTriangleFrame"):playcommand("Invoke")
                                    end
                                end
                            end
                        end
                    end,
                    MouseOverCommand = function(self)
                        if not focused or optionDef == nil then return end
                        updateExplainText(rowHandle)
                        -- uncomment to update cursor position when hovering the invisible area
                        -- seems like an annoying and buggy looking behavior
                        -- although it is correct, it is just weird
                        --setCursorVerticalHorizontalPos(rowHandle, nil)
                    end,
                }
            }

            -- category arrow
            if types["Category"] then
                t[#t+1] = UIElements.SpriteButton(1, 1, THEME:GetPathG("", "_triangle")) .. {
                    Name = "CategoryTriangle",
                    InitCommand = function(self)
                        self:x(actuals.OptionBigTriangleWidth/2)
                        self:zoomto(actuals.OptionBigTriangleWidth, actuals.OptionBigTriangleHeight)
                    end,
                    DrawElementCommand = function(self)
                        if categoryDef ~= nil then
                            if categoryDef.Opened then
                                self:rotationz(180)
                            else
                                self:rotationz(90)
                            end
                            self:diffusealpha(1)
                            self:z(1)
                        else
                            self:diffusealpha(0)
                            self:z(-1)
                        end
                    end,
                    InvokeCommand = function(self)
                        -- behavior for interacting with the Option Row Title Text
                        if categoryDef ~= nil and not categoryDef.Opened then
                            rowHandle:GetParent():playcommand("OpenCategory", {categoryName = categoryDef.Name})
                        end
                    end,
                    MouseOverCommand = onHover,
                    MouseOutCommand = onUnHover,
                    MouseDownCommand = function(self, params)
                        if self:IsInvisible() then return end
                        self:playcommand("Invoke")
                    end,
                }
            end

            -- smaller double arrow, left/right
            if arrowCount == 2 then
                -- copy paste territory
                t[#t+1] = Def.ActorFrame {
                    Name = "LeftTrianglePairFrame",
                    DrawElementCommand = function(self)
                        if optionDef ~= nil and optionDef.Type == "SingleChoiceModifier" then
                            -- only visible in this case
                            -- offset by half the triangle size due to center aligning
                            self:x(actuals.OptionTextWidth + actuals.OptionTextBuffer + actuals.OptionSmallTriangleHeight/2)
                            self:diffusealpha(1)
                            self:z(1)
                        else
                            -- always invisible
                            self:diffusealpha(0)
                            self:z(-1)
                        end
                    end,

                    Def.Sprite {
                        Name = "LeftTriangle", -- outermost triangle
                        Texture = THEME:GetPathG("", "_triangle"),
                        InitCommand = function(self)
                            self:rotationz(-90)
                            self:zoomto(actuals.OptionSmallTriangleWidth, actuals.OptionSmallTriangleHeight)
                        end,
                    },
                    Def.Sprite {
                        Name = "RightTriangle", -- innermost triangle
                        Texture = THEME:GetPathG("", "_triangle"),
                        InitCommand = function(self)
                            self:rotationz(-90)
                            self:zoomto(actuals.OptionSmallTriangleWidth, actuals.OptionSmallTriangleHeight)
                            -- subtract by 25% triangle height because image is 25% invisible
                            self:x(actuals.OptionSmallTriangleHeight + actuals.OptionSmallTriangleGap - actuals.OptionSmallTriangleHeight/4)
                        end,
                    },
                    UIElements.QuadButton(1, 1) .. {
                        Name = "LeftTrianglePairButton",
                        InitCommand = function(self)
                            self:diffusealpha(0)
                            self:x(actuals.OptionSmallTriangleHeight/2)
                            self:zoomto(actuals.OptionSmallTriangleHeight * 2 + actuals.OptionSmallTriangleGap, actuals.OptionBigTriangleWidth)
                        end,
                        InvokeCommand = function(self)
                            if optionDef ~= nil then
                                if optionDef.Type == "SingleChoiceModifier" then
                                    -- SingleChoiceModifier selection mover
                                    if optionDef.Directions ~= nil and optionDef.Directions.Toggle ~= nil then
                                        -- Toggle SingleChoice (multiplier)
                                        optionDef.Directions.Toggle(true)
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    elseif optionDef.Directions ~= nil and optionDef.Directions.Left ~= nil then
                                        -- Move Left (multiplier)
                                        optionDef.Directions.Left(true)
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    end

                                    if optionDef.Choices ~= nil then
                                        moveChoiceSelection(-2)
                                    else
                                        ms.ok("ERROR REPORT TO DEVELOPER")
                                    end
                                end
                            end
                        end,
                        MouseDownCommand = function(self, params)
                            if self:GetParent():IsInvisible() then return end
                            if optionDef ~= nil then
                                self:playcommand("Invoke")
                            end
                        end,
                        MouseOverCommand = onHoverParent,
                        MouseOutCommand = onUnHoverParent,
                    }
                }
                t[#t+1] = Def.ActorFrame {
                    Name = "RightTrianglePairFrame",
                    DrawElementCommand = function(self)
                        if optionDef ~= nil and optionDef.Type == "SingleChoiceModifier" then
                            -- only visible in this case
                            local optionRowChoiceFrame = rowHandle:GetChild("ChoiceFrame")
                            if choiceCount < 1 then self:diffusealpha(0):z(-1) return end
                            -- offset by the position of the choice text and the size of the big triangles
                            -- the logic/ordering of the positioning is visible in the math
                            -- choice xpos + width + buffer + big triangle size + buffer
                            -- we pick choice 1 because only SingleChoice is allowed to show these arrows
                            -- offset by half triangle size due to center aligning (edit: nvm?)
                            -- okay actually im gonna be honest I DONT KNOW WHAT IS HAPPENING HERE
                            -- but it completely mirrors the behavior of the other side so it works
                            -- help
                            self:x(optionRowChoiceFrame:GetX() + optionRowChoiceFrame:GetChild("Choice_1"):GetChild("Text"):GetZoomedWidth() + actuals.OptionChoiceDirectionGap + actuals.OptionBigTriangleHeight*0.9 + actuals.OptionChoiceDirectionGap)
                            self:diffusealpha(1)
                            self:z(1)
                        else
                            -- always invisible
                            self:diffusealpha(0)
                            self:z(-1)
                        end
                    end,

                    Def.Sprite {
                        Name = "RightTriangle", -- outermost triangle
                        Texture = THEME:GetPathG("", "_triangle"),
                        InitCommand = function(self)
                            self:rotationz(90)
                            self:zoomto(actuals.OptionSmallTriangleWidth, actuals.OptionSmallTriangleHeight)
                            -- subtract by 25% triangle height because image is 25% invisible
                            self:x(actuals.OptionSmallTriangleHeight + actuals.OptionSmallTriangleGap - actuals.OptionSmallTriangleHeight/4)
                        end,
                    },
                    Def.Sprite {
                        Name = "LeftTriangle", -- innermost triangle
                        Texture = THEME:GetPathG("", "_triangle"),
                        InitCommand = function(self)
                            self:rotationz(90)
                            self:zoomto(actuals.OptionSmallTriangleWidth, actuals.OptionSmallTriangleHeight)
                            self:x(0)
                        end,
                    },
                    UIElements.QuadButton(1, 1) .. {
                        Name = "RightTrianglePairButton",
                        InitCommand = function(self)
                            self:diffusealpha(0)
                            self:x(actuals.OptionSmallTriangleHeight/2)
                            self:zoomto(actuals.OptionSmallTriangleHeight * 2 + actuals.OptionSmallTriangleGap, actuals.OptionBigTriangleWidth)
                        end,
                        InvokeCommand = function(self)
                            if optionDef ~= nil then
                                if optionDef.Type == "SingleChoiceModifier" then
                                    -- SingleChoiceModifier selection mover
                                    if optionDef.Directions ~= nil and optionDef.Directions.Toggle ~= nil then
                                        -- Toggle SingleChoice (multiplier)
                                        optionDef.Directions.Toggle(true)
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    elseif optionDef.Directions ~= nil and optionDef.Directions.Right ~= nil then
                                        -- Move Right (multiplier)
                                        optionDef.Directions.Right(true)
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    end

                                    if optionDef.Choices ~= nil then
                                        moveChoiceSelection(2)
                                    else
                                        ms.ok("ERROR REPORT TO DEVELOPER")
                                    end
                                end
                            end
                        end,
                        MouseDownCommand = function(self, params)
                            if self:GetParent():IsInvisible() then return end
                            if optionDef ~= nil then
                                self:playcommand("Invoke")
                            end
                        end,
                        MouseOverCommand = onHoverParent,
                        MouseOutCommand = onUnHoverParent,
                    }
                }
            end

            -- single large arrow, left/right
            if arrowCount >= 1 then
                t[#t+1] = Def.ActorFrame {
                    Name = "LeftBigTriangleFrame",
                    DrawElementCommand = function(self)
                        if optionDef ~= nil and (optionDef.Type == "SingleChoice" or optionDef.Type == "SingleChoiceModifier" or (optionDef.Type == "MultiChoice" and rowHandle.maxChoicePage > 1)) then
                            -- visible for SingleChoice(Modifier) and MultiChoice
                            -- only visible on MultiChoice if we need to paginate the choices
                            -- offset by half height due to center aligning
                            local minXPos = actuals.OptionTextWidth + actuals.OptionTextBuffer + actuals.OptionBigTriangleHeight/2
                            if optionDef.Type == "SingleChoice" or optionDef.Type == "MultiChoice" then
                                -- SingleChoice/MultiChoice is on the very left
                                self:x(minXPos)
                            else
                                -- SingleChoiceModifier is to the right of the LeftTrianglePairFrame
                                -- subtract by 25% triangle height twice because 25% of the image is invisible
                                self:x(minXPos + actuals.OptionSmallTriangleHeight * 2 - actuals.OptionSmallTriangleHeight/2 + actuals.OptionSmallTriangleGap + actuals.OptionChoiceDirectionGap)
                            end
                            self:diffusealpha(1)
                            self:z(1)
                        else
                            -- always invisible
                            self:diffusealpha(0)
                            self:z(-1)
                        end
                    end,

                    Def.Sprite {
                        Name = "Triangle",
                        Texture = THEME:GetPathG("", "_triangle"),
                        InitCommand = function(self)
                            self:rotationz(-90)
                            self:zoomto(actuals.OptionBigTriangleWidth, actuals.OptionBigTriangleHeight)
                        end,
                    },
                    UIElements.QuadButton(1, 1) .. {
                        Name = "TriangleButton",
                        InitCommand = function(self)
                            self:diffusealpha(0)
                            self:zoomto(actuals.OptionBigTriangleWidth, actuals.OptionBigTriangleHeight)
                        end,
                        InvokeCommand = function(self)
                            if optionDef ~= nil then
                                if optionDef.Type == "MultiChoice" then
                                    -- MultiChoice pagination
                                    moveChoicePage(-1)
                                elseif optionDef.Type == "SingleChoice" or optionDef.Type == "SingleChoiceModifier" then
                                    -- SingleChoice selection mover
                                    if optionDef.Directions ~= nil and optionDef.Directions.Toggle ~= nil then
                                        -- Toggle SingleChoices
                                        optionDef.Directions.Toggle()
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    elseif optionDef.Directions ~= nil and optionDef.Directions.Left ~= nil then
                                        -- Move Left (no multiplier)
                                        optionDef.Directions.Left(false)
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    end

                                    if optionDef.Choices ~= nil then
                                        moveChoiceSelection(-1)
                                    else
                                        ms.ok("ERROR REPORT TO DEVELOPER")
                                    end
                                end
                            end
                        end,
                        MouseDownCommand = function(self, params)
                            if self:GetParent():IsInvisible() then return end
                            if optionDef ~= nil then
                                self:playcommand("Invoke")
                            end
                        end,
                        MouseOverCommand = onHoverParent,
                        MouseOutCommand = onUnHoverParent,
                    }
                }
                t[#t+1] = Def.ActorFrame {
                    Name = "RightBigTriangleFrame",
                    DrawElementCommand = function(self)
                        if optionDef ~= nil and (optionDef.Type == "SingleChoice" or optionDef.Type == "SingleChoiceModifier" or (optionDef.Type == "MultiChoice" and rowHandle.maxChoicePage > 1)) then
                            -- visible for SingleChoice(Modifier) and MultiChoice
                            local optionRowChoiceFrame = rowHandle:GetChild("ChoiceFrame")
                            if choiceCount < 1 then self:diffusealpha(0):z(-1) return end
                            -- offset by the position of the choice text and appropriate buffer
                            -- the logic/ordering of the positioning is visible in the math
                            -- choice xpos + width + buffer
                            -- we pick choice 1 because only SingleChoice is allowed to show these arrows
                            -- subtract by 25% triangle height because 25% of the image is invisible
                            -- offset by half height due to center aligning
                            if optionDef.Type == "MultiChoice" then
                                -- offset to the right of the last visible choice (up to the 4th one)
                                local lastChoiceIndex = math.min(maxChoicesVisibleMultiChoice, #optionDef.Choices) -- last choice if not on first or last page
                                if rowHandle.choicePage > 1 and rowHandle.choicePage >= rowHandle.maxChoicePage then
                                    -- last if on last (first) page
                                    lastChoiceIndex = #optionDef.Choices % maxChoicesVisibleMultiChoice
                                    if lastChoiceIndex == 0 then lastChoiceIndex = maxChoicesVisibleMultiChoice end
                                end
                                local lastChoice = optionRowChoiceFrame:GetChild("Choice_"..lastChoiceIndex)
                                local finalX = optionRowChoiceFrame:GetX() + lastChoice:GetX() + lastChoice:GetChild("Text"):GetZoomedWidth() + actuals.OptionChoiceDirectionGap + actuals.OptionBigTriangleHeight/4
                                self:x(finalX)
                            else
                                self:x(optionRowChoiceFrame:GetX() + optionRowChoiceFrame:GetChild("Choice_1"):GetChild("Text"):GetZoomedWidth() + actuals.OptionChoiceDirectionGap + actuals.OptionBigTriangleHeight/4)
                            end
                            self:diffusealpha(1)
                            self:z(1)
                        else
                            -- always invisible
                            self:diffusealpha(0)
                            self:z(-1)
                        end
                    end,

                    Def.Sprite {
                        Name = "Triangle",
                        Texture = THEME:GetPathG("", "_triangle"),
                        InitCommand = function(self)
                            self:rotationz(90)
                            self:zoomto(actuals.OptionBigTriangleWidth, actuals.OptionBigTriangleHeight)
                        end,
                    },
                    UIElements.QuadButton(1, 1) .. {
                        Name = "TriangleButton",
                        InitCommand = function(self)
                            self:diffusealpha(0)
                            self:zoomto(actuals.OptionBigTriangleWidth, actuals.OptionBigTriangleHeight)
                        end,
                        InvokeCommand = function(self)
                            if optionDef ~= nil then
                                if optionDef.Type == "MultiChoice" then
                                    -- MultiChoice pagination
                                    moveChoicePage(1)
                                elseif optionDef.Type == "SingleChoice" or optionDef.Type == "SingleChoiceModifier" then
                                    -- SingleChoice selection mover
                                    if optionDef.Directions ~= nil and optionDef.Directions.Toggle ~= nil then
                                        -- Toggle SingleChoices
                                        optionDef.Directions.Toggle()
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    elseif optionDef.Directions ~= nil and optionDef.Directions.Right ~= nil then
                                        -- Move Right (no multiplier)
                                        optionDef.Directions.Right(false)
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                        redrawChoiceRelatedElements()
                                        return
                                    end

                                    if optionDef.Choices ~= nil then
                                        moveChoiceSelection(1)
                                    else
                                        ms.ok("ERROR REPORT TO DEVELOPER")
                                    end
                                end
                            end
                        end,
                        MouseDownCommand = function(self, params)
                            if self:GetParent():IsInvisible() then return end
                            if optionDef ~= nil then
                                self:playcommand("Invoke")
                            end
                        end,
                        MouseOverCommand = onHoverParent,
                        MouseOutCommand = onUnHoverParent,
                    }
                }
            end

            -- choice text
            local function createOptionRowChoices()
                local t = Def.ActorFrame {
                    Name = "ChoiceFrame",
                    DrawElementCommand = function(self)
                        if optionDef ~= nil then
                            self:diffusealpha(1)

                            local minXPos = actuals.OptionTextWidth + actuals.OptionTextBuffer
                            local finalXPos = minXPos
                            -- triangle width buffer thing .... the distance from minX to ... the choices ... across the one big triangle ...
                            local triangleWidthBufferThing = actuals.OptionBigTriangleHeight + actuals.OptionChoiceDirectionGap - actuals.OptionBigTriangleHeight/4
                            if optionDef.Type == "SingleChoice" or (optionDef.Type == "MultiChoice" and rowHandle.maxChoicePage > 1) then
                                -- leftmost xpos + big triangle + gap
                                -- subtract by 25% of the big triangle size because the image is actually 25% invisible
                                finalXPos = finalXPos + triangleWidthBufferThing
                            elseif optionDef.Type == "SingleChoiceModifier" then
                                -- leftmost xpos + big triangle + gap + 2 small triangles + gap between 2 small triangles + last gap
                                -- subtract by 25% of big triangle and 25% of small triangle twice because the image is 25% invisible
                                finalXPos = finalXPos + triangleWidthBufferThing + actuals.OptionSmallTriangleHeight * 2 - actuals.OptionSmallTriangleHeight/2 + actuals.OptionSmallTriangleGap + actuals.OptionChoiceDirectionGap
                            end
                            self:x(finalXPos)

                            -- to force the choices to update left to right
                            -- update the text of all of them first to see what the width would be
                            local lastFilledChoiceIndex = 1
                            for i = 1, math.min(choiceCount, maxChoicesVisibleMultiChoice) do
                                local child = self:GetChild("Choice_"..i)
                                child:playcommand("SetChoiceText")
                                if #child:GetChild("Text"):GetText() > 0 then
                                    lastFilledChoiceIndex = i
                                end
                            end

                            -- so basically this bad line of math evenly splits the given area including the buffer zones in between
                            -- it also takes into account whether or not we have the triangles on the edges (so if missing, take up more room to equal in width)
                            -- (it doesnt produce a great result and all this garbage is for nothing if you think about it)
                            -- (leaving it here anyways in case this method of setting text and then drawing can be used)
                            local allowedWidth = (actuals.OptionChoiceAllottedWidth - (lastFilledChoiceIndex-1) * actuals.OptionTextBuffer) / lastFilledChoiceIndex + (rowHandle.maxChoicePage <= 1 and triangleWidthBufferThing or 0)
                            for i = 1, math.min(choiceCount, maxChoicesVisibleMultiChoice) do
                                local child = self:GetChild("Choice_"..i)
                                child:GetChild("Text"):maxwidth(allowedWidth / choiceTextSize)
                                child:playcommand("DrawChoice")
                            end


                        else
                            -- missing optionDef means no choices possible
                            self:diffusealpha(0)
                        end
                    end,
                }
                for n = 1, math.min(choiceCount, maxChoicesVisibleMultiChoice) do
                    -- each of these tt's are ActorFrames named Choice_n
                    -- they have 3 children, Text, BG, Underline
                    local tt = UIElements.TextButton(1, 1, "Common Normal") .. {
                        Name = "Choice_"..n,
                        InitCommand = function(self)
                            local txt = self:GetChild("Text")
                            local bg = self:GetChild("BG")
                            txt:halign(0)
                            txt:zoom(optionChoiceTextSize)
                            txt:settext(" ")

                            bg:halign(0)
                            -- fudge movement due to font misalign
                            bg:y(1)
                            bg:zoomto(0, txt:GetZoomedHeight() * textButtonHeightFudgeScalarMultiplier)
                        end,
                        SetChoiceTextCommand = function(self)
                            -- THIS DOES NOT DO BUTTON WORK
                            -- RUN COMMANDS IN THIS ORDER: SetChoiceText -> ??? -> DrawChoice
                            -- That will properly update the text and choices and everything "nicely"
                            local txt = self:GetChild("Text")
                            txt:maxwidth(actuals.OptionChoiceAllottedWidth / choiceTextSize)
                            if optionDef ~= nil then
                                if optionDef.Type == "MultiChoice" then
                                    local choiceIndex = n + (rowHandle.choicePage-1) * maxChoicesVisibleMultiChoice
                                    local choice = optionDef.Choices[choiceIndex]
                                    if choice ~= nil then
                                        txt:settext(choice.Name)
                                    else
                                        txt:settext("")
                                    end
                                elseif optionDef.Type == "Button" then
                                    txt:settext("")
                                else
                                    if n == 1 then
                                        -- several cases involving the ChoiceIndexGetter for single choices...
                                        if optionDef.ChoiceIndexGetter ~= nil and optionDef.Choices == nil then
                                            -- getter with no choices means the getter supplies the visible information
                                            txt:settext(currentChoiceSelection)
                                        elseif optionDef.Choices ~= nil then
                                            -- choices present means the getter supplies the choice index that contains the information
                                            txt:settext(optionDef.Choices[currentChoiceSelection].Name)
                                        else
                                            txt:settext("INVALID CONTACT DEVELOPER")
                                        end
                                    else
                                        txt:settext("")
                                    end
                                end
                            else
                                txt:settext("")
                            end
                        end,
                        DrawChoiceCommand = function(self)
                            if optionDef ~= nil then
                                if optionDef.Type == "MultiChoice" then
                                    -- for Multi choice mode
                                    local choiceIndex = n + (rowHandle.choicePage-1) * maxChoicesVisibleMultiChoice
                                    local choice = optionDef.Choices[choiceIndex]
                                    if choice ~= nil then
                                        local txt = self:GetChild("Text")
                                        local bg = self:GetChild("BG")

                                        -- get the x position of this element using the position of the element to the left
                                        -- this requires all elements be updated in order, left to right
                                        local xPos = 0
                                        if n > 1 then
                                            local choiceJustToTheLeftOfThisOne = self:GetParent():GetChild("Choice_"..(n-1))
                                            xPos = choiceJustToTheLeftOfThisOne:GetX() + choiceJustToTheLeftOfThisOne:GetChild("Text"):GetZoomedWidth() + actuals.OptionTextBuffer
                                        end
                                        self:x(xPos)
                                        bg:zoomx(txt:GetZoomedWidth())
                                        bg:diffusealpha(0.1)

                                        self:diffusealpha(1)
                                        self:z(1)
                                    else
                                        -- choice does not exist for this option but does for another
                                        self:x(0)
                                        self:diffusealpha(0)
                                        self:z(-1)
                                    end
                                elseif optionDef.Type == "Button" then
                                    -- Button is just one choice but lets use the option title as the choice (hide all choices)
                                    self:x(0)
                                    self:diffusealpha(0)
                                    self:z(-1)
                                else
                                    -- for Single choice mode only show first choice
                                    if n == 1 then
                                        local txt = self:GetChild("Text")
                                        local bg = self:GetChild("BG")

                                        bg:zoomx(txt:GetZoomedWidth())
                                        bg:diffusealpha(0)
                                        self:x(0) -- for consistency but makes no difference
                                        self:diffusealpha(1)
                                        self:z(1)
                                    else
                                        self:x(0)
                                        self:diffusealpha(0)
                                        self:z(-1)
                                    end
                                end
                            end
                        end,
                        InvokeCommand = function(self, params)
                            if optionDef ~= nil then
                                if optionDef.Type == "SingleChoice" or optionDef.Type == "SingleChoiceModifier" then
                                    -- SingleChoice left clicks will move the option forward
                                    -- SingleChoice right clicks will move the option backward
                                    if params and params.direction then
                                        local fwd = params.direction == "forward"
                                        local bwd = params.direction == "backward"

                                        -- SingleChoice selection mover
                                        if optionDef.Directions ~= nil and optionDef.Directions.Toggle ~= nil then
                                            -- Toggle SingleChoices
                                            optionDef.Directions.Toggle()
                                            if optionDef.ChoiceIndexGetter ~= nil then
                                                currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                            end
                                            broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                            redrawChoiceRelatedElements()
                                            return
                                        elseif fwd and optionDef.Directions ~= nil and optionDef.Directions.Right ~= nil then
                                            -- Move Right (no multiplier)
                                            optionDef.Directions.Right(false)
                                            if optionDef.ChoiceIndexGetter ~= nil then
                                                currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                            end
                                            broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                            redrawChoiceRelatedElements()
                                            return
                                        elseif bwd and optionDef.Directions ~= nil and optionDef.Directions.Left ~= nil then
                                            -- Move Left (no multiplier)
                                            optionDef.Directions.Left(false)
                                            if optionDef.ChoiceIndexGetter ~= nil then
                                                currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                            end
                                            broadcastOptionUpdate(optionDef, currentChoiceSelection)
                                            redrawChoiceRelatedElements()
                                            return
                                        end

                                        if optionDef.Choices ~= nil then
                                            moveChoiceSelection(1 * (fwd and 1 or -1))
                                        else
                                            ms.ok("ERROR REPORT TO DEVELOPER")
                                        end
                                    end
                                elseif optionDef.Type == "MultiChoice" then
                                    -- multichoice clicks will toggle the option
                                    local choiceIndex = n + (rowHandle.choicePage-1) * maxChoicesVisibleMultiChoice
                                    local choice = optionDef.Choices[choiceIndex]
                                    if choice ~= nil then
                                        choice.ChosenFunction()
                                        if optionDef.ChoiceIndexGetter ~= nil then
                                            currentChoiceSelection = optionDef.ChoiceIndexGetter()
                                        end
                                        broadcastOptionUpdate(optionDef, choice)
                                        self:playcommand("DrawChoice")
                                    end
                                end
                            end
                        end,
                        RolloverUpdateCommand = function(self, params)
                            if self:IsInvisible() then return end
                            if params.update == "in" then
                                self:diffusealpha(buttonHoverAlpha)
                                updateExplainText(rowHandle)
                                if optionDef.Type == "MultiChoice" then
                                    setCursorVerticalHorizontalPos(rowHandle, n + (rowHandle.choicePage-1) * maxChoicesVisibleMultiChoice)
                                else
                                    setCursorVerticalHorizontalPos(rowHandle, 1)
                                end
                            else
                                self:diffusealpha(1)
                            end
                        end,
                        ClickCommand = function(self, params)
                            if self:IsInvisible() then return end
                            if params.update == "OnMouseDown" then
                                if optionDef ~= nil then
                                    local direction = params.event == "DeviceButton_left mouse button" and "forward" or "backward"
                                    self:playcommand("Invoke", {direction = direction})
                                end
                            end
                        end,
                    }
                    tt[#tt+1] = Def.Quad {
                        Name = "Underline",
                        InitCommand = function(self)
                            self:halign(0):valign(0)
                            self:zoomto(0,actuals.OptionChoiceUnderlineThickness)
                            self:diffusealpha(0)
                        end,
                        DrawChoiceCommand = function(self)
                            -- assumption: this Actor is later in the command execution order than the rest of the frame
                            -- that should let it use the attributes after they are set
                            if optionDef == nil or optionDef.Type ~= "MultiChoice" then
                                self:diffusealpha(0)
                            else
                                -- optionDef present and is MultiChoice
                                -- determine if this choice is selected
                                local choiceIndex = n + (rowHandle.choicePage-1) * maxChoicesVisibleMultiChoice
                                local isSelected = currentChoiceSelection[choiceIndex]
                                if isSelected == true then
                                    local bg = self:GetParent():GetChild("BG")
                                    local text = self:GetParent():GetChild("Text")
                                    self:diffusealpha(1)
                                    self:y(bg:GetZoomedHeight()/2 + bg:GetY())
                                    self:zoomx(bg:GetZoomedWidth())
                                else
                                    self:diffusealpha(0)
                                end
                            end
                        end,
                    }
                    t[#t+1] = tt
                end
                return t
            end
            t[#t+1] = createOptionRowChoices()
            return t
        end
        for i = 1, optionRowCount do
            t[#t+1] = createOptionRow(i)
        end
        return t
    end

    local function createOptionPageChoices()
        local selectedIndex = 1

        local function createChoice(i)
            return UIElements.TextButton(1, 1, "Common Normal") .. {
                Name = "ButtonTab_"..pageNames[i],
                InitCommand = function(self)
                    local txt = self:GetChild("Text")
                    local bg = self:GetChild("BG")

                    -- this position is the center of the text
                    -- divides the space into slots for the choices then places them half way into them
                    -- should work for any count of choices
                    -- and the maxwidth will make sure they stay nonoverlapping
                    self:x((actuals.RightWidth / #pageNames) * (i-1) + (actuals.RightWidth / #pageNames / 2))
                    txt:zoom(choiceTextSize)
                    txt:maxwidth(actuals.RightWidth / #pageNames / choiceTextSize - textZoomFudge)
                    txt:settext(pageNames[i])
                    bg:zoomto(actuals.RightWidth / #pageNames, actuals.TopLipHeight)
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
                        MESSAGEMAN:Broadcast("OptionTabSet", {page = i})
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
                self:y(actuals.TopLipHeight * 1.5)
                self:playcommand("UpdateSelectedIndex")
            end,
            BeginCommand = function(self)
                local snm = SCREENMAN:GetTopScreen():GetName()
                local anm = self:GetName()

                CONTEXTMAN:RegisterToContextSet(snm, "Settings", anm)
                CONTEXTMAN:ToggleContextSet(snm, "Settings", false)

                -- enable the possibility to press the keyboard to switch tabs
                SCREENMAN:GetTopScreen():AddInputCallback(function(event)
                    -- if locked out, dont allow
                    -- pressing a number with ctrl should lead to the general tab stuff
                    -- otherwise, typing numbers will put you into that settings context and reposition the cursor
                    if not CONTEXTMAN:CheckContextSet(snm, "Settings") then return end
                    if event.type == "InputEventType_FirstPress" then
                        local char = inputToCharacter(event)
                        local num = nil

                        -- if ctrl is pressed with a number, let the general tab input handler deal with it
                        if char ~= nil and tonumber(char) and INPUTFILTER:IsControlPressed() then
                            return
                        end

                        if tonumber(char) then
                            num = tonumber(char)
                        end

                        -- cope with number presses to change option pages
                        if num ~= nil then
                            if num == 0 then num = 10 end
                            if num == selectedIndex then return end
                            if num < 1 or num > #pageNames then return end
                            selectedIndex = num
                            MESSAGEMAN:Broadcast("OptionTabSet", {page = num})
                            self:playcommand("UpdateSelectedIndex")
                        end
                    end
                end)
            end
        }
        for i = 1, #pageNames do
            t[#t+1] = createChoice(i)
        end
        return t
    end

    t[#t+1] = createOptionRows()
    t[#t+1] = createOptionPageChoices()

    return t
end

t[#t+1] = leftFrame()
t[#t+1] = rightFrame()

return t
