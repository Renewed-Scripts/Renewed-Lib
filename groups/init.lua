-- We have to make this an array since some scripts are providing the same exports as others, so to make sure we get the right data we do this
local groups = {
    { 'slrn_groups', 'slrn' },
    { 'ps-playergroups', 'ps' },
    { 'qb-phone', 'qb' }, -- We might need some additional checks for qb, due to the fact that this will break if they use regular qb phone and not Renewed
}

CreateThread(function()
    local loaded = false

    for i = 1, #groups do
        local framework = groups[i]

        if GetResourceState(framework[1]) ~= 'missing' then
            local path = ('groups.%s.server'):format(framework[2])

            require(path)

            loaded = true
            break
        end
    end

    if not loaded then
        require 'groups.standalone.server'
    end
end)

lib.versionCheck('Renewed-Scripts/Renewed-Lib')