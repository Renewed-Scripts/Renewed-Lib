local object_class = require 'classes.objects'

---@type boolean
local useInteract = GetConvar('renewed_useinteract', 'false') == 'true'

---@type table <number, CPoint>
local objects = {}

---goes through the array and find the index and returns that with the object
---@param id string
---@return number?
---@return CPoint?
local function getObject(id)
    if id then
        local index = lib.array.find(objects, function(object)
            return object.id == id
        end)

        return index, index and objects[index]
    end

    return nil, nil
end exports('getObject', getObject)

---Changes or adds a animation to an object
---@param id string
---@param anim table <string, string>
---@param animSpeed number
local function changeAnim(id, anim, animSpeed)
    local _, object = getObject(id)

    if object then
        object.anim = anim
        object.animSpeed = animSpeed

        if object.object then
            SetEntityAnimSpeed(object.object, anim[1], anim[2], animSpeed)
        end
    end
end exports('changeAnim', changeAnim)

---Removes a object from the world and the list
---@param id string
local function removeObject(id)
    local index, object = getObject(id)

    if index and object then
        if object.object then
            DeleteEntity(object.object)
        end

        table.remove(objects, index)
    end
end exports('removeObject', removeObject)

---Creates an object and assigns it to the class
---@param object renewed_objects
local function createObject(object)
    lib.requestModel(object.object)

    local obj = CreateObject(object.object, object.coords.x, object.coords.y, object.coords.z, false, true, true)
    SetEntityHeading(obj, object.heading)


    if object.snapGround then
      PlaceObjectOnGroundProperly(obj)
    end

    FreezeEntityPosition(obj, object.freeze)
    SetCanClimbOnEntity(obj, object.canClimb)
    SetEntityCollision(obj, object.colissions, object.colissions)

    if object.hasAnim then
      SetEntityMaxSpeed(obj, 100)
      SetEntityAnimSpeed(obj, object.anim[1], object.anim[2], object.animSpeed)
    end

    if object.target then
      exports.ox_target:addLocalEntity(obj, object.target)
    end

    if useInteract and object.interact then
      object.interact.entity = obj
      exports.interact:AddLocalEntityInteraction(object.interact)
    end

    SetModelAsNoLongerNeeded(object.object)

    object:setObject(obj)
end


---Deletes the spawned object if its spawned
---@param object renewed_objects
local function deleteObject(object)
    if object.object and DoesEntityExist(object.object) then
        DeleteEntity(object.object)
        object:setObject(nil)
    end
end exports('deleteObject', deleteObject)

---adds a object to the object list
---@param payload renewed_objects
local function addObject(payload)
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
end exports('addObject', addObject)


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