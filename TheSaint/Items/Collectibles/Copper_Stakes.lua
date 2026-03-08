local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

--- "Copper Stakes"
--- - Tears are replaced with copper "nails"
--- - increased knockback
--- - chance to inflict "electrified" status effect
--- @class TheSaint.Items.Collectibles.Copper_Stakes : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Copper_Stakes = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_COPPER_STAKES),
}

--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (not (player:HasCollectible(Copper_Stakes.Target.Type))) then return end

	if (flag & CacheFlag.CACHE_TEARFLAG == CacheFlag.CACHE_TEARFLAG) then
		player.TearFlags = (player.TearFlags | TearFlags.TEAR_KNOCKBACK)
	end
end

--- @param mod ModUpgraded
function Copper_Stakes:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_TEARFLAG)
end

return Copper_Stakes
