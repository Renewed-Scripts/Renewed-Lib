---On standalone this will just trigger a single Group Evnet
---@param eventName string
---@param source number
---@param ... any
exports('TriggerGroupEvent', function(eventName, source, ...)
    TriggerClientEvent(eventName, source, ...)
end)

---On standalone we will trigger a notification on the source
---@param source number
---@param status {name: string, isDone: boolean, id: string}[]
exports('setJobStatus', function(source, status)
    for i = 1, #status do
        local currentStatus = status[i]

        if not currentStatus.isDone then
            TriggerClientEvent('Renewed-Lib:JobStatus', source, currentStatus.name)
            break
        end
    end
end)

---On standalone groupId will be player source
---@param source number
---@return number[]
exports('GetGroupMembers', function(source)
    return { source }
end)

---On standalone we will just return the source
---@param source number
---@return number
exports('GetPlayerGroup', function(source)
    return source
end)

---On standalone we will just return the source
---@return boolean
exports('IsPlayerGroupLeader', function()
    return true
end)

---On standalone we will just trigger the notification on the source
---@param source number
---@param payload NotifyProps
exports('NotifyGroup', function(source, payload)
    TriggerClientEvent('Renewed-Lib:NotifyGroup', source, payload)
end)