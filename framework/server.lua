local Controller = {}

local framework = require 'classes.framework'

---@type table <number, framework_class>
local Players = {}


---Gets a player object by their source
---@param source number
---@return framework_class?
function Controller.getPlayer(source)
    return Players[source]
end exports('getPlayer', Controller.getPlayer)

---Gets a player object by their source
---@param source number
---@return string?
function Controller.getCharName(source)
    local Player = Players[source]

    return Player and Player:getName()
end exports('getCharName', Controller.getCharName)

---Gets a player object by their source
---@param source number
---@return string?
function Controller.getCharId(source)
    local Player = Players[source]

    return Player and Player:getCharId()
end exports('getCharId', Controller.getCharId)

---Finds a player by their charId
---@param charId string
---@return number?
function Controller.getSourceByCharId(charId)
    for k, v in pairs(Players) do
        if v.charId == charId then
            return k
        end
    end
end exports('getSourceByCharId', Controller.getSourceByCharId)


---Checks if a player is in a group and if great is provided, checks if they are that grade or higher
---@param source number
---@param group string
---@param grade number?
---@return boolean
function Controller.hasGroup(source, group, grade)
    local Player = Players[source]

    return Player and Player:hasGroup(group, grade)
end exports('hasGroup', Controller.hasGroup)

---Gets a player's groups
---@param source number
---@return table<string, number>?
function Controller.getGroups(source)
    local Player = Players[source]

    return Player and Player:getPlayerGroups()
end exports('getGroups', Controller.getGroups)



---Creates a player object and assigns it to the class
---@param data framework_class
function Controller.createPlayer(data)
---@diagnostic disable-next-line: invisible
    Players[data.source] = framework:new(data)
    TriggerEvent('Renewed-Lib:server:playerLoaded', data.source, data)
end exports('createPlayer', Controller.createPlayer)


---Removes a player object from the class
---@param source number
function Controller.removePlayer(source)
    local Player = Players[source]

    if Player then
        Players[source] = nil
        TriggerEvent('Renewed-Lib:server:playerRemoved', source, Player)
    end
end

AddEventHandler('playerDropped', function()
    Controller.removePlayer(source)
end)

return Controller