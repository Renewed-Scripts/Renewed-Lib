-- Temporary backwards compatibility, to be removed..
RenewedLib = {}

exports('getLib', function()
	print("This export is deprecated, please refer to the documentation for the updated usage.")
	return RenewedLib
end)


local qb = GetResourceState('qb-core')
local esx = GetResourceState('es_extended')
local ox = GetResourceState('ox_core')
local nd = GetResourceState('ND_Core')
local framework = ox == 'started' and 'ox' or qb == 'started' and 'qb' or esx == 'started' and 'esx' or nd == 'started' and 'nd' or nil

if not framework then
	return error('No framework detected')
end

local scriptPath = ('bridge/%s/%s.lua'):format(framework, lib.context)
local resourceFile = LoadResourceFile(cache.resource, scriptPath)

if not resourceFile then
	return error(("Unable to find framework bridge for '%s'"):format(framework))
end

local func, err = load(resourceFile, ('@@%s/%s'):format(cache.resource, scriptPath))

if not func or err then
	return error(err)
end

func()