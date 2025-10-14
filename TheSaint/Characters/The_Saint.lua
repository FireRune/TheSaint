local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")

local The_Saint = {}

local game = Game()
local char = Isaac.GetPlayerTypeByName(stats.default.name, false)

local v = {
    run = {}
}

--- @param player EntityPlayer
local function getPlayerCounters(player)
    local playerIndex = "The_Saint_Counters_"..isc:getPlayerIndex(player)
    if (not v.run[playerIndex]) then
        v.run[playerIndex] = {
            damage = 0,
            fireRate = 0,
            speed = 0,
            range = 0
        }
    end
    return v.run[playerIndex]
end

--- @param player EntityPlayer
local function getLowestStat(player)
    --[[
    stat values: (lowest | default | max)
    Damage =    ?.?? | 3.50 | inf
    Fire Rate = ?.?? | 2.73 | 5.00
    Speed =     0.10 | 1.00 | 2.00
    Range =     1.00 | 6.50 | inf
    ]]
end

--- Birthright effect: when entering an Angel Room increases lowest stat.<br>
--- Possible stats include: +1 Damage, +0.5 Fire Rate, +0.2 Speed, +2.5 Range
--- @param room RoomType
local function postNewRoomReordered_Saint_Birthright(_, room)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if (player:GetPlayerType() == char)
        and (player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) then
            local counters = getPlayerCounters(player)
            local lowestStat = getLowestStat(player)
        end
    end
end

--- @param mod ModReference
function The_Saint:Init(mod)
    --mod:saveDataManager("The_Saint", v)
    mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_REORDERED, postNewRoomReordered_Saint_Birthright, RoomType.ROOM_ANGEL)
end

return The_Saint
