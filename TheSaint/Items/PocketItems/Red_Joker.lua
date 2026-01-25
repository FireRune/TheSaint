local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local unlockManager = require("TheSaint.UnlockManager")

local game = Game()
local sfx = SFXManager()

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

local playVoiceline = false

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
	playVoiceline = true
	local useFlag = (UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER | UseFlag.USE_NOHUD)
	--- @cast useFlag UseFlag
	player:UseCard(Card.CARD_JOKER, useFlag)
end

--- @param room RoomType
local function postNewRoomReordered(_, room)
	if ((room ~= RoomType.ROOM_DEVIL) and (room ~= RoomType.ROOM_ANGEL)) then return end
	if (playVoiceline) then
		local rng = Isaac.GetPlayer(0):GetCardRNG(Red_Joker.Target.Type)
		if ((Options.AnnouncerVoiceMode == 2) or ((Options.AnnouncerVoiceMode == 0) and (rng:RandomInt(2) == 0))) then
			sfx:Play(enums.SoundEffect.SOUND_REVERSE_JOKER)
		end
		playVoiceline = false
	end
end

local spawnFromPlayer = false

--- @param type EntityType
--- @param variant integer
--- @param subtype integer
--- @param position Vector
--- @param velocity Vector
--- @param spawner Entity
--- @param seed integer
--- @return { Type: EntityType, Variant: integer, SubType: integer, Seed: integer }?
local function preEntitySpawn(_, type, variant, subtype, position, velocity, spawner, seed)
	if ((type == EntityType.ENTITY_PICKUP)
	and (variant == PickupVariant.PICKUP_TAROTCARD)
	and ((subtype == Card.CARD_JOKER) or (subtype == Red_Joker.Target.Type))) then
		-- if `spawner` is a player, then it is most likely due to dropping said item, therefore don't morph
		if (spawner and spawner:ToPlayer()) then
			spawnFromPlayer = true
		end
	end
end

local redJokerSpawn = false

--- Every "Joker" that naturally spawns has a 10% chance to be turned into a "Red Joker"
--- @param pickup EntityPickup
local function postPickupInitFirst_Joker(_, pickup)
	if (spawnFromPlayer) then
		spawnFromPlayer = false
		return
	end
	if (unlockManager:IsPickupUnlocked(PickupVariant.PICKUP_TAROTCARD, Red_Joker.Target.Type)) then
		local rng = pickup:GetDropRNG()
		if (rng:RandomInt(100) < 10) then
			redJokerSpawn = true
			pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Red_Joker.Target.Type, false, false, true)
		end
	end
end

--- Every "Red Joker" that naturally spawns will turn into "Joker"
--- @param pickup EntityPickup
local function postPickupInitFirst_RedJoker(_, pickup)
	if (spawnFromPlayer) then
		spawnFromPlayer = false
		return
	end
	if (redJokerSpawn == false) then
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Card.CARD_JOKER, false, false, true)
	else
		redJokerSpawn = false
	end
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Red_Joker:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, self.Target.Type)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_REORDERED, postNewRoomReordered)
	mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, preEntitySpawn)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_RedJoker, PickupVariant.PICKUP_TAROTCARD, self.Target.Type)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_Joker, PickupVariant.PICKUP_TAROTCARD, Card.CARD_JOKER)
end

return Red_Joker
