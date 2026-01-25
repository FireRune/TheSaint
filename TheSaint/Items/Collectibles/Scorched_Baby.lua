local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

--- @class TheSaint.Items.Collectibles.Scorched_Baby : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Scorched_Baby = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_SCORCHED_BABY, {EntityType.ENTITY_FAMILIAR, enums.FamiliarVariant.SCORCHED_BABY}),
}

--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (flag == CacheFlag.CACHE_FAMILIARS) then
		isc:checkFamiliarFromCollectibles(player, Scorched_Baby.Target.Type, Scorched_Baby.Target.Entity.Variant)
	end
end

--- @param familiar EntityFamiliar
local function familiarInit(_, familiar)
	familiar:AddToFollowers()
end

--- @param familiar EntityFamiliar
local function familiarUpdate(_, familiar)
	familiar:Shoot()
	for _, ent in ipairs(Isaac.FindByType(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0)) do
		if ((ent.SpawnerType == familiar.Type)
		and (ent.SpawnerVariant == familiar.Variant)
		and (ent.FrameCount == 0)) then
			local tear = ent:ToTear() --- @cast tear EntityTear
			tear:AddTearFlags(TearFlags.TEAR_BURN)
			tear:ChangeVariant(TearVariant.FIRE_MIND)
		end
	end
	familiar:FollowParent()
end

--- @param mod ModUpgraded
function Scorched_Baby:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_FAMILIARS)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, familiarInit, self.Target.Entity.Variant)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, familiarUpdate, self.Target.Entity.Variant)
end

return Scorched_Baby
