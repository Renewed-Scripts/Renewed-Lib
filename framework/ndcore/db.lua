local MySQL = MySQL

local GET_CHARNAME_IDENTIFIER = 'SELECT firstname, lastname FROM nd_characters WHERE charid = ?'
---Returns the full name of a character by their charId
---@param charId string
---@return string?
exports('getCharNameById', function(charId)
    local result = MySQL.single.await(GET_CHARNAME_IDENTIFIER, {charId})
    if result then
        return result.firstname .. ' ' .. result.lastname
    end
end)

local GET_OFFLINEMONEY = 'SELECT cash, bank FROM nd_characters WHERE charid = ?'
---Returns the money of a player by their charId
---@param charId string
---@return { bank: number, cash: number }?
exports('getOfflineMoney', function(charId)
    local result = MySQL.query.await(GET_OFFLINEMONEY, {charId})

    if result then
        return {bank = result.bank, cash = result.cash}
    end
end)

local ADD_OFFLINEMONEY = "UPDATE nd_characters SET %s = (%s + ?) WHERE charid = ?"
---Adds money to a player's account by their charId
---@param charId string
---@param amount number
---@param moneyType 'cash' | 'bank'
---@return QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }|nil}
exports('addOfflineMoney', function(charId, amount, moneyType)
    return MySQL.prepare.await((ADD_OFFLINEMONEY):format(moneyType, moneyType), {amount, charId})
end)

local REMOVE_OFFLINEMONEY = "UPDATE nd_characters SET %s = (%s - ?) WHERE charid = ?"
---Adds money to a player's account by their charId
---@param charId string
---@param amount number
---@param moneyType 'cash' | 'bank'
---@return QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }|nil}
exports('removeOfflineMoney', function(charId, amount, moneyType)
    return MySQL.prepare.await((REMOVE_OFFLINEMONEY):format(moneyType, moneyType), {amount, charId})
end)