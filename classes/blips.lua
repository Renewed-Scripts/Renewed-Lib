---@class renewed_blips : OxClass
---@field label string?
---@field category number?
---@field coords vector3?
---@field blip number?
---@field entity number?
---@field netId number?
---@field color number?
---@field alpha number?
---@field scale number?
---@field sprite number?
---@field radius number?
---@field id number | string?
---@field longRange boolean?
---@field routeColor number?
local blip_class = lib.class('renewed_blips')

local blipCategories = lib.load('modules.blips.config')

---Function that gets triggered when a new object intializes
---@param payload renewed_blips
function blip_class:constructor(payload)
    if payload.category and type(payload.category) == 'string' and blipCategories[payload.category] then
        self.category = blipCategories[payload.category].id
    end


    self.id = payload.id
    self.entity = payload.entity
    self.netId = payload.netId
    self.coords = payload.coords

    self.color = payload.color or 0
    self.alpha = payload.alpha or 255

    self.resource = payload.resource

    if payload.radius then
        self.radius = payload.radius + 0.0
    else
        self.longRange = payload.longRange
        self.label = payload.label or 'NO LABEL FOUND'
        self.scale = payload.scale or 0.7
        self.sprite = payload.sprite or 1
    end

    if payload.route then
        self.routeColor = payload.routeColor or 1
    end
end

---Creates the blip on the map
function blip_class:createBlip()
    if self.blip then return end

    if self.entity then
        self.blip = AddBlipForEntity(self.entity)
    elseif self.netId then
        self.blip = AddBlipForEntity(NetworkGetEntityFromNetworkId(self.netId))
    elseif self.radius then
        self.blip = AddBlipForRadius(self.coords.x, self.coords.y, self.coords.z, self.radius)
    elseif self.coords then
        self.blip = AddBlipForCoord(self.coords.x, self.coords.y, self.coords.z)
    end

    if not self.radius then
        SetBlipSprite(self.blip, self.sprite)
        SetBlipScale(self.blip, self.scale)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(self.label)
        EndTextCommandSetBlipName(self.blip)


        if not self.longRange then
            SetBlipAsShortRange(self.blip, true)
        end

        if self.category then
            SetBlipCategory(self.blip, self.category)
        end
    end

    SetBlipColour(self.blip, self.color)
    SetBlipAlpha(self.blip, self.alpha)

    if self.routeColor then
        SetBlipRoute(self.blip, true)
        SetBlipRouteColour(self.blip, self.routeColor)
    end
end

function blip_class:removeBlip()
    if self.blip then
        RemoveBlip(self.blip)
        self.blip = nil
    end
end

---Sets the blip label
---@param label string
function blip_class:setLabel(label)
    if self.blip and not self.radius then
        self.label = label
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(self.label)
        EndTextCommandSetBlipName(self.blip)
    end
end

function blip_class:setCoords()
    if self.blip and self.coords then
        SetBlipCoords(self.blip, self.coords.x, self.coords.y, self.coords.z)
    end
end

CreateThread(function()
    for _, data in pairs(blipCategories) do
        AddTextEntry("BLIP_CAT_" .. data.id, data.Name)
    end
end)


return blip_class
