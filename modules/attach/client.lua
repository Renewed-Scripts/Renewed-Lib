AddStateBagChangeHandler('attachEntity', ('player:%s'):format(cache.serverId), function(_, _, value)
    if type(value) ~= 'table' then return end

    if value.entity then
        while not NetworkDoesEntityExistWithNetworkId(value.entity) do
            Wait(25)
        end

        local entity = NetworkGetEntityFromNetworkId(value.entity)

        if entity == 0 or not DoesEntityExist(entity) then return end

        -- BRO WHY DO WE HAVE TO DO DUMB SHIT LIKE THIS JUST PLEASE ATTACHENTITYTOENTITY SERVER SIDE AND I WILL CUM --
        if NetworkGetEntityOwner(entity) ~= cache.playerId then
            while NetworkGetEntityOwner(entity) ~= cache.playerId do
                NetworkRequestControlOfEntity(entity)
                Wait(25)
            end
        end

        if value.bone then
            local offset, rotation = value.offset, value.rotation

            AttachEntityToEntity(entity, cache.ped, GetPedBoneIndex(cache.ped, value.bone), offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, true, true, value.collision or false, false, value.rotOrder or 1, true)
        end
    end
end)