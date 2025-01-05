---@class renewed_objects : OxClass
---@field object number | nil entity node
---@field coords vector3
---@field model number
---@field heading number
---@field snapGround boolean
---@field freeze boolean
---@field canClimb boolean
---@field colissions boolean
---@field hasAnim boolean
---@field anim string?
---@field animSpeed number?
---@field distance number
---@field id string
---@field target OxTargetOption | OxTargetOption[]
---@field interact table
---@field onEnter function
---@field instance number | string
---@field onExit function
---@field resource string
local object_class = lib.class('renewed_objects')


---Function that gets triggered when a new object intializes
---@param objectData renewed_objects
function object_class:constructor(objectData)
    -- Set the object to nil as its not yet spawned
    self.object = nil

    -- Object related data
    self.objectId = objectData.id
    self.coords = objectData.coords.xyz -- Make explicit call to make sure vector is using xyz
    self.heading = objectData.coords?.w or objectData.heading or 0 -- Backwards compatibility
    self.model = objectData.object or objectData.model -- Backwards compatibility shit
    self.distance = objectData.distance or objectData.dist or 100
    self.instance = objectData.instance or 0
    self.particle = objectData.particle

    -- object settings data
    self.snapGround = objectData.snapGround or false
    self.freeze = objectData.freeze or false
    self.canClimb = objectData.canClimb or false
    self.colissions = objectData.colissions
    self.hasAnim = objectData.anim and objectData.animSpeed and true or false

    if self.hasAnim then
        self.anim = objectData.anim
        self.animSpeed = objectData.animSpeed
    end

    -- Target and Interact support
    self.target = objectData.target
    self.interact = objectData.interact
end

return object_class