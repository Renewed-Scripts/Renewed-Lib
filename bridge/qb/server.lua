local QBCore = exports['qb-core']:GetCoreObject()
local Players, Jobs, Gangs = {}, {}, {}

function RenewedLib.getGroups(src)
    return Players[src] and Players[src].Groups or false
end exports('getGroups', RenewedLib.getGroups)

function RenewedLib.hasGroup(src, group, grade)
    local Player = Players[src]

    if not Player then return false end
    if not Player.Groups[group] then return false end

    if grade then return Player.Groups[group] >= grade end

    return true
end exports('hasGroup', RenewedLib.hasGroup)

function RenewedLib.getPlayer(source)
    return Players[source]
end exports('getPlayer', RenewedLib.getPlayer)

function RenewedLib.addStress(source, value)
    local Player = QBCore.Functions.GetPlayer(source)
    local stress = (Player.PlayerData.metadata.stress or 0) + value

    Player.Functions.SetMetaData('stress', stress > 100 and 100 or stress)
    TriggerClientEvent('hud:client:UpdateStress', source, stress)
    TriggerClientEvent('QBCore:Notify', source, "Stress Gained", 'error', 1500)
end exports('addStress', RenewedLib.addStress)

function RenewedLib.relieveStress(source, value)
    local Player = QBCore.Functions.GetPlayer(source)
    local stress = (Player.PlayerData.metadata.stress or 0) - value

    Player.Functions.SetMetaData('stress', stress < 0 and 0 or stress)
    TriggerClientEvent('hud:client:UpdateStress', source, stress)
    TriggerClientEvent('QBCore:Notify', source, "Stress Relieved", 'error', 1500)
end exports('relieveStress', RenewedLib.relieveStress)


function RenewedLib.isGroupAuth(group, grade)
    grade = tostring(grade)
    local numGrade = tonumber(grade)
    local Group = Jobs[group] or Gangs[group]
    local auth = false
    if Group then
        auth = Group.grades[grade] and Group.grades[grade].isboss or Group.grades[numGrade] and Group.grades[numGrade].isboss
    end
    return auth
end exports('isGroupAuth', RenewedLib.isGroupAuth)

function RenewedLib.getCharId(src)
    return Players[src] and Players[src].charId or false
end exports('getCharId', RenewedLib.getCharId)

function RenewedLib.getCharName(src)
    return Players[src] and Players[src].name or false
end exports('getCharName', RenewedLib.getCharName)

local query = 'SELECT charinfo FROM players WHERE citizenid = ?'
function RenewedLib.getCharNameById(identifier)
    local charinfo = MySQL.prepare.await(query, {identifier})
    if not charinfo then return false end
    charinfo = json.decode(charinfo)
    local fullname = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
    return fullname
end exports('getCharNameById', RenewedLib.getCharNameById)

function RenewedLib.getMoney(src, mType)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    return Player.PlayerData.money[mType]
end exports('getMoney', RenewedLib.getMoney)

function RenewedLib.removeMoney(src, amount, mType, reason)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.PlayerData.money[mType] < amount then return end

    return Player.Functions.RemoveMoney(mType, amount, reason or "unknown")
end exports('removeMoney', RenewedLib.removeMoney)

function RenewedLib.addMoney(src, amount, mType, reason)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    return Player.Functions.AddMoney(mType, amount, reason or "unknown")
end exports('addMoney', RenewedLib.addMoney)

function RenewedLib.addNeeds(src, needs)
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
end exports('addNeeds', RenewedLib.addNeeds)

function RenewedLib.getSourceByCharId(charId)
    for k, v in pairs(Players) do
        if v.charId == charId then
            return k
        end
    end

    return false
end exports('getSourceByCharId', RenewedLib.getSourceByCharId)

-- Group Updaters --
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local Player = Players[source]
    if not Player then return end

    TriggerEvent('Renewed-Lib:server:JobUpdate', source, Player.job, job.name, job.grade.level)

    Player.Groups[Player.job] = nil
    Player.Groups[job.name] = job.grade.level
    Player.job = job.name
end)

AddEventHandler('QBCore:Server:OnGangUpdate', function(source, job)
    local Player = Players[source]
    if not Player then return end

    TriggerEvent('Renewed-Lib:server:JobUpdate', source, Player.gang, job.name, job.grade.level)

    Player.Groups[Player.gang] = nil
    Player.Groups[job.name] = job.grade.level
    Player.gang = job.name
end)

local function UpdatePlayerData(PlayerData)
    local renewedJobs
    local _ = pcall(function() renewedJobs = exports['qb-phone']:getJobs(PlayerData.citizenid) end)
    if renewedJobs then
        PlayerData.renewedJobs = renewedJobs
    end

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

    if PlayerData.renewedJobs then
        for k,v in pairs(PlayerData.renewedJobs) do
            if k ~= Players[PlayerData.source].job then
                Players[PlayerData.source].Groups[k] = v.grade
            end
        end
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    UpdatePlayerData(Player.PlayerData)

    TriggerEvent('Renewed-Lib:server:playerLoaded', Player.PlayerData.source, Players[Player.PlayerData.source])
end)


CreateThread(function()
    Wait(250)
    Jobs = QBCore.Shared.Jobs
    Gangs = QBCore.Shared.Gangs
    for _, sourceId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(sourceId))
        if not Player then return end
        UpdatePlayerData(Player.PlayerData)
        Wait(69)
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    if Players[source] then
        TriggerEvent('Renewed-Lib:server:playerRemoved', source, Players[source])
        Players[source] = nil
    end
end)

AddEventHandler('playerDropped', function()
    if Players[source] then
        TriggerEvent('Renewed-Lib:server:playerRemoved', source, Players[source])
        Players[source] = nil
    end
end)
