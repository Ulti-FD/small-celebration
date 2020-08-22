-- additional utility functions that could be used in places but not overshadowing other util functions


-- return the width of the widest child
-- ASSUMING all immediate children are not ActorFrames
-- this can be made into a recursive function but some behavior indicates that may not be a good idea
function getLargestChildWidth(actorFrame)
    local largest = 0
    if actorFrame == nil then
        return largest
    end

    for name, child in pairs(actorFrame:GetChildren()) do
        local w = child:GetZoomedWidth()
        if w > largest then
            largest = w
        end
    end

    return largest
end

-- recursively print the names of all children of this actorframe
function nameAllChildren(actorFrame)
    local s = actorFrame:GetName()
    actorFrame:RunCommandsRecursively(
        function(self)
            s = s .. "\n" .. self:GetName()
        end
    )
    ms.ok(s)
end

-- find the height and width while maintaining aspect ratio
function getHWKeepAspectRatio(h, w, ratio)
    local he = h / math.sqrt(ratio * ratio + 1)
    local we = w / math.sqrt(1 / (ratio * ratio) + 1)

    return he, we
end

-- string split, return a list given a string and a separator between items
function strsplit(given, separator)
    if separator == nil then
        separator = "%s" -- whitespace
    end
    local t = {}
    for str in string.gmatch(given, "([^"..separator.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- convert a shortened date string into month day year
function expandDateString(given)
    if given == nil then
        return MonthToLocalizedString(1), "1st", "0001"
    end
    local arglist = strsplit(given)

    if #arglist == 2 or #arglist == 1 then
        arglist = strsplit(arglist[1], "-")
    else
        return MonthToLocalizedString(1), "1st", "0001"
    end

    local month = MonthToLocalizedString(tonumber(arglist[2]) - 1)
    local day = tonumber(arglist[3])
    local year = arglist[1]

    if day % 100 >= 11 and day % 100 <= 13 then
        day = tostring(day) .. "th"
    else
        if day % 10 == 1 then
            day = tostring(day) .. "st"
        elseif day % 10 == 2 then
            day = tostring(day) .. "nd"
        elseif day % 10 == 3 then
            day = tostring(day) .. "rd"
        else
            day = tostring(day) .. "th"
        end
    end
    return month, day, year
end