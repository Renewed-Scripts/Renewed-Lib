local Ox = require '@ox_core.lib.init'


local Controller = require 'framework.server'

---Adds stress to a player by their source
---@param source number
---@param value number
exports('addStress', function(source, value)
    local player = Ox.GetPlayer(source)

    if player and player.charId then
        player.addStatus('stress', value)
    end
end)

---Relieves stress from a player by their source
---@param source number
---@param value number
exports('relieveStress', function(source, value)
    local player = Ox.GetPlayer(source)

    if player and player.charId then
        player.removeStatus('stress', value)
    end
end)

---Removes money from a player's account by their source
---@param source number
---@param amount number
---@param moneyType 'cash' | 'bank'
---@param reason string?
---@return boolean
exports('removeMoney', function(source, amount, moneyType, reason)
    if moneyType == 'bank' then
        local account = Ox.GetCharacterAccount(source)

        if account then
            return account.removeBalance({
                amount = amount,
                message = reason,
                overdraw = false
              }).success
        end
    else
        return exports.ox_inventory:RemoveItem(source, 'money', amount)
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
    if moneyType == 'bank' then
        local account = Ox.GetCharacterAccount(source)

        if account then
            return account.addBalance({
                amount = amount,
                message = reason
              }).success
        end
    else
        return exports.ox_inventory:AddItem(source, 'money', amount)
    end

    return false
end)

AddEventHandler('ox:playerLoaded', function(source)
    local Player = Ox.GetPlayer(source)

    if Player then
        Controller.createPlayer({
            Groups = Player.getGroups(),
            charId = Player.stateId,
            name = Player.get('fullName'),
        })
    end
end)

AddEventHandler('ox:playerLogout', Controller.removePlayer)