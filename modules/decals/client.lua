--[[
    LuaGLM
    Copyright (C) 2020 - gottfriedleibniz

    OpenGL Mathematics (GLM)
    Copyright (C) 2005 - G-Truc Creation

    Lua
    Copyright (C) 1994-2021 Lua.org, PUC-Rio.

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local glm = require("glm")
local decal_class = require 'classes.decals'

-- Cache common functions
local quat = quat
local glm_abs = glm.abs
local glm_deg = glm.deg
local glm_dot = glm.dot
local glm_sign = glm.sign
local glm_approx = glm.approx
local glm_normalize = glm.normalize
local glm_perpendicular = glm.perpendicular
local glm_quatlookRotation = glm.quatlookRotation
local glm_extractEulerAngleYXZ = glm.extractEulerAngleYXZ
local math = math

-- Cache direction vectors
local glm_up = glm.up()
local glm_right = glm.right()
local glm_forward = glm.forward()

---@type table <number, CPoint>
local decals = {}

local requestTimeouts = GetConvarInt('renewed_requesttimeouts', 10000)
local playerInstance = LocalPlayer.state.instance or 0

---goes through the array and find the index and returns that with the decal
---@param id string
---@return number?
---@return CPoint?
local function getDecal(id)
    if id then
        for i = 1, #decals do
            local decal = decals[i]

            if decal.decalId == id then
                return i, decal
            end
        end
    end

    return nil, nil
end
exports('getDecal', getDecal)

---Removes a decal from the world and the list
---@param id string
exports('removeDecal', function(id)
    local index, decal = getDecal(id)

    if index and decal then
        if decal.decal then
            RemoveDecal(decal.decal)
        end

        decal:remove()

        table.remove(decal, index)
    end
end)

local function calcDecalRight(surface)
    local decalRight = glm_perpendicular(surface, -glm_up, glm_right)
    local dot_up = glm_dot(surface, glm_up)
    if glm_approx(glm_abs(dot_up), 1.0, 1E-2) then
        local camRot = GetFinalRenderedCamRot(2)
        decalRight = quat(camRot.z, glm_up) * glm_right
    end
    return decalRight
end

local function CreateDecalFromRaycastResult(decalType, pos, surface, textureScale, decalRight)
    local decalForward = -surface

    return AddDecal(
        decalType,
        pos.x, pos.y, pos.z,
        decalForward.x, decalForward.y, decalForward.z,
        decalRight.x, decalRight.y, decalRight.z,
        textureScale, textureScale,
        1.0, 1.0, 1.0, 1.0, -1.0, true, false, true
    )
end

---Creates an decal and assigns it to the class
---@param self renewed_decals
local function createDecal(self)
    if playerInstance ~= self.instance then return end
    local coords = vec3(self.coords.x, self.coords.y, self.coords.z)
    local surfaceVector = vec3(self.surfaceVector.x, self.surfaceVector.y, self.surfaceVector.z)
    local textureScale = self.scale
    local decalRight = vec3(self.decalRight.x, self.decalRight.y, self.decalRight.z)

    local decal = CreateDecalFromRaycastResult(self.decalType, coords, surfaceVector, textureScale, decalRight)
    self.decal = decal
end

---Deletes the spawned decal if its spawned
---@param self renewed_decals
local function deleteDecal(self)
    if self.decal then
        RemoveDecal(self.decal)
        self.decal = nil
    end
end

---adds a decal to the decals list
---@param payload renewed_decals
exports('addDecal', function(payload)
    -- If table is not an array we convert it into one
    payload = table.type(payload) == 'array' and payload or {payload}

    for i = 1, #payload do
        ---@diagnostic disable-next-line: invisible
        local decal = decal_class:new(payload[i])

        decal.onEnter = createDecal
        decal.onExit = deleteDecal
        decal.resource = GetInvokingResource() or GetCurrentResourceName()

        decals[#decals+1] = lib.points.new(decal)
    end
end)

---Deletes an decal and removes it from the list if the decal comes from the same resource
---@param resourceName string
AddEventHandler('onClientResourceStop', function(resourceName)
    for i = #decals, 1, -1 do
        local decal = decals[i]

        if decal.resource == resourceName then
            deleteDecal(decal)
            decal:remove()
            table.remove(decals, i)
        end
    end
end)

AddStateBagChangeHandler('instance', ('player:%s'):format(cache.serverId), function(_, _, value, _, replicated)
    if replicated then return end
    playerInstance = value or 0

    if next(decals) then
        local playerCoords = GetEntityCoords(cache.ped)

        for i = 1, #decals do
            local decal = decals[i]

            if decal.instance == playerInstance then
                if #(playerCoords - decal.coords) < decal.distance then
                    createDecal(decal)
                end
            else
                deleteDecal(decal)
            end
        end
    end
end)

-- Decal placer --

local placingDec = false
local placingDict = nil
local OxTxt = {
    '-- Place Decal --  \n',
    '[E] Place  \n',
    '[X] Cancel  \n'
}

local function finishPlacing()
    lib.hideTextUI()
    placingDec = false
    if placingDict then
        SetStreamedTextureDictAsNoLongerNeeded(placingDict)
        placingDict = nil
    end
end

---Sets the player up to place decals in the world using basic keybinds
---@param data table
---@return vector3?, vector3?, number?, vector3?
exports('placeDecal', function(data)
    local dict, texture, scale, allowRescale, minScale, maxScale, text, minHeightAbovePed = data.dict, data.texture, data.scale, data.allowRescale, data.minScale, data.maxScale, data.text, data.minHeightAbovePed
    local activeScale = (type(scale) == "number" and scale > 0.0) and scale
    if placingDec or not dict or not texture or not activeScale then return end

    local function RotationToDirection(rotation)
        local adjustedRotation = {
            x = (math.pi / 180) * rotation.x,
            y = (math.pi / 180) * rotation.y,
            z = (math.pi / 180) * rotation.z
        }
        local direction = {
            x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
            y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
            z = math.sin(adjustedRotation.x)
        }
        return direction
    end

    local function SurfaceNormalToMarkerRotation(normal)
        local quat_eps = 1E-2
        local surfaceFlip = quat(180.0, glm_forward)

        local q = nil
        if glm_approx(glm_abs(normal.z), 1.0, quat_eps) then
            local camRot = GetFinalRenderedCamRot(2)
            local counterRotation = (glm_sign(normal.z) * -camRot.z) - 90.0

            q = glm_quatlookRotation(normal, glm_right)
            q = q * quat(counterRotation, glm_up)
        elseif glm_approx(normal.y, 1.0, quat_eps) then
            q = glm_quatlookRotation(normal, -glm_up)
            surfaceFlip = quat(180.0, glm_right)
        else -- The texture/decal needs to be flipped!
            q = glm_quatlookRotation(normal, glm_up)
        end

        local euler = vec3(glm_extractEulerAngleYXZ(q * surfaceFlip))
        return q, glm_deg(vec3(euler[2],euler[1],euler[3]))
    end
    placingDict = dict

    lib.requestStreamedTextureDict(placingDict, requestTimeouts)

    local activeRes = GetTextureResolution(placingDict, texture)
    local activeDims = vec2(activeScale * (activeRes.x / activeRes.y), activeScale)

    placingDec = true
    OxTxt = {
        (data.title and (data.title .. '  \n') or '-- Place Decal --  \n'),
        (data.placeLabel and (data.placeLabel .. '  \n') or '[E] Place  \n'),
        '[X] Cancel  \n',
    }
    if allowRescale then
        OxTxt[4] = '[SCROLL UP] Increase size  \n'
        OxTxt[5] = '[SCROLL DOWN] Decrease size'
    end
    local txt = text or OxTxt
    lib.showTextUI(type(txt) == 'table' and table.concat(txt) or txt, {
        position = "left-center",
    })

    while placingDec do
        Wait(0)
        DisableControlAction(0, 44, true)

        local cameraRotation = GetGameplayCamRot()
        local cameraCoord = GetGameplayCamCoord()
        local direction = RotationToDirection(cameraRotation)
        local destination = {
            x = cameraCoord.x + direction.x * 20.0,
            y = cameraCoord.y + direction.y * 20.0,
            z = cameraCoord.z + direction.z * 20.0
        }

        local _, hit, pos, surface, _ = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, cache.ped, 0))
        local pedCoords = GetEntityCoords(cache.ped)
        local far = #(pedCoords - pos) > 3.0
        surface = glm_normalize(surface)
        local m_pos = pos + surface * 0.25
        local _, m_euler = SurfaceNormalToMarkerRotation(surface)

        local decalRight = calcDecalRight(surface)

        if IsControlPressed(0, 73) then
            finishPlacing()
            return nil
        end

        if allowRescale then
            local xClamp = math.clamp(activeDims.x, minScale, maxScale)
            local yClamp = math.clamp(activeDims.y, minScale, maxScale)
            activeDims = vec2(xClamp, yClamp)
            if IsControlJustReleased(0, 15) then
                activeDims = vec2(math.min(activeDims.x + 0.1, maxScale), math.min(activeDims.y + 0.1, maxScale))
            end

            if IsControlJustReleased(0, 14) then
                activeDims = vec2(math.max(activeDims.x - 0.1, minScale), math.max(activeDims.y - 0.1, minScale))
            end
        end

        if hit == 0 or far or (minHeightAbovePed and pedCoords.z + minHeightAbovePed > pos.z) then
            DrawMarker(28, m_pos.x, m_pos.y, m_pos.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 244, 68, 46, 200, false, true, 2, false, nil, nil, false)
        else
            DrawMarker(28, m_pos.x, m_pos.y, m_pos.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 2, 241, 181, 225, false, true, 2, false, nil, nil, false)
            DrawMarker(9, m_pos.x, m_pos.y, m_pos.z, 0.0, 0.0, 0.0, m_euler.x, m_euler.y, m_euler.z, activeDims.x, activeDims.y, activeDims.y, 255, 255, 255, 123, false, false, 2, false, placingDict, texture, false)
            if IsControlJustPressed(0, 38) then
                finishPlacing()
                return pos, surface, math.floor(activeDims.x * 100 + 0.5) / 100, decalRight
            end
        end
    end
end)

exports('stopPlacingDecal', function()
    if not placingDec then return end
    finishPlacing()
end)
