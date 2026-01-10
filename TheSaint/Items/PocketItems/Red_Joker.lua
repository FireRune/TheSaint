local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

local game = Game()

--- "Red Joker"
--- - if the Devil/Angel Room has been generated already, acts like "Joker"
--- - otherwise:
---   - teleports Isaac to a special Devil Room containing "The Fallen"
---   - on room clear, allows access to 2 Devil Room Items for free
--- @class TheSaint.Items.PocketItems.Red_Joker : TheSaint.classes.ModFeatureTargeted<Card>
local Red_Joker = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<Card>
	Target = featureTarget:new(enums.Card.CARD_RED_JOKER),
}

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard(_, card, player, flags)
	local level = game:GetLevel()
	-- check wether Devil/Angel room has already been generated
	if (level:GetRoomByIdx(GridRooms.ROOM_DEVIL_IDX).Data == nil) then
		level:InitializeDevilAngelRoom(false, true)
		local roomData = isc:getRoomDataForTypeVariant(RoomType.ROOM_DEVIL, 101)
		isc:setRoomData(GridRooms.ROOM_DEVIL_IDX, roomData)
	end
	local useFlag = (UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER | UseFlag.USE_NOHUD)
	--- @cast useFlag UseFlag
	player:UseCard(Card.CARD_JOKER, useFlag)
end

-- TODO: implement mechanic of morphing "Joker" and "Red Joker" into each other (requires small rework of UnlockManager.lua)

--- Every "Joker" that spawns has a 10% chance to be turned into a "Red Joker"
--- @param pickup EntityPickup
local function postPickupInitFirst_Joker(_, pickup)
	local rng = pickup:GetDropRNG()
end

--- Every "Red Joker" that naturally spawns will turn into 
--- @param pickup EntityPickup
local function postPickupInitFirst_RedJoker(_, pickup)
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Red_Joker:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, self.Target.Type)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_Joker, PickupVariant.PICKUP_TAROTCARD, Card.CARD_JOKER)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_RedJoker, PickupVariant.PICKUP_TAROTCARD, self.Target.Type)
end

return Red_Joker
