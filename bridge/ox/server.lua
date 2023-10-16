local file = ('imports/%s.lua'):format(IsDuplicityVersion() and 'server' or 'client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))

chunk()

function Renewed.getCharId(source)
    local player = Ox.GetPlayer(source)

    return player and player.charId
end

function Renewed.getCharName(source)
    local player = Ox.GetPlayer(source)

    return player and ('%s %s'):format(player.firstName, player.lastName)
end

function Renewed.getSourceByCharId(charId)
    local player = Ox.GetPlayerByFilter({ charId = tonumber(charId) })

    return player and player.source
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