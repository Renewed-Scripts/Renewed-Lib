local Players, Jobs, Gangs = {}, {}, {}

function Renewed.getGroups(src)
    return Players[src] and Players[src].Groups or false
end

function Renewed.hasGroup(src, group, grade)
    local Player = Players[src]

    if not Player then return false end
    if not Player.Groups[group] then return false end

    if grade then return Player.Groups[group] >= grade end

    return true
end

function Renewed.getPlayer(source)
    return Players[source]
end

function Renewed.addStress(source, value)
    local Player = exports.qbx_core:GetPlayer(source)
    local stress = (Player.PlayerData.metadata.stress or 0) + value

    Player.Functions.SetMetaData('stress', stress > 100 and 100 or stress)
    exports.qbx_core:Notify(source, "Stress Gained", 'error', 1500)
end

function Renewed.relieveStress(source, value)
    local Player = exports.qbx_core:GetPlayer(source)
    local stress = (Player.PlayerData.metadata.stress or 0) - value

    Player.Functions.SetMetaData('stress', stress < 0 and 0 or stress)
    exports.qbx_core:Notify(source, "Stress Relieved", 'error', 1500)
end


function Renewed.isGroupAuth(group, grade)
    grade = tostring(grade)
    local numGrade = tonumber(grade)
    local Group = Jobs[group] or Gangs[group]
    local auth = false
    if Group then
        auth = Group.grades[grade] and Group.grades[grade].isboss or Group.grades[numGrade] and Group.grades[numGrade].isboss
    end
    return auth
end

function Renewed.getCharId(src)
    return Players[src] and Players[src].charId or false
end

function Renewed.getCharName(src)
    return Players[src] and Players[src].name or false
end

local query = 'SELECT charinfo FROM players WHERE citizenid = ?'
function Renewed.getCharNameById(identifier)
    local charinfo = MySQL.prepare.await(query, {identifier})
    if not charinfo then return false end
    charinfo = json.decode(charinfo)
    local fullname = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
    return fullname
end

function Renewed.getMoney(src, mType)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    return Player.PlayerData.money[mType]
end
local GET_OFFLINEMONEY = 'SELECT money FROM players WHERE citizenid = ?'
function Renewed.getOfflineMoney(id)
    local result = MySQL.query.await(GET_OFFLINEMONEY, {id})
    if not result then return false end
    return {bank = result.bank, cash = result.cash}
end

function Renewed.removeMoney(src, amount, mType, reason)
    local Player = exports.qbx_core:GetPlayer(src)

    if not Player then return end

    if Player.PlayerData.money[mType] < amount then return end

    return Player.Functions.RemoveMoney(mType, amount, reason or "unknown")
end

function Renewed.addMoney(src, amount, mType, reason)
    local Player = exports.qbx_core:GetPlayer(src)

    if not Player then return end

    return Player.Functions.AddMoney(mType, amount, reason or "unknown")
end

local ADD_OFFLINEMONEY = "UPDATE players SET money = JSON_SET(money, CONCAT('$.', ?), JSON_UNQUOTE(JSON_EXTRACT(money, CONCAT('$.', ?))) + ?) WHERE citizenid = ?"
function Renewed.addOfflineMoney(identifier, amount, mType)
    return MySQL.prepare.await(ADD_OFFLINEMONEY, {mType, mType, amount, identifier})
end

local REMOVE_OFFLINEMONEY = "UPDATE players SET money = JSON_SET(money, CONCAT('$.', ?), JSON_UNQUOTE(JSON_EXTRACT(money, CONCAT('$.', ?))) - ?) WHERE citizenid = ?"
function Renewed.removeOfflineMoney(identifier, amount, mType)
    return MySQL.prepare.await(REMOVE_OFFLINEMONEY, {mType, mType, amount, identifier})
end

function Renewed.addNeeds(src, needs)
    if type(needs) ~= "table" then return end

    local Player = exports.qbx_core:GetPlayer(src)

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

function Renewed.getSourceByCharId(charId)
    for k, v in pairs(Players) do
        if v.charId == charId then
            return k
        end
    end

    return false
end

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
    Jobs = exports.qbx_core:GetJobs()
    Gangs = exports.qbx_core:GetGangs()
    for _, player in ipairs(exports.qbx_core:GetQBPlayers()) do
        UpdatePlayerData(player.PlayerData)
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
