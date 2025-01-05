local object_class = require 'classes.objects'

---@type table <number, CPoint>
local objects = {}

local useInteract = GetConvar('renewed_useinteract', 'false') == 'true'
local requestTimeouts = GetConvarInt('renewed_requesttimeouts', 10000)
local playerInstance = LocalPlayer.state.instance or 0

---goes through the array and find the index and returns that with the object
---@param id string
---@return number?
---@return CPoint?
local function getObject(id)
    if id then
        for i = 1, #objects do
            local object = objects[i]

            if object.objectId == id then
                return i, object
            end
        end
    end

    return nil, nil
end exports('getObject', getObject)

---Changes or adds a animation to an object
---@param id string
---@param anim table <string, string>
---@param animSpeed number
exports('changeAnim', function(id, anim, animSpeed)
    local _, object = getObject(id)

    if object then
        object.anim = anim
        object.animSpeed = animSpeed

        if object.object then
            SetEntityAnimSpeed(object.object, anim[1], anim[2], animSpeed)
        end
    end
end)

---Removes a object from the world and the list
---@param id string
exports('removeObject', function(id)
    local index, object = getObject(id)

    if index and object then
        if object.object then
            DeleteEntity(object.object)
        end

        object:remove()

        table.remove(objects, index)
    end
end)

---Creates an object and assigns it to the class
---@param self renewed_objects
local function createObject(self)
    if playerInstance ~= self.instance then return end
    lib.requestModel(self.model, requestTimeouts)

    local obj = CreateObject(self.model, self.coords.x, self.coords.y, self.coords.z, false, true, true)
    SetEntityHeading(obj, self.heading)

    if self.snapGround then
        PlaceObjectOnGroundProperly(obj)
    end

    FreezeEntityPosition(obj, self.freeze)
    SetCanClimbOnEntity(obj, self.canClimb)

    if type(self.colissions) == 'boolean' then
        SetEntityCollision(obj, self.colissions, self.colissions)
    end

    if self.hasAnim then
        SetEntityMaxSpeed(obj, 100)
        SetEntityAnimSpeed(obj, self.anim[1], self.anim[2], self.animSpeed)
    end

    SetModelAsNoLongerNeeded(self.model)

    if self.target then
        exports.ox_target:addLocalEntity(obj, self.target)
    end

    if useInteract and self.interact then
        self.interact.entity = obj
        exports.interact:AddLocalEntityInteraction(self.interact)
    end

    if self.particle and self.particle.dict and self.particle.name then
        lib.requestNamedPtfxAsset(self.particle.dict, 1000)
        UseParticleFxAssetNextCall(self.particle.dict)
        self.particle.particle = StartParticleFxLoopedOnEntity(self.particle.name, obj, self.particle.offsetX or 0.0, self.particle.offsetY or 0.0, self.particle.offsetZ or 0.0, self.particle.rotX or 0.0, self.particle.rotY or 0.0, self.particle.rotZ or 0.0, self.particle.scale or 1.0, 0.0, 0.0, 0.0)
        RemoveNamedPtfxAsset(self.particle.dict)
    end

    self.object = obj
end

---Deletes the spawned object if its spawned
---@param self renewed_objects
local function deleteObject(self)
    if self.object and DoesEntityExist(self.object) then
        if self.particle then
            StopParticleFxLooped(self.particle.particle, 0)
        end
        
        SetEntityAsMissionEntity(self.object, false, true)
        DeleteEntity(self.object)
        if self.target then
            for i = 1, #self.target do
                exports.ox_target:removeLocalEntity(self.spawned, self.target[i]?.name)
            end
        end

        if useInteract and self.interact then
            exports.interact:RemoveLocalEntityInteraction(self.spawned, self.interact?.id)
        end

        self.object = nil
    end
end

---Changes the object model, coords and heading
---@param id string
---@param newObject string | number
---@param newCoords vector3
---@param newHeading number
exports('changeObject', function(id, newObject, newCoords, newHeading)
    local _, object = getObject(id)

    if object then
        object.model = newObject
        object.coords = newCoords or object.coords
        object.heading = newHeading or object.heading

        if object.object then
            deleteObject(object)
            createObject(object)
        end
    end
end)

---adds a object to the object list
---@param payload renewed_objects
exports('addObject', function(payload)
    -- If table is not an array we convert it into one
    payload = table.type(payload) == 'array' and payload or {payload}

    for i = 1, #payload do
        ---@diagnostic disable-next-line: invisible
        local object = object_class:new(payload[i])

        object.onEnter = createObject
        object.onExit = deleteObject
        object.resource = GetInvokingResource() or GetCurrentResourceName()

        objects[#objects+1] = lib.points.new(object)
    end
end)

---Adds a particle to an object
---@param id string
---@param dict string
---@param name string
---@param offsetX number?
---@param offsetY number?
---@param offsetZ number?
---@param rotX number?
---@param rotY number?
---@param rotZ number?
---@param scale number?
exports('addObjectParticle', function(id, dict, name, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale)
    local _, object = getObject(id)

    if object and not object.particle and dict and name then
        object.particle = {
            dict = dict,
            name = name,
            offsetX = offsetX or 0.0,
            offsetY = offsetY or 0.0,
            offsetZ = offsetZ or 0.0,
            rotX = rotX or 0.0,
            rotY = rotY or 0.0,
            rotZ = rotZ or 0.0,
            scale = scale or 1.0
        }
        lib.requestNamedPtfxAsset(object.particle.dict, 1000)
        UseParticleFxAssetNextCall(object.particle.dict)
        object.particle.particle = StartParticleFxLoopedOnEntity(object.particle.name, object.object, object.particle.offsetX, object.particle.offsetY, object.particle.offsetZ, object.particle.rotX, object.particle.rotY, object.particle.rotZ, object.particle.scale, 0.0, 0.0, 0.0)
        RemoveNamedPtfxAsset(object.particle.dict)
    end
end)

---Removes a particle from an object
---@param id string
exports('removeObjectParticle', function(id)
    local _, object = getObject(id)

    if object and object.particle then
        StopParticleFxLooped(object.particle.particle, 0)
        object.particle = nil
    end
end)

---Deletes an object and removes it from the list if the object comes from the same resource
---@param resourceName string
AddEventHandler('onClientResourceStop', function(resourceName)
    for i = #objects, 1, -1 do
        local object = objects[i]

        if object.resource == resourceName then
            deleteObject(object)
            object:remove()
            table.remove(objects, i)
        end
    end
end)

AddStateBagChangeHandler('instance', ('player:%s'):format(cache.serverId), function(_, _, value, _, replicated)
    if replicated then return end
    playerInstance = value or 0

    if next(objects) then
        local playerCoords = GetEntityCoords(cache.ped)

        for i = 1, #objects do
            local object = objects[i]

            if object.instance == playerInstance then
                if #(playerCoords - object.coords) < object.distance then
                    createObject(object)
                end
            else
                deleteObject(object)
            end
        end
    end
  end)

