NDCore = {}

lib.load('@ND_Core.init')

local Players = {}

function RenewedLib.getGroups(src)
    return Players[src] and Players[src].Groups or false
end exports('getGroups', RenewedLib.getGroups)

function RenewedLib.hasGroup(src, group, grade)
    local player = Players[src]

    if not player then return false end
    if not player.Groups[group] then return false end

    if grade then return player.Groups[group] >= grade end

    return true
end exports('hasGroup', RenewedLib.hasGroup)

function RenewedLib.getPlayer(source)
    return Players[source]
end exports('getPlayer', RenewedLib.getPlayer)

function RenewedLib.addStress(source, value)
    local player = NDCore.getPlayer(source)
    local stress = (player.getMetadata("stress") or 0) + value

    player.setMetaData('stress', stress > 100 and 100 or stress)
    player.notify({
        title = "Stress Gained",
        type = "error",
        duration = 1500
    })
end exports('addStress', RenewedLib.addStress)

function RenewedLib.relieveStress(source, value)
    local player = NDCore.getPlayer(source)
    local stress = (player.getMetadata("stress") or 0) - value

    player.setMetadata('stress', stress < 0 and 0 or stress)
    player.notify({
        title = "Stress Relieved",
        type = "error",
        duration = 1500
    })
end exports('relieveStress', RenewedLib.relieveStress)


function RenewedLib.isGroupAuth(group, grade)
    local Group = Groups[group]
    local auth = false
    if Group then
        auth = Group.ranks[grade] and grade >= Group.ranks[grade].minimumBossRank
    end
    return auth
end exports('isGroupAuth', RenewedLib.isGroupAuth)

function RenewedLib.getCharId(src)
    return Players[src] and Players[src].charId or false
end exports('getCharId', RenewedLib.getCharId)

function RenewedLib.getCharName(src)
    return Players[src] and Players[src].name or false
end exports('getCharName', RenewedLib.getCharName)

local query = 'SELECT firstname, lastname FROM nd_characters WHERE identifier = ?'
function RenewedLib.getCharNameById(identifier)
    local charinfo = MySQL.query.await(query, {identifier})
    if not charinfo then return false end
    local fullname = ("%s %s"):format(charinfo.firstname, charinfo.lastname)
    return fullname
end exports('getCharNameById', RenewedLib.getCharNameById)

function RenewedLib.getMoney(src, mType)
    local player = NDCore.getPlayer(src)
    if not player then return end
    return (mType == 'cash' or mType == 'bank') and player[mType] or nil
end exports('getMoney', RenewedLib.getMoney)

function RenewedLib.removeMoney(src, amount, mType, reason)
    local player = NDCore.getPlayer(src)

    if not player then return end

    return player.deductMoney(mType, amount, reason or "unknown")
end exports('removeMoney', RenewedLib.removeMoney)

function RenewedLib.addMoney(src, amount, mType, reason)
    local player = NDCore.getPlayer(src)

    if not player then return end

    return player.addMoney(mType, amount, reason or "unknown")
end exports('addMoney', RenewedLib.addMoney)

function RenewedLib.addNeeds(src, needs)
    if type(needs) ~= "table" then return end

    local player = NDCore.getPlayer(src)

    if not player then return end

    needs.hunger = needs.hunger or 0
    needs.thirst = needs.thirst or 0

    local hunger = player.getMetadata("hunger") + needs.hunger
    local thirst = player.getMetadata("thirst") + needs.thirst

    if hunger > 100 then hunger = 100 end
    if thirst > 100 then thirst = 100 end

    player.setMetadata("hunger", hunger)
    player.setMetadata("thirst", thirst)

    return true
end exports('addNeeds', RenewedLib.addNeeds)

function RenewedLib.getSourceByCharId(charId)
    for k, v in pairs(Players) do
        if v.charId == charId then
            return k
        end
    end

    return false
end exports('getSourceByCharId', RenewedLib.getSourceByCharId)

-- Group Updaters --
local function UpdatePlayerData(source)
    local player = NDCore.getPlayer(source)

    local playerGroups = {}
    for job, info in pairs(player.groups) do
        playerGroups[job] = info.rank
    end

    Players[source] = {
        Groups = playerGroups,
        job = player.job,
        charId = player.identifier,
        name = player.fullname
    }
end

AddEventHandler('ND:updateCharacter', function(PlayerData)
    UpdatePlayerData(PlayerData.source)
end)

AddEventHandler('ND:characterLoaded', function(PlayerData)
    UpdatePlayerData(PlayerData.source)

    TriggerEvent('Renewed-Lib:server:playerLoaded', PlayerData.source, Players[PlayerData.source])
end)

AddEventHandler('ND:characterUnloaded', function(source)
    if Players[source] then
        TriggerEvent('Renewed-Lib:server:playerRemoved', source, Players[source])
        Players[source] = nil
    end
end)

AddEventHandler('playerDropped', function()
    if Players[source] then
        TriggerEvent('Renewed-Lib:server:playerRemoved', source, Players[source])
        Players[source] = nil
    end
end)