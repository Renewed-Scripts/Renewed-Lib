
---@class framework_class : OxClass
---@field name string
---@field charId string
---@field Groups table<string, number>
---@field job string?
---@field gang string?
local framework_class = lib.class('framework_class')

function framework_class:constructor(data)
    self.name = data.name
    self.charId = data.charId
    self.Groups = data.Groups
    self.job = data.job
    self.gang = data.gang

    TriggerEvent('Renewed-Lib:server:playerLoaded', Player.PlayerData.source, data)
end


return framework_class