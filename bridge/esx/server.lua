local ESX = exports.es_extended:getSharedObject()
local Players, Jobs = {}, {}

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
    value *= 10000
    TriggerClientEvent('esx_status:add', source, 'stress', value)
    TriggerClientEvent('HUD:Notification', source, 'Stress Gained', 'error', 1500)
end

function Renewed.relieveStress(source, value)
    value *= 10000
    TriggerClientEvent('HUD:Notification', source, 'Stress Relieved')
    TriggerClientEvent('esx_status:remove', source, 'stress', value)
end

function Renewed.isGroupAuth(job, grade)
    grade = tostring(grade)
    local numGrade = tonumber(grade)
    return Jobs[job].grades[grade] and Jobs[job].grades[grade].name == 'boss' or Jobs[job].grades[numGrade] and Jobs[job].grades[numGrade].name == 'boss'
end

function Renewed.getCharId(src)
    return Players[src] and Players[src].charId or false
end

function Renewed.getCharName(src)
    return Players[src] and Players[src].name or false
end

function Renewed.getCharNameById(identifier)
    local result = MySQL.prepare.await('SELECT firstname, lastname FROM users WHERE identifier = ?', {identifier})
    if not result then return false end
    local fullname = ("%s %s"):format(result.firstname, result.lastname)
    return fullname
end

-- Converting qb money to esx money --
local convertMoney = {
    ["cash"] = "money",
    ["bank"] = "bank"
}

function Renewed.getMoney(src, mType)
    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end
    mType = convertMoney[mType] or mType
    return Player.getAccount(mType).money
end

function Renewed.removeMoney(src, amount, mType, reason)
    if not Players[src] then return false end

    local type = convertMoney[mType] or mType

    local Player = ESX.GetPlayerFromId(src)
    if not Player then return false end

    if Player.getAccount(type).money < amount then return false end

    Player.removeAccountMoney(type, amount, reason)
    return true
end

function Renewed.addMoney(src, amount, mType, reason)
    if not Players[src] then return end

    local type = convertMoney[mType]
    if not type then return end

    local Player = ESX.GetPlayerFromId(src)
    if not Player then return end

    Player.addAccountMoney(type, amount, reason)

    return true
end

function Renewed.addNeeds(src, needs)
    if type(needs) ~= "table" then return end
    if not Players[src] then return end

    local hunger = needs.hunger * 10000 or 0
    local thirst = needs.thirst * 10000 or 0

    if hunger > 0 then
        TriggerClientEvent('esx_status:add', src, 'hunger', hunger)
    end

    if thirst > 0 then
        TriggerClientEvent('esx_status:add', src, 'thirst', thirst)
    end

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
AddEventHandler('esx:setJob', function(source, job, lastJob)
    local Player = Players[source]
    if not Player then return end

    TriggerEvent('Renewed-Lib:server:JobUpdate', source, lastJob.name, job.name, job.grade)

	Player.Groups[lastJob.name] = nil
	Player.Groups[job.name] = job.grade
end)

local function UpdatePlayerData(source)
    local Player = ESX.GetPlayerFromId(source)

    Players[source] = {
        Groups = {
            [Player.job.name] = Player.job.grade,
        },
        charId = Player.identifier,
        name = Player.name
    }

end

AddEventHandler('esx:playerLoaded', function(source)
    UpdatePlayerData(source)
    TriggerEvent('Renewed-Lib:server:playerLoaded', source, Players[source])
end)

CreateThread(function()
    Wait(250)
    ESX.RefreshJobs()
    Jobs = ESX.GetJobs()
    for _, sourceId in ipairs(GetPlayers()) do
        UpdatePlayerData(sourceId)
        Wait(69)
    end
end)

AddEventHandler('esx:playerDropped', function(source)
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
