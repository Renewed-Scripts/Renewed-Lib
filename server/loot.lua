--- Loot Tables
local lootTables = {}

---register loot table
---@param id string
---@param data table
local function registerLootTable(id, data)
    if not id or not data then return end

    data = table.type(data) == 'array' and data or { data }

    table.sort(data, function(a, b)
        return a.chance < b.chance
    end)

    lootTables[id] = data
end exports('RegisterLootTable', registerLootTable)

---Get the amount of items the player should recieve
---@param item table
---@return integer
local function getAmount(item)
    return item.amount or (item.min and item.max and math.random(item.min, item.max)) or 1
end

---Generate loot
---@param id string
---@param maxLoot integer
---@return table | boolean
local function generateLoot(id, minLoot, maxLoot)
    if not lootTables[id] then
        error('Invalid loot table ID:' .. tostring(id))
    end

    local rewards = lootTables[id]

    if not next(rewards) then
        return false
    end

    local loot = {}
    local lootAmount = 0

    for i = 1, #rewards do
        local item = rewards[i]
        local chance = math.random()

        if chance <= item.chance then
            local amount = getAmount(item)

            if amount and amount > 0 then
                lootAmount += 1
                loot[item.name] = {
                    amount = amount,
                    metadata = item.metadata or nil
                }

                if maxLoot and lootAmount >= maxLoot then
                    break
                end
            end
        end
    end

    if minLoot and lootAmount < minLoot then
        return generateLoot(id, minLoot, maxLoot)
    end

    return loot
end exports('GenerateLoot', generateLoot)