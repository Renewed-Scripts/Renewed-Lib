local QBCore = exports['qb-core']:GetCoreObject()

local Player = {}

function Renewed.getPlayerGroup()
    return Player and Player.Group or {}
end

function Renewed.getCharId()
    return Player and Player.charId
end

-- Group Updaters --
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not Player.Group then return end

    Player.Group[Player.job] = nil
    Player.Group[job.name] = job.grade.level
    Player.job = job.name

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Group)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(job)
    if not Player.Group then return end

    Player.Group[Player.gang] = nil
    Player.Group[job.name] = job.grade.level
    Player.gang = job.name

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Group)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    Player = {
        Group = {
            [PlayerData.job.name] = PlayerData.job.grade.level,
            [PlayerData.gang.name] = PlayerData.gang.grade.level
        },
        job = PlayerData.job.name,
        gang = PlayerData.gang.name,
        charId = PlayerData.citizenid,
        name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)
    }

    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Player = table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)
