if not lib.checkDependency('ox_inventory', '2.37.3') then return end


local inventories = {}
local openedBy = {}
local shops = {}

local inventoryHook

local function addItemToSecondSlot(id, price, payload)
    SetTimeout(50, function()
        local addMoney = exports.ox_inventory:AddItem(id, 'money', price, nil, 1)

        if addMoney then
            exports.ox_inventory:RemoveItem(payload.fromInventory, payload.fromSlot.name, payload.count, payload.fromSlot.metadata, payload.fromSlot.slot)
            exports.ox_inventory:AddItem(id, payload.fromSlot.name, payload.count, payload.fromSlot.metadata, 2)

            inventories[id] += 1
            exports.ox_inventory:SetSlotCount(id, inventories[id])
        end
    end)
end

local function resetInventory(source, id)
    SetTimeout(100, function()
        local items = exports.ox_inventory:GetItems(id)
        exports.ox_inventory:ClearInventory(id)
        exports.ox_inventory:SetSlotCount(id, 2)
        inventories[id] = 2

        lib.logger(source, ('renewed_stashitems:%s'):format(id), items)
        TriggerEvent('Renewed-Lib:server:soldStashItems', source, id, items)
    end)
end

local function prepStash(id, label, weight)
    exports.ox_inventory:RegisterStash(id, label, 2, weight)
    exports.ox_inventory:ClearInventory(id, false)
end

local function deleteHook()
    exports.ox_inventory:removeHooks(inventoryHook)
    inventoryHook = nil
end

local function getInventoryArray()
    local ids = {}
    local amount = 0

    for k, _ in pairs(inventories) do
        amount += 1
        ids[amount] = k
    end

    return ids
end

local function createSaleStash(id, label, weight, items)
    if inventories[id] then
        return
    end

    inventories[id] = 2
    shops[id] = items

    prepStash(id, label, weight)

    if inventoryHook then
        deleteHook()
    end

    inventoryHook = exports.ox_inventory:registerHook('swapItems', function(payload)
        local source = payload.source
        local item = payload.fromSlot.name:lower()
        local addItem = inventories[payload.toInventory]
        local inventory = payload.toInventory == source and payload.fromInventory or payload.toInventory

        if item == 'money' and not addItem then
            resetInventory(source, inventory)
            return true
        end

        if payload.action ~= 'move' then
            return false
        end

        local price = shops?[inventory]?[item]
        if not price or openedBy[inventory] ~= source then
            return false
        end

        price *= payload.count

        local slotCount = inventories[inventory]

        if addItem then
            if payload.toSlot == 1 then
                addItemToSecondSlot(inventory, price, payload)

                return false
            else
                local added = exports.ox_inventory:AddItem(inventory, 'money', price, nil, 1)

                if added then
                    slotCount += 1
                    exports.ox_inventory:SetSlotCount(inventory, slotCount)

                    inventories[inventory] = slotCount
                end

                return added
            end
        elseif payload.fromSlot.slot > 1 and payload.fromSlot.slot == slotCount-1 then
            local removed = exports.ox_inventory:RemoveItem(inventory, 'money', price, nil, 1)

            if removed then
                slotCount -= 1
                exports.ox_inventory:SetSlotCount(inventory, slotCount)

                inventories[inventory] = slotCount
            end

            return removed
        end

        return false
    end, {
        inventoryFilter = getInventoryArray()
    })
end exports('CreateSaleStash', createSaleStash)


AddEventHandler('ox_inventory:openedInventory', function(playerId, inventoryId)
    if inventories[inventoryId] and not openedBy[inventoryId] then
        openedBy[inventoryId] = playerId
    end
end)

AddEventHandler('ox_inventory:closedInventory', function(playerId, inventoryId)
    if openedBy[inventoryId] == playerId then
        openedBy[inventoryId] = nil
    end
end)


AddEventHandler('Renewed-Lib:server:playerRemoved', function(playerId)
    for inventory, source in pairs(openedBy) do
        if source == playerId then
            openedBy[inventory] = nil
        end
    end
end)