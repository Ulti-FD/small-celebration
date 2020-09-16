local function UpdateLoop()
    local mouseX = INPUTFILTER:GetMouseX()
    local mouseY = INPUTFILTER:GetMouseY()
    TOOLTIP:SetPosition(mouseX, mouseY)
    BUTTON:UpdateMouseState()

    return false
end

local t = Def.ActorFrame {
    InitCommand = function(self)
        self:SetUpdateFunction(UpdateLoop)
        self:SetUpdateFunctionInterval(0.01)
    end
}

local tooltip, pointer = TOOLTIP:New()
t[#t+1] = tooltip
t[#t+1] = pointer


return t;