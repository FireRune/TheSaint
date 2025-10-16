local isc = require("TheSaint.lib.isaacscript-common")
local stats = include("TheSaint.stats")

local The_Saint = {}

local game = Game()
local char = Isaac.GetPlayerTypeByName(stats.default.name, false)

local v = {
    level = {
        angelRoomFirstEntry = true
    }
}

--- Birthright effect: when entering an Angel Room increases lowest stat (by giving and removing 'Consolation Prize')
--- @param room RoomType
local function postNewRoomReordered_Saint_Birthright(_, room)
    if (v.level.angelRoomFirstEntry) then
        for i = 0, game:GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if (player:GetPlayerType() == char)
            and (player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) then
                player:AddCollectible(CollectibleType.COLLECTIBLE_CONSOLATION_PRIZE)
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_CONSOLATION_PRIZE)
            end
        end
        v.level.angelRoomFirstEntry = false
    end
end

--- @param mod ModReference
function The_Saint:Init(mod)
    mod:saveDataManager("The_Saint", v)
    mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_REORDERED, postNewRoomReordered_Saint_Birthright, RoomType.ROOM_ANGEL)
end

return The_Saint
