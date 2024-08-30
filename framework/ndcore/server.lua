local Controller = require 'framework.server'

NDCore = {}

lib.load('@ND_Core.init')

---Adds stress to a player by their source
---@param source number
---@param value number
exports('addStress', function(source, value)
    local player = NDCore.getPlayer(source)

    local statuses = player.getMetadata("status")
    local stressStatus = statuses?.stress or { -- ND_Status doesnt ship with stress by default, create default metadata table
        type = 'stress',
        max = 100.0,
        status = 0
    }

    stressStatus.status = (stressStatus.status + value)

    player.setMetadata("status", {
        stress = stressStatus
    })

    TriggerClientEvent('ND_Status:setStatuses', source, {
        stress = stressStatus.status,
    })

    player.notify({
        title = "Stress Gained",
        type = "error",
        duration = 1500
    })
end)


---Relieves stress from a player by their source
---@param source number
---@param value number
exports('relieveStress', function(source, value)
    local player = NDCore.getPlayer(source)
    local statuses = player.getMetadata("status")
    local stressStatus = statuses?.stress or { -- ND_Status doesnt ship with stress by default, create default metadata table
        type = 'stress',
        max = 100.0,
        status = 0
    }

    stressStatus.status = (stressStatus.status - value)

    player.setMetadata("status", {
        stress = stressStatus
    })

    player.notify({
        title = "Stress Relieved",
        type = "success",
        duration = 1500
    })

    TriggerClientEvent('ND_Status:setStatuses', source, {
        stress = stressStatus.status,
    })
end)

-- Default ND money types
local allowedMoneyTypes = {
    ['cash'] = true,
    ['bank'] = true
}

---Returns the amount of money a player has by their source
---@param source number
---@param moneyType 'cash' | 'bank'
---@return number?
exports('getMoney', function(source, moneyType)
    local Player = NDCore.getPlayer(source)

    if Player then
        return allowedMoneyTypes[moneyType] and Player[moneyType] or nil
    end
end)


---Removes money from a player's account by their source
---@param source number
---@param amount number
---@param moneyType 'cash' | 'bank'
---@param reason string?
---@return boolean
exports('removeMoney', function(source, amount, moneyType, reason)
    local Player = NDCore.getPlayer(source)

    if Player and (allowedMoneyTypes[moneyType] and Player[moneyType] or 0) >= amount then
        return Player.deductMoney(moneyType, amount, reason or "unknown")
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
    local Player = NDCore.getPlayer(source)

    if Player and (allowedMoneyTypes[moneyType] and Player[moneyType] or 0) >= amount then
        return Player.addMoney(moneyType, amount, reason or "unknown")
    end

    return false
end)

---Adds needs (hunger, thirst) to a player, returns true/false depending on success and reason why it failed
---@param source number
---@param needs { hunger: number, thirst: number }
---@return boolean?
---@return string?
exports('addNeeds', function(source, needs)
    if type(needs) ~= "table" then return end

    local player = NDCore.getPlayer(source)

    if not player then return end

    needs.hunger = needs.hunger or 0
    needs.thirst = needs.thirst or 0

    local statuses = player.getMetadata("status")
    local hungerStatus, thirstStatus = statuses.hunger, statuses.thirst

    local hunger = hungerStatus.status + needs.hunger
    local thirst = thirstStatus.status + needs.thirst

    if hunger > hungerStatus.max then hunger = hungerStatus.max end
    if thirst > thirstStatus.max then thirst = thirstStatus.max end

    statuses.hunger.status = hunger
    statuses.thirst.status = thirst

    player.setMetadata("status", {
        hunger = statuses.hunger,
        thirst = statuses.thirst
    })

    TriggerClientEvent('ND_Status:setStatuses', source, {
        hunger = statuses.hunger.status,
        thirst = statuses.thirst.status
    })

    return true
end)

-- Group Updaters --
local function convertNDGroups(groups)
    local converted = {}
    for groupName, groupInfo in pairs(groups) do
        converted[groupName] = groupInfo.rank
    end
    return converted
end

AddEventHandler('ND:updateCharacter', function(PlayerData, updateType)
    local Player = Controller.getPlayer(PlayerData.source)

    if Player then
        if updateType == "job" and Player.job ~= PlayerData.job then
            Player.job = PlayerData.job
            TriggerEvent('Renewed-Lib:server:JobUpdate', PlayerData.source, Player.job, PlayerData.job, PlayerData.jobInfo.rank)
        end

        if updateType == "groups" then
            Player.Groups = convertNDGroups(Player.groups)
        end
    end
end)

AddEventHandler('ND:groupRemoved', function(PlayerData, removedGroup)
    local Player = Controller.getPlayer(PlayerData.source)

    if Player then
        if Player.Groups[removedGroup] then
            Player.Groups[removedGroup] = nil
        end
    end
end)

AddEventHandler('ND:characterLoaded', function(PlayerData)
    local playerGroups = convertNDGroups(PlayerData.groups)

    Controller.createPlayer({
        Groups = playerGroups,
        job = PlayerData.job,
        charId = PlayerData.id,
        name = PlayerData.fullname,
        source = PlayerData.source
    })
end)


AddEventHandler('ND:characterUnloaded', Controller.removePlayer)

require 'framework.ndcore.db'