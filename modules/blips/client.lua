local blips_class = require 'classes.blips'

---@type table <number, renewed_blips>
local blips = {}

---adds a blips to the blips list
---@param payload renewed_blips
exports('addBlip', function(payload)
    -- If table is not an array we convert it into one
    payload = table.type(payload) == 'array' and payload or {payload}

    for i = 1, #payload do
        local data = payload[i]

        data.resource = GetInvokingResource() or cache.resource

        ---@diagnostic disable-next-line: invisible
        local blip = blips_class:new(data)

        blip:createBlip()

        blips[#blips+1] = blip
    end
end)

---Get the blip from the ID
---@param id number | string
---@return renewed_blips?
local function getBlip(id)
    if not id then return end

    for i = #blips, 1, -1 do
        local blip = blips[i]

        if blip.id and blip.id == id then
            return blip
        end
    end
end

---Hides the blip from the map
---@param id number | string
exports('hideblip', function(id)
    local blip = getBlip(id)

    if blip then
        blip:removeBlip()
    end
end)

---Shows the blip on the map
---@param id number | string
exports('showBlip', function(id)
    local blip = getBlip(id)

    if blip then
        blip:createBlip()
    end
end)

---Removes the blip from the map
---@param id number | string
exports('removeBlip', function(id)
    if not id then return end

    for i = #blips, 1, -1 do
        local blip = blips[i]

        if blip.id and blip.id == id then
            blip:removeBlip()
            table.remove(blips, i)
            break
        end
    end
end)

---Changes the label of a blip
---@param id number | string
---@param label string
exports('setBlipLabel', function(id, label)
    if not label then return end

    local blip = getBlip(id)

    if blip then
        blip:setLabel(label)
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    for i = #blips, 1, -1 do
        local blip = blips[i]

        if blip.resource == resourceName then
            blip:removeBlip()
            table.remove(blips, i)
        end
    end
end)