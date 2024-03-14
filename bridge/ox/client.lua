if not lib.checkDependency('ox_core', '0.21.3', true) then return end

local Ox = require '@ox_core.lib.init'

local Player = {}

function Renewed.getPlayerGroup()
    return Player and Player.group
end

function Renewed.getCharId()
    return Player and Player.charId
end

RegisterNetEvent('ox:setGroup', function(name, grade)
    Player.group[name] = grade

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.group)
end)

AddEventHandler('ox:playerLoaded', function()
    local currentPlayer = Ox.GetPlayer()

    Player = {
        charId = currentPlayer.charId,
        name = currentPlayer.name,
        group = currentPlayer.getGroups()
    }

    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end)

AddEventHandler('ox:playerLogout', function()
    table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)