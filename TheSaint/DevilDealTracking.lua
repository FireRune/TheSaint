local isc = require("TheSaint.lib.isaacscript-common")
local utils = include("TheSaint.utils")

local game = Game()

--- @class TheSaint.DevilDealTracking : TheSaint.classes.ModFeature
local DevilDealTracking = {
	IsInitialized = false,
	SaveDataKey = "DevilDealTracking",
}

local v = {
	run = {
		HasDevilDealBeenTaken = false,
	},
}

--- Function to determine wether purchasing an item/pickup would be considered as taking a Devil Deal.<br>
--- Returns true if current room is a Devil Room, a Devil Treasure Room ("Devil's Crown") or a Boss Room after "Satanic Bible" has been used on the current floor.<br>
--- Otherwise, returns false.
--- @return boolean
local function isCurrentRoomConsideredDevil()
	local level = game:GetLevel()
	local room = level:GetCurrentRoom()
	local roomDesc = level:GetCurrentRoomDesc()

	return (
		(room:GetType() == RoomType.ROOM_DEVIL) or
		(isc:hasFlag(roomDesc.Flags, RoomDescriptor.FLAG_DEVIL_TREASURE)) or
		(level:GetStateFlag(LevelStateFlag.STATE_SATANIC_BIBLE_USED) and (room:GetType() == RoomType.ROOM_BOSS))
	)
end

--- Sets the Devil Deal Tracking flag after collecting a pickup/item that is considered a Devil Deal.
--- @param player EntityPlayer
--- @param pickup EntityPickup
local function pickupGet(_, player, pickup)
	-- (REP+) Don't trigger this callback if Isaac is overlapping with an item that uses the DevilSacrifice payment.
	if ((REPENTANCE_PLUS) and (pickup.Price == utils.PickupPrice_PRICE_SACRIFICE)) then return false end

	if ((v.run.HasDevilDealBeenTaken) or (not isCurrentRoomConsideredDevil())) then return end

	-- After paying with the sacrifice item.Price becomes 0 and item.State becomes 1
	if ((pickup.Price == 0) and (not ((REPENTANCE_PLUS) and (pickup.State == 1)))) then return end

	v.run.HasDevilDealBeenTaken = true
end

--- @param mod ModUpgraded
function DevilDealTracking:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallbackCustom(isc.ModCallbackCustom.PRE_GET_PEDESTAL, pickupGet)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_COLLECT, function (_, pickup, player)
		pickupGet(_, player, pickup)
	end)
end

--- Returns wether a Devil Deal has been taken in the current run. (i.e. any purchase that causes Angel Room chance to be displayed as 0%)<br>
--- That includes any pickup/item with a price tag (money, hearts, (REP+ only) sacrifice spikes)<br>
--- found in a Devil Room, Boss Room after using "Satanic Bible" or Devil Treasure Room (from "Devil's Crown")
--- @return boolean
function DevilDealTracking:HasDevilDealBeenTaken()
	return v.run.HasDevilDealBeenTaken
end

return DevilDealTracking
