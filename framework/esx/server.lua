local Controller = require 'framework.server'
local ESX = exports.es_extended:getSharedObject()

---Adds stress to a player by their source
---@param source number
---@param value number
exports('addStress', function(source, value)
    value *= 10000
    TriggerClientEvent('esx_status:add', source, 'stress', value)
    TriggerClientEvent('HUD:Notification', source, 'Stress Gained', 'error', 1500)
end)


---Relieves stress from a player by their source
---@param source number
---@param value number
exports('relieveStress', function(source, value)
    value *= 10000
    TriggerClientEvent('HUD:Notification', source, 'Stress Relieved')
    TriggerClientEvent('esx_status:remove', source, 'stress', value)
end)


-- Converting qb money to esx money --
local convertMoney = {
    cash = 'money',
    bank = 'bank'
}

---Returns the amount of money a player has by their source
---@param source number
---@param moneyType 'cash' | 'bank'
---@return number?
exports('getMoney', function(source, moneyType)
    local Player = ESX.GetPlayerFromId(source)

    if Player then
        local _type = convertMoney[moneyType]

        if _type then
            return Player.getAccount(_type).money
        end
    end
end)

---Removes money from a player's account by their source
---@param source number
---@param amount number
---@param moneyType 'cash' | 'bank'
---@param reason string?
---@return boolean
exports('removeMoney', function(source, amount, moneyType, reason)
    local type = convertMoney[moneyType]
    local Player = ESX.GetPlayerFromId(source)

    if Player and type and Player.getAccount(type).money >= amount then
        Player.removeAccountMoney(type, amount, reason)
        return true
    end

    return false
end)


---Adds money to a player's account by their source
---@param source number
---@param amount number
---@param moneyType 'cash' | 'bank'
---@param reason string?
---@return boolean
exports('addMoney', function(source, amount, moneyType, reason)
    local Player = ESX.GetPlayerFromId(source)

    if Player then
        local type = convertMoney[moneyType]

        if not type then return false end

        Player.addAccountMoney(type, amount, reason)

        return true
    end

    return false
end)


---Adds needs (hunger, thirst) to a player, returns true/false depending on success and reason why it failed
---@param source number
---@param needs { hunger: number, thirst: number }
---@return boolean
---@return string?
exports('addNeeds', function(source, needs)
    if type(needs) ~= 'table' then return false end

    if DoesPlayerExist(source) then
        local hunger = needs.hunger * 10000 or 0
        local thirst = needs.thirst * 10000 or 0

        if hunger > 0 then
            TriggerClientEvent('esx_status:add', source, 'hunger', hunger)
        end

        if thirst > 0 then
            TriggerClientEvent('esx_status:add', source, 'thirst', thirst)
        end

        return true
    end

    return false
end)


-- Group Updaters --
AddEventHandler('esx:setJob', function(source, job, lastJob)
    local Player = Controller.getPlayer(source)

    if Player then
        TriggerEvent('Renewed-Lib:server:JobUpdate', source, lastJob.name, job.name, job.grade)

        Player.Groups[lastJob.name] = nil
        Player.Groups[job.name] = job.grade
    end
end)

AddEventHandler('esx:playerLoaded', function(source)
    local Player = ESX.GetPlayerFromId(source)

    Controller.createPlayer({
        Groups = {
            [Player.job.name] = Player.job.grade,
        },
        charId = Player.identifier,
        name = Player.name,
        source = source
    })
end)

AddEventHandler('esx:playerDropped', Controller.removePlayer)

require 'framework.esx.db'