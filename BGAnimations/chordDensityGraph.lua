local sizing = Var("sizing") -- specify init sizing
if sizing == nil then sizing = {} end
--[[
    We are expecting the sizing table to be provided on file load.
    It should contain these attributes:
    Width
    Height
    NPSThickness
    TextSize
]]
-- the bg is placed relative to top left: 0,0 alignment
-- the bars are placed relative to bottom left: 1 valign 0 halign
local stepsinuse = nil
local t = Def.ActorFrame {
    Name = "ChordDensityGraphFile",
    InitCommand = function(self)
        self:playcommand("UpdateSizing", {sizing = sizing})
        self:finishtweening()
    end,
    GeneralTabSetMessageCommand = function(self, params)
        
    end,
    CurrentRateChangedMessageCommand = function(self)
        self:playcommand("LoadDensityGraph", {steps = stepsinuse})
    end,
    LoadDensityGraphCommand = function(self, params)
        stepsinuse = params.steps or stepsinuse
    end,
    UpdateSizingCommand = function(self, params)
        local sz = params.sizing
        if sz ~= nil then
            if sz.Height ~= nil then
                sizing.Height = sz.Height
            end
            if sz.Width ~= nil then
                sizing.Width = sz.Width
            end
            if sz.NPSThickness ~= nil then
                sizing.NPSThickness = sz.NPSThickness
            end
            if sz.TextSize ~= nil then
                sizing.TextSize = sz.TextSize
            end
        end
        local bar = self:GetChild("Progress")
        local bg = self:GetChild("BG")
        local seek = self:GetChild("SeekBar")
        self:SetUpdateFunction(function(self)
            local top = SCREENMAN:GetTopScreen()
            local song = GAMESTATE:GetCurrentSong()
            if stepsinuse ~= nil and top ~= nil and top.GetSampleMusicPosition and song then
                local r = getCurRateValue()
                local length = stepsinuse:GetLengthSeconds()
                local musicpositionratio = (song:GetFirstSecond() / r + length) / sizing.Width * r
                local pos = top:GetSampleMusicPosition() / musicpositionratio
                bar:zoomx(clamp(pos, 0, sizing.Width))
            else
                bar:zoomx(0)
            end
            if isOver(bg) then
                local mx = INPUTFILTER:GetMouseX()
                local my = INPUTFILTER:GetMouseY()
                local lx, ly = bg:GetLocalMousePos(mx, my, 0)
                seek:diffusealpha(1)
                seek:x(lx)
            else
                seek:diffusealpha(0)
            end
        end)
    end
}

local function getColorForDensity(density, nColumns)
    -- Generically (generally? intelligently? i dont know) set a range
	-- The value var describes the level of density.
    -- Beginning at lowVal for 0, to highVal for nColumns.
    local interval = 1 / nColumns
	local value = 1 - density * interval
	return color(tostring(value)..","..tostring(value)..","..tostring(value))
end

local function makeABar(vertices, x, y, barWidth, barHeight, thecolor)
	-- These bars are vertical, progressively going across the screen
	-- Their corners are: (x,y), (x, y-barHeight), (x-barWidth, y-barHeight), (x-barWidth, y)
	vertices[#vertices + 1] = {{x,y-barHeight,0},thecolor}
	vertices[#vertices + 1] = {{x-barWidth,y-barHeight,0},thecolor}
	vertices[#vertices + 1] = {{x-barWidth,y,0},thecolor}
	vertices[#vertices + 1] = {{x,y,0},thecolor}
end

local function updateGraphMultiVertex(parent, self, steps)
	if steps then
		local ncol = steps:GetNumColumns()
		local rate = math.max(1, getCurRateValue())
        local graphVectors = steps:GetCDGraphVectors(rate)
        local txt = parent:GetChild("NPSText")
		if graphVectors == nil then
			-- reset everything if theres nothing to show
			self:SetVertices({})
            self:SetDrawState( {Mode = "DrawMode_Quads", First = 0, Num = 0} )
            txt:settext("")
			return
		end
		
		local npsVector = graphVectors[1] -- refers to the cps vector for 1 (tap notes)
		local numberOfColumns = #npsVector
		local columnWidth = sizing.Width / numberOfColumns * rate
		
		-- set height scale of graph relative to the max nps
		local heightScale = 0
		for i=1,#npsVector do
			if npsVector[i] * 2 > heightScale then
				heightScale = npsVector[i] * 2
			end
		end
		
        txt:settext(heightScale / 2 * 0.7 .. "NPS")
        heightScale = sizing.Height / heightScale
        
		local verts = {} -- reset the vertices for the graph
		local yOffset = 0 -- completely unnecessary, just a Y offset from the graph
		for density = 1,ncol do
			for column = 1,numberOfColumns do
                if graphVectors[density][column] > 0 then
                    local barColor = getColorForDensity(density, ncol)
                    makeABar(verts, math.min(column * columnWidth, sizing.Width), yOffset, columnWidth, graphVectors[density][column] * 2 * heightScale, barColor)
                end
			end
		end
		
		self:SetVertices(verts)
        self:SetDrawState( {Mode = "DrawMode_Quads", First = 1, Num = #verts} )
    else
        -- reset everything if theres nothing to show
        self:SetVertices({})
        self:SetDrawState( {Mode = "DrawMode_Quads", First = 0, Num = 0} )
        parent:GetChild("NPSText"):settext("")
	end
end

local textzoomFudge = 5
local bgColor = color("#FFFFFF")
local npsColor = color("#666699")
local progressColor = color("#00FF0055")
local seekColor = color("#666699")
local resizeAnimationSeconds = 0.1

t[#t+1] = UIElements.QuadButton(1, 1) .. {
    Name = "BG",
    InitCommand = function(self)
        self:halign(0):valign(0)
        self:diffuse(bgColor)
    end,
    UpdateSizingCommand = function(self)
        self:finishtweening()
        self:smooth(resizeAnimationSeconds)
        self:zoomto(sizing.Width, sizing.Height)
    end,
    MouseDownCommand = function(self, params)
        local lx = params.MouseX - self:GetParent():GetX()
        local top = SCREENMAN:GetTopScreen()
        if params.event == "DeviceButton_left mouse button" then
            local song = GAMESTATE:GetCurrentSong()
            if top.SetSampleMusicPosition and stepsinuse and song then
                local r = getCurRateValue()
                local length = stepsinuse:GetLengthSeconds()
                local musicpositionratio = (song:GetFirstSecond() / r + length) / sizing.Width * r
                top:SetSampleMusicPosition(lx * musicpositionratio)
            end
        else
            if top.PauseSampleMusic then
                top:PauseSampleMusic()
            end
        end
    end
}

t[#t+1] = Def.Quad {
    Name = "Progress",
    InitCommand = function(self)
        self:halign(0):valign(0)
        self:diffuse(progressColor)
    end,
    UpdateSizingCommand = function(self)
        self:finishtweening()
        self:smooth(resizeAnimationSeconds)
        self:zoomto(0, sizing.Height)
    end
}

t[#t+1] = Def.ActorMultiVertex {
    Name = "ChordDensityGraphAMV",
    UpdateSizingCommand = function(self)
        -- this will position the plot relative to the bottom left of the area
        -- less math, more easy, progarming fun
        self:finishtweening()
        self:smooth(resizeAnimationSeconds)
        self:y(sizing.Height)
    end,
    LoadDensityGraphCommand = function(self, params)
        updateGraphMultiVertex(self:GetParent(), self, params.steps)
    end,
}

t[#t+1] = Def.Quad {
    Name = "NPSLine",
    InitCommand = function(self)
        self:halign(0)
        self:diffuse(npsColor)
    end,
    UpdateSizingCommand = function(self)
        self:finishtweening()
        self:smooth(resizeAnimationSeconds)
        -- the NPS Line represents 75% of the actual NPS
        -- the position is relative to top left, so move it 25% of the way down
        -- do not valign this (this means the center of this line is 75%)
        self:y(sizing.Height * 0.25)
        self:zoomto(sizing.Width, sizing.NPSThickness)
    end,
}

t[#t+1] = LoadFont("Common Normal") .. {
    Name = "NPSText",
    InitCommand = function(self)
        self:halign(0):valign(1)
        self:diffuse(npsColor)
    end,
    UpdateSizingCommand = function(self)
        self:finishtweening()
        self:smooth(resizeAnimationSeconds)
        local zs = sizing.TextSize or 1
        self:zoom(zs)
        -- this text is positioned above the NPS line, basically half the thickness above it
        self:y(sizing.Height * 0.25 - sizing.NPSThickness * 0.75)
        self:maxwidth(sizing.Width / zs - textzoomFudge)
    end,
}

t[#t+1] = Def.Quad {
    Name = "SeekBar",
    InitCommand = function(self)
        self:valign(0)
        self:diffuse(seekColor)
        self:diffusealpha(0)
    end,
    UpdateSizingCommand = function(self)
        self:finishtweening()
        self:smooth(resizeAnimationSeconds)
        self:zoomto(sizing.NPSThickness, sizing.Height)
    end
}

return t