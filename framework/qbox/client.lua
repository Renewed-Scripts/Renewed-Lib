
local Controller = require 'framework.client'


RegisterNetEvent('qbx_core:client:onGroupUpdate', function(groupName, groupGrade)
    local Player = Controller.getPlayer()

    Player.Groups[groupName] = not groupGrade and nil or groupGrade
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = exports.qbx_core:GetPlayerData()

    local groups = {}

    for groupName, grade in pairs(PlayerData.jobs) do
        groups[groupName] = grade
    end

    for groupName, grade in pairs(PlayerData.gangs) do
        groups[groupName] = grade
    end

    Controller.createPlayer({
        Groups = groups,
        charId = PlayerData.citizenid,
        name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
    })

    LocalPlayer.state:set('renewed_service', PlayerData.job.onduty and PlayerData.job.name or false, true)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(enabled)
    LocalPlayer.state:set('renewed_service', enabled and Player.job or false, true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    LocalPlayer.state:set('renewed_service', false, true)
    Controller.removePlayer()
end)