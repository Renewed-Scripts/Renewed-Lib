local Objects = {}

--[[
  This is quite messy compared to peds will probably rewrite it later on
]]


local CreateObject = CreateObject
local GetEntityCoords = GetEntityCoords
local SetEntityHeading = SetEntityHeading
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local DeleteObject = DeleteObject
local GetInvokingResource = GetInvokingResource

local function SpawnObject(id)
  local item = Objects[id]

  lib.requestModel(item.object)

  local obj = CreateObject(item.object, item.coords.x, item.coords.y, item.coords.z, false, true, true)
  SetEntityHeading(obj, item.heading)

  if item.snapGround then PlaceObjectOnGroundProperly(obj) end
  if item.freeze ~= nil then FreezeEntityPosition(obj, item.freeze) end
  if item.canClimb ~= nil then SetCanClimbOnEntity(obj, item.canClimb) end

  if item.anim and item.animSpeed then
    SetEntityMaxSpeed(obj, 100)
    SetEntityAnimSpeed(obj, item.anim[1], item.anim[2], item.animSpeed)
  end

  SetModelAsNoLongerNeeded(item.object)

  if item.target then
    exports.ox_target:addLocalEntity(obj, item.target)
  end

  item.spawned = obj
end

function Renewed.addObject(payload)
  payload = table.type(payload) == 'array' and payload or { payload }
  local objectSize = #Objects
  local resource = GetInvokingResource()
  local pCoords = GetEntityCoords(cache.ped)

  for i = 1, #payload do
    local item = payload[i]
    item.resource = resource

    objectSize += 1
    Objects[objectSize] = item

    if #(pCoords - item.coords) < item.dist then
      SpawnObject(objectSize)
    end
  end
end

local function getObject(id)
  for i = 1, #Objects do
      local item = Objects[i]

      if item.id == id then
          return i
      end
  end
end

local function forceDeleteEntity(id)
  local item = Objects[id]

  if item.targets then
    for i = 1, #item.targets do
      exports.ox_target:removeLocalEntity(item.spawned, item.targets[i]?.name)
    end
  end
  DeleteObject(item.spawned)
  item.spawned = false
end

function Renewed.changeObject(id, newObject, newCoords)
  local objId = getObject(id)

  if not objId then return end

  local item = Objects[objId]

  local obj = type(newObject) == "string" and joaat(newObject) or newObject
  item.object = obj
  item.coords = newCoords or item.coords

  if not item.spawned then return end

  forceDeleteEntity(objId)
  SpawnObject(id)
end

function Renewed.changeAnim(id, anim, animSpeed)
  local objId = getObject(id)

  if not objId then return end

  local item = Objects[objId]

  item.anim = anim
  item.animSpeed = animSpeed

  if not item.spawned then return end

  SetEntityAnimSpeed(item.spawned, anim[1], anim[2], animSpeed)
end

function Renewed.removeObject(id)
  local objId = getObject(id)

  if not objId then return end

  local item = Objects[objId]

  if item.spawned then
    forceDeleteEntity(id)
  end

  table.remove(Objects, objId)
end

CreateThread(function()
    while true do
      local pCoords = GetEntityCoords(cache.ped)
      local objectCount = #Objects

      for i = 1, objectCount do
        local item = Objects[i]
        local isClose = #(pCoords - item.coords) < item.dist

        if item.spawned and not isClose then
          forceDeleteEntity(i)
          Wait(0)
        elseif not item.spawned and isClose then
          SpawnObject(i)
          Wait(0)
        end

      end

        Wait(5000)
    end
end)

local function removeResourceObj(resource)
  resource = resource or GetInvokingResource() or cache.resource
  for i = #Objects, 1, -1 do
    local item = Objects[i]

    if item.resource == resource then
      if item.spawned then
        forceDeleteEntity(i)
      end

      table.remove(Objects, i)
    end
  end
end

AddEventHandler('onClientResourceStop', function(resource)
  removeResourceObj(resource)
end)


-- Object placer --
local OxTxt = {
  '-- Place Object --  \n',
  '[E] Place  \n',
  '[X] Cancel  \n',
  '[SCROLL UP] Change Heading  \n',
  '[SCROLL DOWN] Change Heading'
}

local placingObj = nil

local function finishPlacing()
  lib.hideTextUI()
  DeleteObject(placingObj)
  placingObj = nil
end

function Renewed.placeObject(object, dist, snapGround, text, allowedMats)
  if placingObj then return end
  if not object then return "You didnt define any object to place" end

  local obj = type(object) == "string" and joaat(object) or object
  local heading = 0.0
  local checkDist = dist or 10.0

  local txt = text or OxTxt

  lib.requestModel(obj)

  placingObj = CreateObject(obj, 1.0, 1.0, 1.0, false, true, true)
  SetModelAsNoLongerNeeded(obj)
  SetEntityAlpha(placingObj, 150)
  SetEntityCollision(placingObj, false, false)
  SetEntityInvincible(placingObj, true)
  FreezeEntityPosition(placingObj, true)


  if type(txt) == "table" then txt = table.concat(txt) end

  lib.showTextUI(txt, {
    position = "left-center",
  })

  local outLine = false

  while placingObj do
    local hit, _, coords, _, materialHash = lib.raycast.cam(1, 4)
    if hit then
      SetEntityCoords(placingObj, coords.x, coords.y, coords.z)
      local objCoords = GetEntityCoords(placingObj)
      local distCheck = #(GetEntityCoords(cache.ped) - objCoords)
      SetEntityHeading(placingObj, heading)

      if snapGround then
        PlaceObjectOnGroundProperly(placingObj)
      end

      if outLine then
        outLine = false
        SetEntityDrawOutline(placingObj, false)
      end

      if (allowedMats and not allowedMats[materialHash]) or distCheck >= checkDist then
        if not outLine then
          outLine = true
          SetEntityDrawOutline(placingObj, true)
        end
      end

      if IsControlJustReleased(0, 38) then
        if not outLine and (not allowedMats or allowedMats[materialHash]) and distCheck < checkDist then
          finishPlacing()

          return objCoords, heading
        end
      end

      if IsControlJustReleased(0, 73) then
        finishPlacing()

        return nil, nil
      end

      if IsControlJustReleased(0, 14) then
        heading = heading + 5
        if heading > 360 then heading = 0.0 end
      end

      if IsControlJustReleased(0, 15) then
        heading = heading - 5
        if heading < 0 then heading = 360.0 end
      end
    end

    Wait(0)
  end
end

function Renewed.stopPlacing()
  if not placingObj then return end
  finishPlacing()
end