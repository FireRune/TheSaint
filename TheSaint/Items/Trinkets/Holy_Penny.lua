local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local utils = include("TheSaint.utils")

local game = Game()

--- "Holy Penny"
--- - picking up coins has a chance to spawn an Eternal Heart
--- @class TheSaint.Items.Trinkets.Holy_Penny : TheSaint.classes.ModFeatureTargeted<TrinketType>
local Holy_Penny = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<TrinketType>
	Target = featureTarget:new(enums.TrinketType.TRINKET_HOLY_PENNY),
}

--- When picking up a coin, has a 17%/25%/30% chance to spawn an Eternal Heart (same chance formula as for "Blessed Penny")
--- @param pickup EntityPickup
--- @param collider Entity
--- @param low boolean
local function prePickupCollision(_, pickup, collider, low)
	local player = collider:ToPlayer()
	if (not ((player) and (player:HasTrinket(Holy_Penny.Target.Type)))) then return end

	local multiplier = math.min(2, 0.5 + (player:GetTrinketMultiplier(Holy_Penny.Target.Type) / 2))
	local chance = (1 - (0.8334 ^ (multiplier * pickup:GetCoinValue())))
	local rng = player:GetTrinketRNG(Holy_Penny.Target.Type)
	if (rng:RandomFloat() >= chance) then return end

	Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, game:GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil)
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Holy_Penny:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddPriorityCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, utils.CallbackPriority_VERY_LATE, prePickupCollision, PickupVariant.PICKUP_COIN)
end

return Holy_Penny
