local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

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
local function onPickup(_, pickup, collider)
	if (collider.Type == EntityType.ENTITY_PLAYER and pickup.Type == EntityType.ENTITY_PICKUP) then
		if (pickup.Variant == PickupVariant.PICKUP_COIN) then
			local player = collider:ToPlayer()
			if (player and player:HasTrinket(Holy_Penny.Target.Type)) then
				local multiplier = math.min(2, 0.5 + (player:GetTrinketMultiplier(Holy_Penny.Target.Type) / 2))
				local rng = player:GetTrinketRNG(Holy_Penny.Target.Type)
				if (rng:RandomFloat() < (1 - (0.8334 ^ (multiplier * pickup:GetCoinValue())))) then
					Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, game:GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true), Vector.Zero, nil)
				end
			end
		end
	end
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Holy_Penny:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, onPickup)
end

return Holy_Penny
