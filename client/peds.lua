local Peds = {}

local CreatePed = CreatePed
local GetEntityCoords = GetEntityCoords
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local DeleteEntity = DeleteEntity
local GetInvokingResource = GetInvokingResource
local DoesEntityExist = DoesEntityExist

local function spawnPed(payload)
    if not payload.coords or not payload.model then return end

    lib.requestModel(payload.model, 1000)

    local ped = CreatePed(0, payload.model, payload.coords.x, payload.coords.y, payload.coords.z, payload.heading, false, true)

    if payload.freeze then
        FreezeEntityPosition(ped, true)
    end

    if payload.invincible then
        SetEntityInvincible(ped, true)
    end

    if payload.tempevents then
        SetBlockingOfNonTemporaryEvents(ped, true)
    end

    if payload.animDict and payload.animName then
        lib.playAnim(ped, payload.animDict, payload.animName, 8.0, 0, -1, 1, 0, 0, 0)
    end

    if payload.scenario then
        TaskStartScenarioInPlace(ped, payload.scenario, 0, true)
    end

    if payload.target then
        exports.ox_target:addLocalEntity(ped, payload.target)
    elseif payload.interact then
        payload.interact.entity = ped
        exports.interact:AddLocalEntityInteraction(payload.interact)
    end

    SetModelAsNoLongerNeeded(payload.model)

    return ped
end

function RenewedLib.addPed(payload)
    payload = table.type(payload) == 'array' and payload or { payload }

    local pedSize = #Peds
    local resource = GetInvokingResource()
    local pCoords = GetEntityCoords(cache.ped)

    for i = 1, #payload do
      local item = payload[i]

      if item.coords and item.model then
        if #(pCoords - item.coords) < item.dist then
            item.spawned = spawnPed(item)
        end

        item.resource = resource

        pedSize += 1
        Peds[pedSize] = item
      end
    end
end

local function deletePed(entity, target, interact)
    if not entity then return end
    if entity == 0 then return end
    if not DoesEntityExist(entity) then return end

    if target then
        for i = 1, #target do
            exports.ox_target:removeLocalEntity(entity, target[i]?.name)
        end
    elseif interact then
        exports.interact:RemoveLocalEntityInteraction(entity, interact?.id)
    end

    SetEntityAsMissionEntity(entity, false, true)
    DeleteEntity(entity)
end

function RenewedLib.removePed(id)
    if not id then return end

    for i = 1, #Peds do
        local item = Peds[i]
        if item.id == id then
            if item.spawned then
                deletePed(item.spawned, item.target, item.interact)
            end
            table.remove(Peds, i)
            break
        end
    end
end

function RenewedLib.setPedCoords(id, coords, heading)
    if not id then return end

    for i = 1, #Peds do
        local item = Peds[i]
        if item.id == id then
            item.coords = coords
            item.heading = heading

            if item.spawned then
                SetEntityCoords(item.spawned, coords.x, coords.y, coords.z, false, false, false, false)
                SetEntityHeading(item.spawned, heading)
            end
            break
        end
    end
end

function Renewed.getPedById(id)
    if not id then return end

    for i = 1, #Peds do
        local item = Peds[i]
        if item.spawned and item.id == id then
            return item.spawned
        end
    end
end

function Renewed.removeResourcePed(resource)
    resource = resource or GetInvokingResource() or cache.resource

    for i = #Peds, 1, -1 do

        local item = Peds[i]
        if item.resource == resource then
            if item.spawned then
                deletePed(item.spawned, item.target, item.interact)
            end
            table.remove(Peds, i)
        end
    end
end

AddEventHandler('onClientResourceStop', function(resource)
    for i = #Peds, 1, -1 do
        local item = Peds[i]

        if item.resource == resource then
            if item.spawned then
                deletePed(item.spawned, item.target, item.interact)
            end
            table.remove(Peds, i)
        end
    end
end)

CreateThread(function()
    while true do
        local pCoords = GetEntityCoords(cache.ped)
        local pedCount = #Peds

        for i = 1, pedCount do
            local item = Peds[i]
            local isClose = #(pCoords - item.coords) < item.dist

            if item.spawned and not isClose then
                deletePed(item.spawned, item.target, item.interact)
                item.spawned = false
                Wait(0)
            elseif not item.spawned and isClose then
                item.spawned = spawnPed(item)
                Wait(0)
            end
        end

        Wait(5000)
    end
end)
