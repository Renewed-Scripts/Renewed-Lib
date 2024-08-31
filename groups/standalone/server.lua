


---On standalone this will just trigger a single Group Evnet
---@param eventName string
---@param groupId number | string
---@param ... any
exports('TriggerGroupEvent', function(eventName, groupId, ...)
    TriggerClientEvent(eventName, groupId, ...)
end)

---On standalone groupId will be player source
---@param groupId number
---@return number[]
exports('GetGroupMembers', function(groupId)
    return { groupId }
end)

---On standalone we will just return the source
---@param source number
---@return number
exports('GetPlayerGroup', function(source)
    return source
end)

---On standalone we will just return the source
---@param source number
---@return boolean
exports('IsPlayerGroupLeader', function(source)
    return true
end)


---On standalone we will just trigger the notification on the source
---@param groupId number
---@param payload NotifyProps
exports('NotifyGroup', function(groupId, payload)
    TriggerClientEvent('Renewed-Lib:NotifyGroup', groupId, payload)
end)