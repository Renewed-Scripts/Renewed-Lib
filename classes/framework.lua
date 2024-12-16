
---@class framework_class : OxClass
---@field name string
---@field charId string
---@field Groups table<string, number>
---@field job string?
---@field gang string?
---@field source number? Source is nil if its on the client side
local framework_class = lib.class('framework_class')

function framework_class:constructor(data)
    self.name = data.name
    self.charId = data.charId
    self.Groups = data.Groups
    self.job = data.job
    self.gang = data.gang
    self.source = data.source
end

---Returns the player's charId
---@return string
function framework_class:getCharId()
    return self.charId
end

---Returns the players name
---@return string
function framework_class:getName()
    return self.name
end

---Returns the player's groups
---@return table<string, number>
function framework_class:getPlayerGroups()
    return self.Groups
end

---Checks if a player is in a group and if grade is provided, checks if they are that grade or higher
---@param group string
---@param grade number?
---@return boolean
function framework_class:hasGroup(group, grade)
    if grade and self.Groups[group] then
        return self.Groups[group] >= grade
    end

    return (self.Groups[group] ~= nil)
end


return framework_class