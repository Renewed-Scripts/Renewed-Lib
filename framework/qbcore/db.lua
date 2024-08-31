local MySQL = MySQL

local GET_CHARNAME_IDENTIFIER = 'SELECT charinfo FROM players WHERE citizenid = ?'
---Returns the full name of a character by their charId
---@param charId string
---@return string?
exports('getCharNameById', function(charId)
    local result = MySQL.prepare.await(GET_CHARNAME_IDENTIFIER, {charId})

    if result then
        local charinfo = json.decode(result)
        return charinfo.firstname .. ' ' .. charinfo.lastname
    end
end)

local GET_OFFLINEMONEY = 'SELECT money FROM players WHERE citizenid = ?'
---Returns the money of a player by their charId
---@param charId string
---@return { bank: number, cash: number }?
exports('getOfflineMoney', function(charId)
    local result = MySQL.query.await(GET_OFFLINEMONEY, {charId})

    if result then
        return {bank = result.bank, cash = result.cash}
    end
end)

local ADD_OFFLINEMONEY = "UPDATE players SET money = JSON_SET(money, CONCAT('$.', ?), JSON_UNQUOTE(JSON_EXTRACT(money, CONCAT('$.', ?))) + ?) WHERE citizenid = ?"
---Adds money to a player's account by their charId
---@param charId string
---@param amount number
---@param moneyType 'cash' | 'bank'
---@return QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }|nil}
exports('addOfflineMoney', function(charId, amount, moneyType)
    return MySQL.prepare.await(ADD_OFFLINEMONEY, {moneyType, moneyType, amount, charId})
end)

local REMOVE_OFFLINEMONEY = "UPDATE players SET money = JSON_SET(money, CONCAT('$.', ?), JSON_UNQUOTE(JSON_EXTRACT(money, CONCAT('$.', ?))) - ?) WHERE citizenid = ?"
---Adds money to a player's account by their charId
---@param charId string
---@param amount number
---@param moneyType 'cash' | 'bank'
---@return QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }|nil}
exports('removeOfflineMoney', function(charId, amount, moneyType)
    return MySQL.prepare.await(REMOVE_OFFLINEMONEY, {moneyType, moneyType, amount, charId})
end)
