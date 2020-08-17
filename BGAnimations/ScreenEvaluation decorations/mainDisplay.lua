local judgeSetting = (PREFSMAN:GetPreference("SortBySSRNormPercent") and 4 or GetTimingDifficulty())

local t = Def.ActorFrame {
    Name = "MainDisplayFile",
    OnCommand = function(self)
        local score = SCOREMAN:GetMostRecentScore()
        if not score then
            score = SCOREMAN:GetTempReplayScore()
        end

        --- propagate set command through children with the song
        self:playcommand("Set", {song = GAMESTATE:GetCurrentSong(), steps = GAMESTATE:GetCurrentSteps(), score = score})
    end
}

local ratios = {
    LeftGap = 78 / 1920,
    UpperGap = 135 / 1080, -- from top edge of screen to edge of bg
    Width = 1765 / 1920,
    Height = 863 / 1080,
    LipLeftGap = 758 / 1920, -- the lip starts at the end of the banner
    LipHeight = 50 / 1080,
    LipLength = 1007 / 1920, -- runs to the right end of the frame

    GraphLeftGap = 18 / 1920,
    GraphWidth = 739 / 1920, -- this must be the same as in metrics [GraphDisplay/ComboGraph]
    GraphBannerGap = 16 / 1080, -- from bottom of banner to top of graph
    BannerLeftGap = 18 / 1920,
    BannerHeight = 228 / 1080,
    BannerWidth = 739 / 1920,
    LifeGraphHeight = 71 / 1080, -- this must be the same as in metrics [GraphDisplay]
    ComboGraphHeight = 16 / 1080, -- this must be the same as in metrics [ComboGraph]

    DividerThickness = 2 / 1080,
    LeftDividerLeftGap = 18 / 1920,
    LeftDividerLength = 739 / 1920,

    LeftDivider1UpperGap = 338 / 1080,
    LeftDivider2UpperGap = 399 / 1080,

    ModTextLeftGap = 19 / 1920,
    -- modtext Y pos is half between the 2 dividers.

    JudgmentBarLeftGap = 18 / 1920, -- edge of frame to left of bar
    JudgmentBarUpperGap = 408 / 1080, -- top edge of from to top edge of top bar
    JudgmentBarHeight = 44 / 1080,
    JudgmentBarAllottedSpace = 264 / 1080, -- top of top bar to top of bottom bar (valign 0)
    JudgmentBarLength = 739 / 1920,
    JudgmentBarSpacing = 7 / 1080, -- the emptiness between judgments
    JudgmentNameLeftGap = 25 / 1920, -- from left edge of bar to left edge of text
    JudgmentCountRightGap = 95 / 1920, -- from right edge of bar to left edge of percentage, right edge of count

    BottomTextUpperGap = 733 / 1080, -- top edge of frame to top edge of the text at the bottom left of the screen
    BottomTextHeight = 16 / 1080, -- fudge
    BottomTextSpacing = 10 / 1080, -- mix with the immediately above value
    SubTypeTextLeftGap = 18 / 1920, -- edge of frame to left of text
    SubTypeCountLeftGap = 102 / 1920, -- left edge of name to left edge of number
    SubTypeCountTotalLeftGap = 196 / 1920, -- left edge of name to right edge of number
    SubTypeCountWidth = 95 / 1920, -- approximate width of the numbers including the /
    SubTypeAllottedSpace = 105 / 1080, -- top of top text to top of bottom text (valign 0)

    StatTextRightGap = 195 / 1920, -- right edge of stat count text to left edge of name text
    StatCountRightGap = 54 / 1920, -- right edge of stat count text to right edge of count text
    StatCountTotalRightGap = 0 / 1920, -- this is a base line, probably 0, here for consistency
    StatCountWidth = 95 / 1920, -- approximate width of the numbers including the /
    StatTextAllottedSpace = 105 / 1080, -- top of top text to top of bottom text (valign 0)

    RightHalfLeftGap = 803 / 1920, -- left edge of frame to left edge of everything on the right side
    RightHorizontalDividerLength = 936 / 1920,
    RightVerticalDividerLength = 250 / 1080,
    RightHorizontalDivider1UpperGap = 244 / 1080, -- top of frame to top of divider
    RightHorizontalDivider2UpperGap = 544 / 1080, -- same
    RightVerticalDividerLeftGap = 131 / 1920, -- from RightHalfLeftGap to left edge of divider
    RightVerticalDividerUpperGap = 274 / 1080, -- from top of frame to top of divider

    SongInfoUpperGap = 75 / 1080, -- from top of frame to top of title
    SongArtistUpperGap = 43 / 1080, -- from top of song title to top of artist
    SongPackUpperGap = 87 / 1080, -- from top of song title to top of pack name
    SongRateUpperGap = 131 / 1080, -- from top of song title to top of rate
}

local actuals = {
    LeftGap = ratios.LeftGap * SCREEN_WIDTH,
    UpperGap = ratios.UpperGap * SCREEN_HEIGHT,
    Width = ratios.Width * SCREEN_WIDTH,
    Height = ratios.Height * SCREEN_HEIGHT,
    LipLeftGap = ratios.LipLeftGap * SCREEN_WIDTH,
    LipHeight = ratios.LipHeight * SCREEN_HEIGHT,
    LipLength = ratios.LipLength * SCREEN_WIDTH,
    GraphLeftGap = ratios.GraphLeftGap * SCREEN_WIDTH,
    GraphWidth = ratios.GraphWidth * SCREEN_WIDTH,
    GraphBannerGap = ratios.GraphBannerGap * SCREEN_HEIGHT,
    BannerLeftGap = ratios.BannerLeftGap * SCREEN_WIDTH,
    BannerHeight = ratios.BannerHeight * SCREEN_HEIGHT,
    BannerWidth = ratios.BannerWidth * SCREEN_WIDTH,
    LifeGraphHeight = ratios.LifeGraphHeight * SCREEN_HEIGHT,
    ComboGraphHeight = ratios.ComboGraphHeight * SCREEN_HEIGHT,
    DividerThickness = ratios.DividerThickness * SCREEN_HEIGHT,
    LeftDividerLeftGap = ratios.LeftDividerLeftGap * SCREEN_WIDTH,
    LeftDividerLength = ratios.LeftDividerLength * SCREEN_WIDTH,
    LeftDivider1UpperGap = ratios.LeftDivider1UpperGap * SCREEN_HEIGHT,
    LeftDivider2UpperGap = ratios.LeftDivider2UpperGap * SCREEN_HEIGHT,
    ModTextLeftGap = ratios.ModTextLeftGap * SCREEN_WIDTH,
    JudgmentBarLeftGap = ratios.JudgmentBarLeftGap * SCREEN_WIDTH,
    JudgmentBarUpperGap = ratios.JudgmentBarUpperGap * SCREEN_HEIGHT,
    JudgmentBarHeight = ratios.JudgmentBarHeight * SCREEN_HEIGHT,
    JudgmentBarAllottedSpace = ratios.JudgmentBarAllottedSpace * SCREEN_HEIGHT,
    JudgmentBarLength = ratios.JudgmentBarLength * SCREEN_WIDTH,
    JudgmentBarSpacing = ratios.JudgmentBarSpacing * SCREEN_HEIGHT,
    JudgmentNameLeftGap = ratios.JudgmentNameLeftGap * SCREEN_WIDTH,
    JudgmentCountRightGap = ratios.JudgmentCountRightGap * SCREEN_WIDTH,
    BottomTextUpperGap = ratios.BottomTextUpperGap * SCREEN_HEIGHT,
    BottomTextHeight = ratios.BottomTextHeight * SCREEN_HEIGHT,
    BottomTextSpacing = ratios.BottomTextSpacing * SCREEN_HEIGHT,
    SubTypeTextLeftGap = ratios.SubTypeTextLeftGap * SCREEN_WIDTH,
    SubTypeCountLeftGap = ratios.SubTypeCountLeftGap * SCREEN_WIDTH,
    SubTypeCountTotalLeftGap = ratios.SubTypeCountTotalLeftGap * SCREEN_WIDTH,
    SubTypeCountWidth = ratios.SubTypeCountWidth * SCREEN_WIDTH,
    SubTypeAllottedSpace = ratios.SubTypeAllottedSpace * SCREEN_HEIGHT,
    StatTextRightGap = ratios.StatTextRightGap * SCREEN_WIDTH,
    StatCountRightGap = ratios.StatCountRightGap * SCREEN_WIDTH,
    StatCountTotalRightGap = ratios.StatCountTotalRightGap * SCREEN_WIDTH,
    StatCountWidth = ratios.StatCountWidth * SCREEN_WIDTH,
    StatTextAllottedSpace = ratios.StatTextAllottedSpace * SCREEN_HEIGHT,
    RightHalfLeftGap = ratios.RightHalfLeftGap * SCREEN_WIDTH,
    RightHorizontalDividerLength = ratios.RightHorizontalDividerLength * SCREEN_WIDTH,
    RightVerticalDividerLength = ratios.RightVerticalDividerLength * SCREEN_HEIGHT,
    RightHorizontalDivider1UpperGap = ratios.RightHorizontalDivider1UpperGap * SCREEN_HEIGHT,
    RightHorizontalDivider2UpperGap = ratios.RightHorizontalDivider2UpperGap * SCREEN_HEIGHT,
    RightVerticalDividerLeftGap = ratios.RightVerticalDividerLeftGap * SCREEN_WIDTH,
    RightVerticalDividerUpperGap = ratios.RightVerticalDividerUpperGap * SCREEN_HEIGHT,
    SongInfoUpperGap = ratios.SongInfoUpperGap * SCREEN_HEIGHT,
    SongArtistUpperGap = ratios.SongArtistUpperGap * SCREEN_HEIGHT,
    SongPackUpperGap = ratios.SongPackUpperGap * SCREEN_HEIGHT,
    SongRateUpperGap = ratios.SongRateUpperGap * SCREEN_HEIGHT,
}

-- list of judgments to display the bar/counts for
local judgmentsChosen = {
    "TapNoteScore_W1", -- marvelous
    "TapNoteScore_W2", -- perfect
    "TapNoteScore_W3", -- great
    "TapNoteScore_W4", -- good
    "TapNoteScore_W5", -- bad
    "TapNoteScore_Miss", -- miss
}

-- list of tap/hold subtypes to display the counts for
-- these are each a part of RadarCategory_x
local subTypesChosen = {
    "Holds",
    "Mines",
    "Rolls",
    "Lifts",
    "Fakes",
}

local modTextZoom = 0.6
local judgmentTextZoom = 0.6
local judgmentCountZoom = 0.6
local judgmentPercentZoom = 0.3
local judgmentCountPercentBump = 1 -- a bump in position added to the Count and Percent for spacing
local subTypeTextZoom = 0.7
local statTextZoom = 0.7
local statTextSuffixZoom = 0.6
local titleTextSize = 0.8
local songInfoTextSize = 0.55
local textzoomFudge = 5

local textEmbossColor = color("0,0,0,0")

local function judgmentBars()
    local totalTaps = 0
    local t = Def.ActorFrame {
        Name = "JudgmentBarParentFrame",
        SetCommand = function(self, params)
            totalTaps = 0
            for i, j in ipairs(judgmentsChosen) do
                totalTaps = totalTaps + params.score:GetTapNoteScore(j)
            end
        end
    }
    local function makeJudgment(i)
        local jdg = judgmentsChosen[i]

        return Def.ActorFrame {
            Name = "Judgment_"..i,
            InitCommand = function(self)
                -- finds the top of every bar given the requested spacing and the height of each bar within the allotted space
                self:y((((i-1) * actuals.JudgmentBarHeight + (i-1) * actuals.JudgmentBarSpacing) / actuals.JudgmentBarAllottedSpace) * actuals.JudgmentBarAllottedSpace)
            end,

            Def.Quad {
                Name = "BG",
                InitCommand = function(self)
                    self:halign(0):valign(0)
                    self:zoomto(actuals.JudgmentBarLength, actuals.JudgmentBarHeight)
                    self:diffuse(byJudgment(jdg))
                    self:diffusealpha(0.7)
                end
            },
            Def.Quad {
                Name = "Fill",
                InitCommand = function(self)
                    self:halign(0):valign(0)
                    self:zoomto(0, actuals.JudgmentBarHeight)
                    self:diffuse(byJudgment(jdg))
                end,
                SetCommand = function(self, params)
                    if params.score == nil then
                        self:zoomx(0)
                        return
                    end
                    local percent = params.score:GetTapNoteScore(jdg) / totalTaps
                    self:zoomx(actuals.JudgmentBarLength * percent)
                end
            },
            LoadFont("Common Large") .. {
                Name = "Name",
                InitCommand = function(self)
                    self:halign(0)
                    self:xy(actuals.JudgmentNameLeftGap, actuals.JudgmentBarHeight / 2)
                    self:zoom(judgmentTextZoom)
                    self:strokecolor(textEmbossColor)
                    --self:maxwidth()
                    self:settext(getJudgeStrings(ms.JudgeCount[i]))
                end
            },
            Def.RollingNumbers {
                Name = "Count",
                Font = "Common Large",
                InitCommand = function(self)
                    self:Load("RollingNumbersNoLead")
                    self:halign(1)
                    self:xy(actuals.JudgmentBarLength - actuals.JudgmentCountRightGap - judgmentCountPercentBump, actuals.JudgmentBarHeight / 2)
                    self:zoom(judgmentCountZoom)
                    self:strokecolor(textEmbossColor)
                    self:targetnumber(0)
                end,
                SetCommand = function(self, params)
                    if params.score == nil then
                        self:targetnumber(0)
                        return
                    end
                    local count = params.score:GetTapNoteScore(jdg)
                    self:targetnumber(count)
                end
            },
            Def.RollingNumbers {
                Name = "Percentage",
                Font = "Common Large",
                InitCommand = function(self)
                    self:Load("RollingNumbersJudgmentPercentage")
                    self:halign(0)
                    self:xy(actuals.JudgmentBarLength - actuals.JudgmentCountRightGap + judgmentCountPercentBump, actuals.JudgmentBarHeight / 2)
                    self:zoom(judgmentPercentZoom)
                    self:strokecolor(textEmbossColor)
                    self:targetnumber(0)
                end,
                SetCommand = function(self, params)
                    if params.score == nil then
                        self:targetnumber(0)
                        return
                    end
                    local percent = params.score:GetTapNoteScore(jdg) / totalTaps * 100
                    self:targetnumber(percent)
                end
            }
        }
    end
    for i = 1, #judgmentsChosen do
        t[#t+1] = makeJudgment(i)
    end

    return t
end

local function subTypeStats()
    local t = Def.ActorFrame {Name = "SubTypeParentFrame"}
    local function makeLine(i)
        local rdr = subTypesChosen[i]

        return Def.ActorFrame {
            Name = "SubTypeLine_"..i,
            InitCommand = function(self)
                self:y((actuals.SubTypeAllottedSpace / (#subTypesChosen - 1)) * (i-1))
            end,

            LoadFont("Common Normal") .. {
                Name = "Name",
                InitCommand = function(self)
                    self:halign(0):valign(0)
                    self:zoom(subTypeTextZoom)
                    self:maxwidth(actuals.SubTypeCountLeftGap / subTypeTextZoom - textzoomFudge)
                    self:settext(rdr)
                end
            },
            Def.RollingNumbers {
                Name = "Count",
                Font = "Common Normal",
                InitCommand = function(self)
                    self:Load("RollingNumbers3Leading")
                    self:halign(0):valign(0)
                    self:x(actuals.SubTypeCountLeftGap)
                    self:zoom(subTypeTextZoom)
                    self:maxwidth(actuals.SubTypeCountWidth / 2 / subTypeTextZoom - textzoomFudge)
                    self:targetnumber(0)
                end,
                SetCommand = function(self, params)
                    if params.score == nil then
                        self:targetnumber(0)
                        return
                    end
                    local num = params.score:GetRadarValues():GetValue(rdr)
                    self:targetnumber(num)
                end
            },
            LoadFont("Common Normal") .. {
                Name = "Slash",
                InitCommand = function(self)
                    -- when you want to do something in a really particular way and dont trust anything else to get it right
                    self:valign(0)
                    self:x(actuals.SubTypeCountLeftGap + actuals.SubTypeCountWidth / 2)
                    self:zoom(subTypeTextZoom)
                    self:settext("/")
                end
            },
            Def.RollingNumbers {
                Name = "Total",
                Font = "Common Normal",
                InitCommand = function(self)
                    self:Load("RollingNumbers3Leading")
                    self:halign(1):valign(0)
                    self:x(actuals.SubTypeCountTotalLeftGap)
                    self:zoom(subTypeTextZoom)
                    self:maxwidth(actuals.SubTypeCountWidth / 2 / subTypeTextZoom - textzoomFudge)
                    self:targetnumber(0)
                end,
                SetCommand = function(self, params)
                    if params.score == nil then
                        self:targetnumber(0)
                        return
                    end
                    local num = params.score:GetRadarPossible():GetValue("RadarCategory_"..rdr)
                    self:targetnumber(num)
                end
            }
        }
    end
    for i = 1, #subTypesChosen do
        t[#t+1] = makeLine(i)
    end

    return t
end

local function calculatedStats()
    -- list of stats
    -- do not allow this list to be shorter than 2 in length
    local statStrings = {
        "Mean",
        "Sd",
        "Largest",
        "Left CBs",
        "Middle CBs", -- skip this index for even column types
        "Right CBs",
    }
    
    local statSuffixes = {
        "ms", -- Mean milliseconds
        "ms", -- Standard Deviation milliseconds
        "ms", -- Largest Deviation milliseconds
        "", -- count
        "", -- count
        "", -- count
    }

    -- RollingNumber types in metrics
    -- so we can assign it without so much work
    local statTypes = {
        "2DecimalNoLead",
        "2DecimalNoLead",
        "2DecimalNoLead",
        "NoLead",
        "NoLead",
        "NoLead",
    }

    local evenColumns = true
    local indexToSkip = 5 -- the middle cb index
    
    -- contains the data corresponding to each of the above stat strings
    local statData = {
        0, -- mean
        0, -- sd
        0, -- largest deviation
        0, -- left cb
        0, -- middle cb
        0, -- right cb
    }

    local function calculateStatData(score, numColumns)
        local tracks = score:GetTrackVector()
        local offsetTable = score:GetOffsetVector()

        local middleColumn = numColumns / 2

        local cbThreshold = ms.JudgeScalers[judgeSetting]
        local leftCB = 0
        local middleCB = 0
        local rightCB = 0
        local smallest, largest = wifeRange(offsetTable)

        -- count CBs
        for i = 1, #offsetTable do
            if tracks[i] then
                if math.abs(offsetTable[i]) > cbThreshold * 90 then
                    if tracks[i] < middleColumn then
                        leftCB = leftCB + 1
                    elseif tracks[i] > middleColumn then
                        rightCB = rightCB + 1
                    else
                        middleCB = middleCB + 1
                    end
                end
            end
        end

        -- MUST MATCH statData above
        local output = {
            wifeMean(offsetTable), -- mean
            wifeSd(offsetTable), -- sd
            largest,
            leftCB,
            middleCB,
            rightCB,
        }
        return output
    end

    local t = Def.ActorFrame {
        Name = "CalculatedStatsParentFrame",
        SetCommand = function(self, params)
            if params.steps ~= nil then
                if params.steps:GetNumColumns() % 2 ~= 0 then
                    evenColumns = false
                end
                -- this recalculates the stats to display for the following texts
                -- subtract 1 from the number of columns because we are indexing at 0 in some of the data
                -- and it produces the numbers we want
                statData = calculateStatData(params.score, params.steps:GetNumColumns() - 1)

                self:playcommand("UpdateStats", {score = params.score})
            end
        end
    }
    local function makeLine(i)
        local statname = statStrings[i]
        return Def.ActorFrame {
            Name = "Stat_"..i,
            InitCommand = function(self)
                self:y((actuals.StatTextAllottedSpace / (#statStrings - 1)) * (i-1))
            end,
            UpdateStatsCommand = function(self, params)
                if evenColumns and i == indexToSkip then
                    self:diffusealpha(0)
                else
                    self:diffusealpha(1)
                end
                if evenColumns then
                    if i ~= indexToSkip then
                        -- this will convert the index to either i or i-1
                        -- because when we skip an index we want to place it as if nothing changed
                        -- and we are using a slightly shorter range than usual anyways
                        local j = (i < indexToSkip and i or i-1)
                        self:y((actuals.StatTextAllottedSpace / (#statStrings - 2)) * (j-1))
                    end
                end
            end,

            LoadFont("Common Normal") .. {
                Name = "Name",
                InitCommand = function(self)
                    self:halign(0):valign(0)
                    self:zoom(statTextZoom)
                    self:maxwidth(actuals.StatCountWidth / statTextZoom - textzoomFudge)
                    self:settext(statname)
                end
            },
            Def.RollingNumbers {
                Name = "Number",
                Font = "Common Normal",
                InitCommand = function(self)
                    self:Load("RollingNumbers" .. statTypes[i])
                    self:halign(1):valign(0)
                    -- note to self make this name less confusing
                    self:x(actuals.StatTextRightGap)
                    self:zoom(statTextZoom)
                    self:maxwidth(actuals.StatCountWidth / statTextZoom - textzoomFudge)
                    self:targetnumber(0)
                end,
                UpdateStatsCommand = function(self, params)
                    -- move the number over according to the suffix
                    -- and adjust the maxwidth to compensate for the reduced room
                    local suffixWidth = self:GetParent():GetChild("Suffix"):GetZoomedWidth()
                    self:x(actuals.StatTextRightGap - suffixWidth)
                    self:maxwidth((actuals.StatCountWidth - suffixWidth) / statTextZoom - textzoomFudge)
                    self:targetnumber(statData[i])
                end
            },
            LoadFont("Common Normal") .. {
                Name = "Suffix",
                InitCommand = function(self)
                    self:halign(1):valign(0)
                    self:x(actuals.StatTextRightGap)
                    self:zoom(statTextSuffixZoom)
                    self:settext(statSuffixes[i])
                    self:diffusealpha(0)
                end,
                UpdateStatsCommand = function(self, params)
                    -- all of this garbage to get the text to align to the bottom of the line instead of the top
                    -- (thanks to me for having foresight and setting parent Y appropriately first)
                    local aligningtext = self:GetParent():GetChild("Number")
                    local heightaligningto = aligningtext:GetZoomedHeight()
                    self:valign(1):y(heightaligningto)

                    self:diffusealpha(1)
                end
            }
        }

    end

    for i = 1, #statStrings do
        t[#t+1] = makeLine(i)
    end
    return t
end

t[#t+1] = Def.ActorFrame {
    Name = "OwnerFrame",
    InitCommand = function(self)
        self:xy(actuals.LeftGap, actuals.UpperGap)
    end,

    Def.Quad {
        Name = "BG",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:zoomto(actuals.Width, actuals.Height)
            self:diffuse(color("#111111"))
            self:diffusealpha(0.75)
        end
    },
    Def.Quad {
        Name = "BGLip",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:x(actuals.LipLeftGap)
            self:zoomto(actuals.LipLength, actuals.LipHeight)
            self:diffuse(color("#111111"))
        end
    },
    Def.Quad {
        Name = "LeftUpperDivider",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:zoomto(actuals.LeftDividerLength, actuals.DividerThickness)
            self:xy(actuals.LeftDividerLeftGap, actuals.LeftDivider1UpperGap)
        end
    },
    Def.Quad {
        Name = "LeftLowerDivider",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:zoomto(actuals.LeftDividerLength, actuals.DividerThickness)
            self:xy(actuals.LeftDividerLeftGap, actuals.LeftDivider2UpperGap)
        end
    },
    Def.Quad {
        Name = "RightUpperHorizontalDivider",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:zoomto(actuals.RightHorizontalDividerLength, actuals.DividerThickness)
            self:xy(actuals.RightHalfLeftGap, actuals.RightHorizontalDivider1UpperGap)
        end
    },
    Def.Quad {
        Name = "RightLowerHorizontalDivider",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:zoomto(actuals.RightHorizontalDividerLength, actuals.DividerThickness)
            self:xy(actuals.RightHalfLeftGap, actuals.RightHorizontalDivider2UpperGap)
        end
    },
    Def.Quad {
        Name = "RightVerticalDivider",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:zoomto(actuals.DividerThickness, actuals.RightVerticalDividerLength)
            self:xy(actuals.RightHalfLeftGap + actuals.RightVerticalDividerLeftGap, actuals.RightVerticalDividerUpperGap)
        end
    },

    Def.Sprite {
        Name = "Banner",
        InitCommand = function(self)
            self:x(actuals.BannerLeftGap)
            self:valign(0):halign(0)
            self:scaletoclipped(actuals.BannerWidth, actuals.BannerHeight)
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
                local bnpath = THEME:GetPathG("Common", "fallback banner")
                self:LoadBackground(bnpath)
            end
        end
    },
    Def.GraphDisplay {
        Name = "LifeGraph",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:xy(actuals.GraphLeftGap, actuals.GraphBannerGap + actuals.BannerHeight)
            -- due to reasons, the sizing for this is in metrics [GraphDisplay]
            -- we override them with the following zoomto
            -- so the ones in metrics can be anything....
            -- i don't like that
            self:Load("GraphDisplay")
            self:zoomto(actuals.GraphWidth, actuals.LifeGraphHeight)

            -- hide the max life line and its dots (why does this exist?)
            self:GetChild("Line"):diffusealpha(0)
        end,
        SetCommand = function(self, params)
            local ss = SCREENMAN:GetTopScreen():GetStageStats()
            self:Set(ss, ss:GetPlayerStageStats(PLAYER_1))
        end
    },
    Def.ComboGraph {
        Name = "ComboGraph",
        InitCommand = function(self)
            self:valign(0):halign(0)
            self:xy(actuals.GraphLeftGap, actuals.GraphBannerGap + actuals.BannerHeight + actuals.LifeGraphHeight)
            -- due to reasons, the sizing for this is in metrics [ComboGraph]
            -- self:zoomto(actuals.GraphWidth, actuals.ComboGraphHeight)
        end,
        SetCommand = function(self, params)
            -- we have to destroy and reload all children of the ComboGraph when setting it
            -- this crashes really easily if you do it wrong
            if #(self:GetChildren()) > 0 then
                self:Clear()
            end
            self:Load("ComboGraph")
            local ss = SCREENMAN:GetTopScreen():GetStageStats()
            self:Set(ss, ss:GetPlayerStageStats(PLAYER_1))
        end
    },
    LoadFont("Common Large") .. {
        Name = "ModString",
        InitCommand = function(self)
            -- should be the upper divider + half the space between (accounting for the width of the top divider)
            local yPos = actuals.LeftDivider1UpperGap + (actuals.LeftDivider2UpperGap - actuals.LeftDivider1UpperGap) / 2 + actuals.DividerThickness
            self:xy(actuals.ModTextLeftGap, yPos)
            self:halign(0)
            self:zoom(modTextZoom)
            self:maxwidth(actuals.BannerWidth / modTextZoom - textzoomFudge)
        end,
        SetCommand = function(self, params)
            local mstr = GAMESTATE:GetPlayerState(PLAYER_1):GetPlayerOptionsString("ModsLevel_Current")
            local ss = SCREENMAN:GetTopScreen():GetStageStats()
            if not ss:GetLivePlay() then
                mstr = SCREENMAN:GetTopScreen():GetReplayModifiers()
            end
            self:settext(mstr)
        end
    },
    judgmentBars() .. {
        InitCommand = function(self)
            self:xy(actuals.JudgmentBarLeftGap, actuals.JudgmentBarUpperGap)
        end
    },
    subTypeStats() .. {
        InitCommand = function(self)
            self:xy(actuals.SubTypeTextLeftGap, actuals.BottomTextUpperGap)
        end
    },
    calculatedStats() .. {
        InitCommand = function(self)
            self:xy(actuals.JudgmentBarLeftGap + actuals.JudgmentBarLength - actuals.StatTextRightGap, actuals.BottomTextUpperGap)
        end
    },

    LoadFont("Common Large") .. {
        Name = "ScreenTitle",
        InitCommand = function(self)
            self:xy(actuals.RightHalfLeftGap, actuals.LipHeight / 2)
            self:halign(0)
            self:zoom(titleTextSize)
            self:settext("Results")
        end
    },
    Def.ActorFrame {
        Name = "BasicSongInfo",
        InitCommand = function(self)
            self:xy(actuals.RightHalfLeftGap, actuals.SongInfoUpperGap)
        end,

        LoadFont("Common Large") .. {
            Name = "SongTitle",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:zoom(songInfoTextSize)
                self:settext(GAMESTATE:GetCurrentSong():GetDisplayMainTitle())
            end
        },
        LoadFont("Common Large") .. {
            Name = "SongArtist",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:y(actuals.SongArtistUpperGap)
                self:zoom(songInfoTextSize)
                self:settext(GAMESTATE:GetCurrentSong():GetDisplayArtist())
            end
        },
        LoadFont("Common Large") .. {
            Name = "SongPack",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:y(actuals.SongPackUpperGap)
                self:zoom(songInfoTextSize)
                self:settext(GAMESTATE:GetCurrentSong():GetGroupName())
            end
        },
        LoadFont("Common Large") .. {
            Name = "SongRate",
            InitCommand = function(self)
                self:halign(0):valign(0)
                self:y(actuals.SongRateUpperGap)
                self:zoom(songInfoTextSize)
            end,
            BeginCommand = function(self)
                local rate = SCREENMAN:GetTopScreen():GetReplayRate()
                if not rate then rate = getCurRateValue() end
                local ratestr = getRateString(rate)
                self:settext(ratestr)
            end
        }
    }


}

return t