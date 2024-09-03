local Controller = require 'framework.client'

RegisterNetEvent('esx:setPlayerData', function(key, value)
	if GetInvokingResource() ~= 'es_extended' or key ~= 'job' then return end

    local Player = Controller.getPlayer()

    if table.type(Player) == 'empty' then
        return
    end

    Player.Groups = { [value.name] = value.grade }
    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Groups)
end)

RegisterNetEvent('esx:playerLoaded',function(xPlayer)
    Controller.createPlayer({
        Groups = {
            [xPlayer.job.name] = xPlayer.job.grade,
        },
        charId = xPlayer.identifier,
        name = ('%s %s'):format(xPlayer.firstName, xPlayer.lastName)
    })
end)

RegisterNetEvent('esx:setJob', function (job, lastJob)
    LocalPlayer.state:set('renewed_service', not string.find(job.name, 'off') and job.name or false, true)
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    Controller.removePlayer()
end)
