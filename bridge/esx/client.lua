local Player = {}
local Loaded = false

function RenewedLib.getPlayerGroup()
    return Player and Player.Group or {}
end exports("GetPlayerGroup", RenewedLib.getPlayerGroup)

function RenewedLib.getCharId()
    return Player and Player.charId
end exports("GetCharId", RenewedLib.getCharId)

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

RegisterNetEvent('esx:setJob', function (job, lastJob)
    LocalPlayer.state:set('renewed_service', not string.find(job.name, 'off') and job.name or false, true)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Player = table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)