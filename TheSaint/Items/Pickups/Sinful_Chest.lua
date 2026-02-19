local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local unlockManager = require("TheSaint.UnlockManager")
local utils = include("TheSaint.utils")

local game = Game()
local sfx = SFXManager()

-- SubType of a fresh, unopened Eternal Chest is 2. After it closes itself again it's SubType changes to 1 (CHEST_CLOSED)
local CHEST_ETERNAL_CLOSED = 2

--- "Sinful Chest"
--- - works like an Eternal Chest, but with the rewards of Red Chests (25% chance for nothing, no longer re-closes if payout was nothing or an item)
--- - has a chance to replace regular Red Chests (higher chance in Devil Rooms)
--- @class TheSaint.Items.Pickups.Sinful_Chest : TheSaint.classes.ModFeatureTargeted<PickupVariant>
local Sinful_Chest = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<PickupVariant>
	Target = featureTarget:new(enums.PickupVariant.PICKUP_SINFULCHEST),
	SaveDataKey = "Sinful_Chest",
}

local v = {}

--- Change Red Chests to Sinful Chests with the following chance:
--- - in a Devil Room: ~66.6%
--- - otherwise: ~1.05%
--- @param pickup EntityPickup
local function postPickupInitFirst_RedChest(_, pickup)
	-- only change Red Chests when Sinful Chests are unlocked
	if (unlockManager:IsPickupUnlocked(Sinful_Chest.Target.Type, 0) == false) then return end

	local room = game:GetRoom()

	local chance = (((room:GetType() == RoomType.ROOM_DEVIL) and (2/3)) or (7/666))
	local rng = utils:CreateNewRNG(pickup.InitSeed)
	if (rng:RandomFloat() < chance) then
		pickup:Morph(EntityType.ENTITY_PICKUP, Sinful_Chest.Target.Type, 0, false, false, true)
	end
end

--- @param pickup EntityPickup
local function postPickupInitFirst_SinfulChest(_, pickup)
	pickup.SubType = CHEST_ETERNAL_CLOSED
end

--- @param pickup EntityPickup
local function postPickupUpdate_SinfulChest(_, pickup)
	local sprite = pickup:GetSprite()
	if (sprite:IsEventTriggered("DropSound")) then
		sfx:Play(SoundEffect.SOUND_CHEST_DROP)
	end
end

--- @param pickup EntityPickup
--- @param collider Entity
--- @param low boolean
local function prePickupCollision_SinfulChest(_, pickup, collider, low)
	local player = collider:ToPlayer()
	if (not player) then return end
end

--- @param mod ModUpgraded
function Sinful_Chest:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_RedChest, PickupVariant.PICKUP_REDCHEST)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_SinfulChest, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, postPickupUpdate_SinfulChest, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, prePickupCollision_SinfulChest, self.Target.Type)
end

return Sinful_Chest
