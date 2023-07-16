local Player = {}
local Loaded = false

function Renewed.getPlayerGroup()
    return Player and Player.Group or {}
end

function Renewed.getCharId()
    return Player and Player.charId
end

RegisterNetEvent('esx:setPlayerData', function(key, value)
	if not Loaded or GetInvokingResource() ~= 'es_extended' then return end

    if key ~= 'job' then return end

    Player.Group = { [value.name] = value.grade }
    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Group)
end)

RegisterNetEvent('esx:playerLoaded',function(xPlayer)
    Player = {
        Group = {
            [xPlayer.job.name] = xPlayer.job.grade,
        },
        charId = xPlayer.identifier,
        name = ('%s %s'):format(xPlayer.firstName, xPlayer.lastName)
    }

    Loaded = true
    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Player = table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)