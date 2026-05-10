---@class renewed_decals : OxClass
---@field decal number | nil entity node
---@field coords vector3
---@field distance number
---@field scale number
---@field decalType number
---@field surfaceVector vector3
---@field decalRight vector3
---@field id string
---@field onEnter function
---@field instance number | string
---@field onExit function
---@field resource string
local decal_class = lib.class('renewed_decals')

---Function that gets triggered when a new decal intializes
---@param decalData renewed_decals
function decal_class:constructor(decalData)
    -- Set the decal to nil as its not yet spawned
    self.decal = nil

    -- Decal related data
    self.decalId = decalData.id
    self.coords = decalData.coords.xyz -- Make explicit call to make sure vector is using xyz
    self.scale = decalData.scale
    self.decalType = decalData.decalType
    self.surfaceVector = decalData.surfaceVector
    self.decalRight = decalData.decalRight
    self.distance = decalData.distance or 150
    self.instance = decalData.instance or 0
end

return decal_class