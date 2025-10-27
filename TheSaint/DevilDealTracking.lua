local isc = require("TheSaint.lib.isaacscript-common")

local game = Game()

--- Devil Deal tracking:
--- if tracking flag == false then:
--- 1. if picking up an item/pickup while at least 1 of the following is true:
---     - current RoomType == RoomType.ROOM_DEVIL
---     - current RoomDescriptor.Flags has RoomDescriptor.FLAG_DEVIL_TREASURE
---     - current level.GetStateFlag(LevelStateFlag.STATE_SATANIC_BIBLE_USED) == true and current RoomType == RoomType.ROOM_BOSS
--- 2. check wether 1 of the following is true:
---     - EntityPickup.Price < 0 (item had to be purchased with health OR pickup had to be paid with damage (PickupPrice.PRICE_SPIKES))
---     - EntityPickup.Price > 0 (item/pickup had to be purchased with money (any player is Keeper or Tainted Keeper, Pound of Flesh))
---     - (REP+) EntityPickup.Price == 0 and EntityPickup.State == 1 (item acquired after using sacrifice spikes)
--- 3. if both are true, set tracking flag to true

local DevilDealTracking = {}

local firstInit = true

local v = {
	run = {
		hasDevilDealBeenTaken = false
	}
}

--- @return boolean
function DevilDealTracking:HasDevilDealBeenTaken()
	return v.run.hasDevilDealBeenTaken
end

--- Function to determine wether purchasing an item/pickup would be considered as taking a Devil Deal.<br>
--- Returns true if current room is a Devil Room, a Devil Treasure Room (Devil's Crown) or a Boss Room after Satanic Bible has been used on the current floor.<br>
--- Otherwise, returns false
--- @return boolean
local function isCurrentRoomConsideredDevil()
	local level = game:GetLevel()
	local room = level:GetCurrentRoom()
	local roomDesc = level:GetCurrentRoomDesc()
	if (room:GetType() == RoomType.ROOM_DEVIL)
	or (isc:hasFlag(roomDesc.Flags, RoomDescriptor.FLAG_DEVIL_TREASURE))
	or (level:GetStateFlag(LevelStateFlag.STATE_SATANIC_BIBLE_USED) and room:GetType() == RoomType.ROOM_BOSS) then
		return true
	else
		return false
	end
end

--- @param player EntityPlayer
--- @param pickup EntityPickup
local function pickupGet(_, player, pickup)
	-- (REP+) Don't trigger this callback if Isaac is overlapping with an item that uses the DevilSacrifice payment.
	-- After paying with the sacrifice item.Price becomes 0 and item.State becomes 1
	if (REPENTANCE_PLUS and pickup.Price == -10) then return false end -- (magic number here because the enum PickupPrice currently has no member for this value)
	if (v.run.hasDevilDealBeenTaken == false and isCurrentRoomConsideredDevil() == true) then
		if (pickup.Price ~= 0 or (REPENTANCE_PLUS and pickup.Price == 0 and pickup.State == 1)) then
			v.run.hasDevilDealBeenTaken = true
		end
	end
end

--- @param mod ModReference
function DevilDealTracking:Init(mod)
	if (firstInit == true) then
		mod:saveDataManager("DevilDealTracking", v)
		mod:AddCallbackCustom(isc.ModCallbackCustom.PRE_GET_PEDESTAL, pickupGet)
		mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_COLLECT, pickupGet)
		firstInit = false
	end
end

return DevilDealTracking
