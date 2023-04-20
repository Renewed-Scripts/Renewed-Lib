local QBCore = exports['qb-core']:GetCoreObject()
local Players = {}

function Renewed.hasGroup(src, group, grade)
    local Player = Players[src]

    if not Player then return false end
    if not Player.Groups[group] then return false end

    if grade then return Player.Groups[group] >= grade end

    return true
end

function Renewed.getCharId(src)
    return Players[src] and Players[src].charId or false
end

function Renewed.getCharName(src)
    return Players[src] and Players[src].name or false
end

function Renewed.removeMoney(src, amount, mType, reason)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.PlayerData.money[mType] < amount then return end

    return Player.Functions.RemoveMoney(mType, amount, reason or "unknown")
end

function Renewed.addMoney(src, amount, mType, reason)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    return Player.Functions.AddMoney(mType, amount, reason or "unknown")
end

function Renewed.addNeeds(src, needs)
    if type(needs) ~= "table" then return end

    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    needs.hunger = needs.hunger or 0
    needs.thirst = needs.thirst or 0

    local hunger = Player.PlayerData.metadata["hunger"] + needs.hunger
    local thirst = Player.PlayerData.metadata["thirst"] + needs.thirst

    if hunger > 100 then hunger = 100 end
    if thirst > 100 then thirst = 100 end

    Player.Functions.SetMetaData("hunger", hunger)
    Player.Functions.SetMetaData("thirst", thirst)

    TriggerClientEvent('hud:client:UpdateNeeds', src, hunger, thirst)

    return true
end



-- Group Updaters --
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local Player = Players[source]
    if not Player then return end

    Player.Groups[Player.job] = nil
    Player.Groups[job.name] = job.grade.level
    Player.job = job.name
end)

AddEventHandler('QBCore:Server:OnGangUpdate', function(source, job)
    local Player = Players[source]
    if not Player then return end

    Player.Groups[Player.gang] = nil
    Player.Groups[job.name] = job.grade.level
    Player.gang = job.name
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local PlayerData = Player.PlayerData
    Players[PlayerData.source] = {
        Groups = {
            [PlayerData.job.name] = PlayerData.job.grade.level,
            [PlayerData.gang.name] = PlayerData.gang.grade.level
        },
        job = PlayerData.job.name,
        gang = PlayerData.gang.name,
        charId = PlayerData.citizenid,
        name = ('%s %s'):format(PlayerData.charinfo.firstname, PlayerData.charinfo.lastname)
    }
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    if not Players[source] then return end
    Players[source] = nil
end)