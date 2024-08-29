-- We have to make this an array since qbox is acting like qbcore is started so to make sure we get the right data we do this
local frameworks = {
    { 'ND_Core', 'ndcore' },
    { 'qbx_core', 'qbox' },
    { 'qb-core', 'qbcore' },
    { 'es_extended', 'esx' },
    { 'ox_core', 'ox' },
}

local filePath = IsDuplicityVersion() and 'server' or 'client'


for i = 1, #frameworks do
    local framework = frameworks[i]

    if GetResourceState(framework[1]) ~= 'missing' then
        local path = ('framework.%s.%s'):format(framework[2], filePath)

        require(path)

        break
    end
end