if not lib.checkDependency('ox_core', '0.21.3', true) then return end

local Ox = require '@ox_core.lib.init'

function Renewed.getCharId(source)
    local player = Ox.GetPlayer(source)

    return player and player.charId
end

Renewed.getPlayer = Ox.GetPlayer

Renewed.CreateVehicle = Ox.CreateVehicle

function Renewed.getPlayerGroups(source)
    local player = Ox.GetPlayer(source)

    return player and player.charId and player.getGroups()
end

function Renewed.getCharName(source)
    local player = Ox.GetPlayer(source)

    return player and player.charId and player.get('name')
end

function Renewed.addStress(source, value)
    local player = Ox.GetPlayer(source)

    if player and player.charId then
        player.addStatus('stress', value)
    end
end

function Renewed.relieveStress(source, value)
    local player = Ox.GetPlayer(source)

    if player and player.charId then
        player.removeStatus('stress', value)
    end
end

function Renewed.getSourceByCharId(charId)
    local player = Ox.GetPlayerByFilter({ charId = tonumber(charId) })

    return player and player.charId and player.source
end

function Renewed.removeMoney(source, amount, mType, reason)
    if mType == 'bank' then

    else -- cash
        return exports.ox_inventory:RemoveItem(source, 'money', amount)
    end
end

function Renewed.addMoney(source, amount, mType, reason)
    if mType == 'bank' then

    else -- cash
        return exports.ox_inventory:AddItem(source, 'money', amount)
    end
end

AddEventHandler('ox:playerLoaded', function(source, _, charid)
    TriggerEvent('Renewed-Lib:server:playerLoaded', source, {
        charId = charid,
    })
end)

AddEventHandler('ox:playerLogout', function(source, _, charid)
    TriggerEvent('Renewed-Lib:server:playerRemoved', source, {
        charId = charid,
    })
end)

