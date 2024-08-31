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


---Gets a player source from their character id
---@param charId string
exports('getPlayerFromCharId', function(charId)
    for source, v in pairs(Players) do
        if v:getCharId() == charId then
            return source
        end
    end
end)



---Creates a player object and assigns it to the class
---@param data framework_class
function Controller.createPlayer(data)
---@diagnostic disable-next-line: invisible
    Players[data.source] = framework:new(data)
    TriggerEvent('Renewed-Lib:server:playerLoaded', data.source, data)
end

local onDutyCops = {}


---Removes a player object from the class
---@param source number
function Controller.removePlayer(source)
    local Player = Players[source]

    if Player then
        Players[source] = nil
        TriggerEvent('Renewed-Lib:server:playerRemoved', source, Player)

        if onDutyCops[source] then
            onDutyCops[source] = nil
            GlobalState.copCount -= 1
        end
    end
end

AddEventHandler('playerDropped', function()
    Controller.removePlayer(source)
end)



local PoliceJobs = json.decode(GetConvar('inventory:police', '["police", "sheriff"]'))
GlobalState.copCount = 0 -- Ensure the global state is never nil

AddStateBagChangeHandler('renewed_service', nil, function(bagname, _, value)
    local Player = GetPlayerFromStateBagName(bagname)

    if Player == 0 then
        return
    end

    if value and lib.table.contains(PoliceJobs, value) then
        onDutyCops[Player] = value
        GlobalState.copCount += 1
    elseif onDutyCops[Player] then
        onDutyCops[Player] = nil
        GlobalState.copCount -= 1
    end
end)

---Returns the current cops on duty and which job they are on Duty as
---@return table<number, string>
exports('GetCopsOnDuty', function()
    return onDutyCops
end)

---Returns weather or not the player is a cop
---@param source number
---@return boolean
exports('IsPlayerACop', function(source)
    local Player = Players[source]

    if Player then
        for job in pairs(Player.Groups) do
            if lib.table.contains(PoliceJobs, job) then
                return true
            end
        end
    end

    return false
end)

return Controller