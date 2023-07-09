Renewed = {}

exports("getLib", function()
	return Renewed
end)

local qb = GetResourceState('qb-core')
local esx = GetResourceState('es_extended')
local ox = GetResourceState('ox_core')
local framework = ox == 'started' and 'ox' or qb == 'started' and 'qb' or esx == 'started' and 'esx' or nil

if not framework then
	return error('No framework detected')
end

local scriptPath = ('bridge/%s/client.lua'):format(framework)
local resourceFile = LoadResourceFile(cache.resource, scriptPath)

if not resourceFile then
	return error(("Unable to find framework bridge for '%s'"):format(framework))
end

local func, err = load(resourceFile, ('@@%s/%s'):format(cache.resource, scriptPath))

if not func or err then
	return error(err)
end

func()