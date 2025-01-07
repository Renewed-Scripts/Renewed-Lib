local Controller = require 'framework.client'
local Ox = require '@ox_core.lib.init'


RegisterNetEvent('ox:setGroup', function(name, grade)
    local Player = Controller.getPlayer()

    if Player then
        Player.group[name] = grade
        TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.group)
    end
end)


AddEventHandler('ox:playerLoaded', function()
    local currentPlayer = Ox.GetPlayer()

    Controller.createPlayer({
        Groups = currentPlayer.getGroups(),
        charId = currentPlayer.stateId,
        name = currentPlayer.get('fullName')
    })
end)

AddEventHandler('ox:playerLogout', Controller.removePlayer())
