
local Controller = require 'framework.client'

NDCore = {}

lib.load('@ND_Core.init')

local function convertNDGroups(groups)
    local converted = {}
    for groupName, groupInfo in pairs(groups) do
        converted[groupName] = groupInfo.rank
    end
    return converted
end

RegisterNetEvent('ND_Status:setStatuses', function(statuses) -- Created compat event for ND_Status client export
    if GetResourceState('ND_Status') == 'missing' then return end

    if type(statuses) ~= 'table' then
        return lib.print.info(('Expected Statuses Table - Received: %s'):format(type(statuses)))
    end

    for statusName, statusAmount in pairs(statuses) do
        exports['ND_Status']:setStatus(statusName, statusAmount)
    end
end)

RegisterNetEvent('ND:updateCharacter', function(PlayerData, updateType)
    if updateType ~= "groups" or updateType ~= "job" then return end

    local Player = Controller.getPlayer()

    if updateType == "job" and Player.job ~= PlayerData.job then
        Player.job = PlayerData.job
    end

    if updateType == "groups" then
        Player.Groups = convertNDGroups(PlayerData.groups)
    end

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Groups)
end)

RegisterNetEvent('ND:characterLoaded', function()
    local PlayerData = NDCore.getPlayer()

    local groups = convertNDGroups(PlayerData.groups)

    Controller.createPlayer({
        Groups = groups,
        charId = PlayerData.id,
        job = PlayerData.job,
        name = PlayerData.fullname
    })

    LocalPlayer.state:set('renewed_service', PlayerData?.job or false, true) -- ND doesn't have duty states, set to current job
end)

RegisterNetEvent('ND:characterUnloaded', function()
    LocalPlayer.state:set('renewed_service', false, true)
    Controller.removePlayer()
end)
