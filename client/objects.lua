local Objects = {}

local CreateObject = CreateObject
local GetEntityCoords = GetEntityCoords
local SetEntityHeading = SetEntityHeading
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local DeleteObject = DeleteObject
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local GetInvokingResource = GetInvokingResource

local function SpawnObject(payload)
  lib.requestModel(payload.object)

  local obj = CreateObject(payload.object, payload.coords.x, payload.coords.y, payload.coords.z, false, true, true)
  SetEntityHeading(obj, payload.heading)


  if payload.snapGround then
    PlaceObjectOnGroundProperly(obj)
  end

  if payload.freeze ~= nil then
    FreezeEntityPosition(obj, payload.freeze)
  end

  if payload.canClimb ~= nil then
    SetCanClimbOnEntity(obj, payload.canClimb)
  end

  if payload.colissions ~= nil then
    SetEntityCollision(obj, payload.colissions, payload.colissions)
  end

  if payload.anim and payload.animSpeed then
    SetEntityMaxSpeed(obj, 100)
    SetEntityAnimSpeed(obj, payload.anim[1], payload.anim[2], payload.animSpeed)
  end

  if payload.target then
    exports.ox_target:addLocalEntity(obj, payload.target)
  end

  SetModelAsNoLongerNeeded(payload.object)

  return obj
end

function Renewed.addObject(payload)
  payload = table.type(payload) == 'array' and payload or { payload }
  local objectSize = #Objects
  local resource = GetInvokingResource()
  local pCoords = GetEntityCoords(cache.ped)

  for i = 1, #payload do
    local item = payload[i]
    item.resource = resource

    if #(pCoords - item.coords) < item.dist then
      item.spawned = SpawnObject(item)
    end

    objectSize += 1
    Objects[objectSize] = item
  end
end

local function getObject(id)
  for i = 1, #Objects do
      if Objects[i].id == id then
          return i
      end
  end
end

local function forceDeleteEntity(item)
  if not item then return end

  if item.targets then
    for i = 1, #item.targets do
      exports.ox_target:removeLocalEntity(item.spawned, item.targets[i]?.name)
    end
  end

  SetEntityAsMissionEntity(item.spawned, false, true)
  DeleteObject(item.spawned)
  item.spawned = false
end

function Renewed.changeObject(id, newObject, newCoords)
  local objId = getObject(id)

  if not objId then return end

  local item = Objects[objId]

  item.object = type(newObject) == "string" and joaat(newObject) or newObject
  item.coords = newCoords or item.coords

  if not item.spawned then return end

  forceDeleteEntity(item)
  item.spawned = SpawnObject(item)
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
  local objId = id and getObject(id)

  if not objId then return end

  local item = Objects[objId]

  if item.spawned then
    forceDeleteEntity(item)
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

        if not isClose and item.spawned then
          forceDeleteEntity(item)
          Wait(0)
        elseif isClose and (not item.spawned or not DoesEntityExist(item.spawned)) then
          item.spawned = SpawnObject(item)
          Wait(0)
        end

      end

        Wait(5000)
    end
end)

function Renewed.removeResourceObj(resource)
  resource = resource or GetInvokingResource() or cache.resource
  for i = #Objects, 1, -1 do
    local item = Objects[i]

    if item.resource == resource then
      if item.spawned then
        forceDeleteEntity(item)
      end

      table.remove(Objects, i)
    end
  end
end

AddEventHandler('onClientResourceStop', function(resource)
  Renewed.removeResourceObj(resource)
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


local IsControlJustReleased = IsControlJustReleased
local SetEntityCoords = SetEntityCoords
function Renewed.placeObject(object, dist, snapGround, text, allowedMats, offset)
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

      if offset then
        coords = coords + offset
      end

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
  end
end

function Renewed.stopPlacing()
  if not placingObj then return end
  finishPlacing()
end
