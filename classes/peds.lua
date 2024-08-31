

---@class renewed_peds : OxClass
---@field coords vector3 | vector4
---@field heading number
---@field pedId string
---@field distance number
---@field freeze boolean?
---@field invincible boolean?
---@field tempevents boolean?
---@field animDict string?
---@field animName string?
---@field scenario string?
---@field target OxTargetOption | OxTargetOption[]?
---@field interact table?
---@field onEnter function
---@field instance number | string
---@field onExit function
---@field resource string
---@field entity number | nil entity node
local peds_class = lib.class('renewed_peds')


---intiates the ped class with all the appropriate data
---@param payload renewed_peds
function peds_class:constructor(payload)
    self.entity = nil
    self.distance = payload.distance or payload.dist or 100
    self.model = payload.model
    self.coords = payload.coords.xyz
    self.heading = payload.coords?.w or payload.heading
    self.pedId = payload.id

    self.freeze = payload.freeze or false
    self.invincible = payload.invincible or false
    self.tempevents = payload.tempevents or false

    self.animDict = payload.animDict
    self.animName = payload.animName
    self.scenario = payload.scenario

    self.target = payload.target
    self.interact = payload.interact
end





return peds_class