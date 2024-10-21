assert(lib.checkDependency('qbx_core', '1.17.2'), 'qbx_core v1.17.2 or higher is required to use this script')

local Controller = require 'framework.client'

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
        job = PlayerData.job.name,
        gang = PlayerData.gang.name,
        charId = PlayerData.citizenid,
        name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
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