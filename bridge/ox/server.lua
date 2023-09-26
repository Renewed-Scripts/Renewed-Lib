local file = ('imports/%s.lua'):format(IsDuplicityVersion() and 'server' or 'client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))

chunk()

function Renewed.getCharId(source)
    local player = Ox.GetPlayer(source)

    return player and player.charId
end
