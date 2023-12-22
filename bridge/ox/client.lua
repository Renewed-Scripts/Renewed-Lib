local file = ('imports/%s.lua'):format('client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))

chunk()

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

AddEventHandler('ox:playerLoaded', function(data)
    Player = {
        charId = data.charId,
        name = data.name,
        group = Ox.GetPlayerData().groups
    }

    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end)

AddEventHandler('ox:playerLogout', function()
    table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)