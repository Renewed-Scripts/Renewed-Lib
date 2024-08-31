local MySQL = MySQL


local GET_CHARINFO = 'SELECT firstname, lastname FROM users WHERE identifier = ?'
---Returns the full name of a character by their charId
---@param charId string
---@return string?
exports('getCharNameById', function(charId)
    local result = MySQL.prepare.await(GET_CHARINFO, {charId})

    if result then
        return result.firstname .. ' ' .. result.lastname
    end
end)

local GET_OFFLINEMONEY = 'SELECT accounts FROM users WHERE identifier = ?'
---Returns the money of a player by their charId
---@param charId string
---@return { bank: number, cash: number }?
exports('getOfflineMoney', function(charId)
    local result = MySQL.query.await(GET_OFFLINEMONEY, {charId})

    if result then
        return {bank = result.bank, cash = result.money}
    end
end)

local convertMoney = {
    cash = 'money',
    bank = 'bank'
}

local ADD_OFFLINEMONEY = "UPDATE users SET accounts = JSON_SET(accounts, CONCAT('$.', ?), JSON_UNQUOTE(JSON_EXTRACT(accounts, CONCAT('$.', ?))) + ?) WHERE identifier = ?"
---Adds money to a player's account by their charId
---@param charId string
---@param amount number
---@param moneyType 'cash' | 'bank'
---@return QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }|nil}
exports('addOfflineMoney', function(charId, amount, moneyType)
    local _type = convertMoney[moneyType] or moneyType
    return MySQL.prepare.await(ADD_OFFLINEMONEY, {_type, _type, amount, charId})
end)

local REMOVE_OFFLINEMONEY = "UPDATE users SET accounts = JSON_SET(accounts, CONCAT('$.', ?), JSON_UNQUOTE(JSON_EXTRACT(accounts, CONCAT('$.', ?))) - ?) WHERE identifier = ?"
---Adds money to a player's account by their charId
---@param charId string
---@param amount number
---@param moneyType 'cash' | 'bank'
---@return QueryResult|unknown|{ [number]: { [string]: unknown  }|{ [string]: unknown }|nil}
exports('removeOfflineMoney', function(charId, amount, moneyType)
    local _type = convertMoney[moneyType] or moneyType
    return MySQL.prepare.await(REMOVE_OFFLINEMONEY, {_type, _type, amount, charId})
end)