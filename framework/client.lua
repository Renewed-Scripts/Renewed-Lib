local Controller = {}

local framework = require 'classes.framework'

---@type framework_class
---@diagnostic disable-next-line: missing-fields
local Player = {}

---Gets the player groups
---@return table<string, number>
function Controller.getPlayerGroup()
    if table.type(Player) == 'empty' then
        return {}
    end

    return Player:getPlayerGroups()
end
exports('getPlayerGroup', Controller.getPlayerGroup) -- This one is here for backwards compatability
exports('getGroups', Controller.getPlayerGroup)

---Gets the player charId
---@return string?
exports('getCharId', function()
    if table.type(Player) == 'empty' then
        return
    end

    return Player:getCharId()
end)

---Gets the player name
---@return string?
function Controller.getCharName()
    if table.type(Player) == 'empty' then
        return
    end

    return Player:getName()
end exports('getCharName', Controller.getCharName)

---Checks weather or not the player has a group
---@param group string
---@param grade number?
---@return boolean
function Controller.hasGroup(group, grade)
    if table.type(Player) == 'empty' then
        return false
    end

    return Player:hasGroup(group, grade)
end exports('hasGroup', Controller.hasGroup)

---Creates the player object
---@param data framework_class
function Controller.createPlayer(data)
---@diagnostic disable-next-line: invisible
    Player = framework:new(data)

    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end

---Removes the player object
function Controller.removePlayer()
    ---@diagnostic disable-next-line: missing-fields
    Player = {}

    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end

---Gets the player object
---@return framework_class
function Controller.getPlayer()
    return Player
end exports('getPlayer', Controller.getPlayer)

return Controller