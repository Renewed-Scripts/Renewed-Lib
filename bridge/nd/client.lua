if not lib.checkDependency('ND_Core', '2.0.0') then return end

NDCore = {}

lib.load('@ND_Core.init')

local Player = {}

function RenewedLib.getPlayerGroup()
    return Player and Player.Group or {}
end exports('GetPlayerGroup', RenewedLib.getPlayerGroup)

function RenewedLib.getCharId()
    return Player and Player.charId
end exports('GetCharId', RenewedLib.getCharId)

-- Group Updaters --
RegisterNetEvent('ND:updateCharacter', function(PlayerData)
    if not Player.Group then return end

    for job, info in pairs(PlayerData.groups) do
        Player.Group[job] = info.rank
    end

    TriggerEvent('Renewed-Lib:client:UpdateGroup', Player.Group)
end)

RegisterNetEvent('ND:characterLoaded', function()
    local PlayerData = NDCore.getPlayer()

    local playerGroups = {}
    for job, info in pairs(PlayerData.groups) do
        playerGroups[job] = info.rank
    end

    Player = {
        Group = playerGroups,
        job = PlayerData.job,
        charId = PlayerData.identifier,
        name = PlayerData.fullname
    }

    -- TODO: ADD DUTY STATE
    TriggerEvent('Renewed-Lib:client:PlayerLoaded', Player)
end)

RegisterNetEvent('ND:characterUnloaded', function()
    LocalPlayer.state:set('renewed_service', false, true)
    Player = table.wipe(Player)
    TriggerEvent('Renewed-Lib:client:PlayerUnloaded')
end)