local Controller = require 'framework.client'
local QBCore = exports['qb-core']:GetCoreObject()

-- Group Updaters --
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    local Player = Controller.getPlayer()

    if table.type(Player) == 'empty' then return end

    Player.Groups[Player.job] = nil
    Player.Groups[job.name] = job.grade.level
    Player.job = job.name

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Groups)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(job)
    local Player = Controller.getPlayer()

    if table.type(Player) == 'empty' then return end

    Player.Groups[Player.gang] = nil
    Player.Groups[job.name] = job.grade.level
    Player.gang = job.name

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Groups)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()

    Controller.createPlayer({
        Groups = {
            [PlayerData.job.name] = PlayerData.job.grade.level,
            [PlayerData.gang.name] = PlayerData.gang.grade.level
        },
        job = PlayerData.job.name,
        gang = PlayerData.gang.name,
        charId = PlayerData.citizenid,
        name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
    })

    LocalPlayer.state:set('renewed_service', PlayerData.job.onduty and PlayerData.job.name or false, true)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(enabled)
    local Player = Controller.getPlayer()

    if table.type(Player) ~= 'empty' then
        LocalPlayer.state:set('renewed_service', enabled and Player.job or false, true)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    LocalPlayer.state:set('renewed_service', false, true)
    Controller.removePlayer()
end)