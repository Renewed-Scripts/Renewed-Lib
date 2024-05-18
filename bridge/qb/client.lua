local QBCore = exports['qb-core']:GetCoreObject()

local Player = {}
local playerState = LocalPlayer.state

local CopCount = 0

exports('GetCopCount', function()
    return CopCount
end)

function RenewedLib.getPlayerGroup()
    return Player and Player.Group or {}
end exports('GetPlayerGroup', RenewedLib.getPlayerGroup)

function RenewedLib.getCharId()
    return Player and Player.charId
end exports('GetCharId', RenewedLib.getCharId)

-- Group Updaters --
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not Player.Group then return end

    Player.Group[Player.job] = nil
    Player.Group[job.name] = job.grade.level

    if Player.job == playerState.renewed_service then
        playerState:set('renewed_service', false, true)
    end

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

    playerState:set('renewed_service', PlayerData.job.onduty and PlayerData.job.name or false, true)
    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(enabled)
    playerState:set('renewed_service', enabled and Player.job or false, true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    playerState:set('renewed_service', false, true)
    Player = table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)

RegisterNetEvent('police:SetCopCount', function(amount)
    if CopCount and type(CopCount) == 'number' then
        CopCount = amount
    end
end)
