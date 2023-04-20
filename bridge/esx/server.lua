local ESX = exports.es_extended:getSharedObject()
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

-- Converting qb money to esx money --
local convertMoney = {
    ["cash"] = "money",
    ["bank"] = "bank"
}

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

    local hunger = needs.hunger * 1000 or 0
    local thirst = needs.thirst * 1000 or 0

    if hunger > 0 then
        TriggerClientEvent('esx_status:add', src, 'hunger', hunger)
    end

    if thirst > 0 then
        TriggerClientEvent('esx_status:add', src, 'thirst', thirst)
    end

    return true
end


-- Group Updaters --
AddEventHandler('esx:setJob', function(source, job, lastJob)
    local Player = Players[source]
    if not Player then return end
	Player.groups[lastJob.name] = nil
	Player.groups[job.name] = job.grade
end)

AddEventHandler('esx:playerLoaded', function(source)
    local Player = ESX.GetPlayerFromId(source)

    Players[PlayerData.source] = {
        Groups = {
            [Player.job.name] = Player.job.grade,
        },
        charId = Player.identifier,
        name = Player.name
    }
end)

AddEventHandler('esx:playerDropped', function(source)
    if not Players[source] then return end
    Players[source] = nil
end)