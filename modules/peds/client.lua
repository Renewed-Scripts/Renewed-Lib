local pedClass = require 'classes.peds'

---@type table<number, CPoint>
local Peds = {}

local playerInstance = LocalPlayer.state.instance or 0
local useInteract = GetConvar('renewed_useinteract', 'false') == 'true'
local requestTimeouts = GetConvarInt('renewed_requesttimeouts', 10000)

---Spawns the ped on enter
---@param self renewed_peds
local function spawnPed(self)
    lib.requestModel(self.model, requestTimeouts)

    local ped = CreatePed(0, self.model, self.coords.x, self.coords.y, self.coords.z, self.heading, false, true)

    FreezeEntityPosition(ped, self.freeze)
    SetEntityInvincible(ped, self.invincible)
    SetBlockingOfNonTemporaryEvents(ped, self.tempevents)

    if self.animDict and self.animName then
        lib.requestAnimDict(self.animDict, requestTimeouts)
        TaskPlayAnim(ped, self.animDict, self.animName, 8.0, 0, -1, 1, 0, 0, 0)
        RemoveAnimDict(self.animDict)
    end

    if self.scenario then
        TaskStartScenarioInPlace(ped, self.scenario, 0, true)
    end

    if self.target then
        exports.ox_target:addLocalEntity(ped, self.target)
    end

    if useInteract and self.interact then
        self.interact.entity = ped
        exports.interact:AddLocalEntityInteraction(self.interact)
    end

    SetModelAsNoLongerNeeded(self.model)

    self.entity = ped
end

---Deletes the ped on exit
---@param self renewed_peds
local function deletePed(self)
    if self.entity and DoesEntityExist(self.entity) then
        SetEntityAsMissionEntity(self.entity, false, true)
        DeleteEntity(self.entity)

        if self.target then
            for i = 1, #self.target do
                exports.ox_target:removeLocalEntity(self.entity, self.target[i]?.name)
            end
        end

        if self.interact then
            exports.interact:RemoveLocalEntityInteraction(self.entity, self.interact?.id)
        end

        self.entity = nil
    end
end

---Adds a ped to the list of spawnable peds on the server
---@param payload renewed_peds | renewed_peds[]
exports('addPed', function(payload)
    payload = table.type(payload) == 'array' and payload or { payload }

    for i = 1, #payload do
        ---@diagnostic disable-next-line: invisible
        local ped = pedClass:new(payload[i])

        ped.resource = GetInvokingResource() or GetCurrentResourceName()
        ped.onEnter = spawnPed
        ped.onExit = deletePed

        Peds[#Peds+1] = lib.points.new(ped)
    end
end)

---Removes a ped from the list of spawnable peds on the server
---@param id string
exports('removePed', function(id)
    if id then
        for i = #Peds, 1, -1 do
            local ped = Peds[i]

            if ped.pedId == id then
                if ped.entity then
                    deletePed(ped)
                end

                ped:remove()

                table.remove(Peds, i)
                break
            end
        end
    end
end)

---Gets a ped by its id
---@param id string
---@return renewed_peds | nil
exports('getPedById', function(id)
    if id then
        for i = 1, #Peds do
            local ped = Peds[i]

            if ped.pedId == id then
                return ped
            end
        end
    end

    return nil
end)

---Sets the ped's coords and heading
---@param id string
---@param coords vector3 | vector4
---@param heading number?
exports('setPedCoords', function(id, coords, heading)
    if id and coords then
        for i = 1, #Peds do
            local item = Peds[i]
            if item.pedId == id then
                item.coords = coords.xyz
                item.heading = coords.w or heading

                if item.entity then
                    SetEntityCoords(item.entity, coords.x, coords.y, coords.z, false, false, false, false)
                    SetEntityHeading(item.entity, heading)
                end

                break
            end
        end
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    for i = #Peds, 1, -1 do
        local ped = Peds[i]

        if ped.resource == resource then
            if ped.entity then
                deletePed(ped)
            end

            ped:remove()

            table.remove(Peds, i)
        end
    end
end)

AddStateBagChangeHandler('instance', ('player:%s'):format(cache.serverId), function(_, _, value, _, replicated)
    if replicated then return end
    playerInstance = value or 0

    if next(Peds) then
        local playerCoords = GetEntityCoords(cache.ped)

        for i = 1, #Peds do
            local ped = Peds[i]

            if ped.instance == playerInstance then
                if #(playerCoords - ped.coords) < ped.distance then
                    spawnPed(ped)
                end
            else
                deletePed(ped)
            end
        end
    end
  end)
