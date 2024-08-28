local Controller = {}

local framework = require 'classes.framework'

---@type table <number, framework_class>
local Players = {}





---Gets a player object by their source
---@param source number
---@return framework_class?
function Controller.getPlayer(source)
    return Players[source]
end exports('getSourceByCharId', Controller.getSourceByCharId)

---Gets a player object by their source
---@param source number
---@return string?
function Controller.getCharName(source)
    local Player = Players[source]

    return Player and Player.name
end exports('getCharName', Controller.getCharName)

---Gets a player object by their source
---@param source number
---@return string?
function Controller.getCharId(source)
    local Player = Players[source]

    return Player and Player.charId
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


---Creates a player object and assigns it to the class
---@param player framework_class
---@param source number
function Controller.createPlayer(player, source)
---@diagnostic disable-next-line: invisible
    Players[source] = framework:new(player)
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

return Controller