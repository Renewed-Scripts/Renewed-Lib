---Notifies the client of a group
---@param payload NotifyProps
RegisterNetEvent('Renewed-Lib:NotifyGroup', function(payload)
    lib.notify(payload)
end)