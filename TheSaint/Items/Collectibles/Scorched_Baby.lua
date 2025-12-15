local enums = require("TheSaint.Enums")

--- @class TheSaint.Items.Collectibles.Scorched_Baby : TheSaint_Feature
local Scorched_Baby = {
	IsInitialized = false,
	FeatureSubType = enums.CollectibleType.COLLECTIBLE_SCORCHED_BABY,
}

--- @param player EntityPlayer
--- @param flags CacheFlag
local function evaluateStats(_, player, flags)
	if (flags & CacheFlag.CACHE_FAMILIARS == CacheFlag.CACHE_FAMILIARS) then
		local numFamiliar = player:GetCollectibleNum(Scorched_Baby.FeatureSubType) + player:GetEffects():GetCollectibleEffectNum(Scorched_Baby.FeatureSubType)
		player:CheckFamiliar(enums.FamiliarVariant.SCORCHED_BABY, numFamiliar, player:GetCollectibleRNG(Scorched_Baby.FeatureSubType), Isaac.GetItemConfig():GetCollectible(Scorched_Baby.FeatureSubType))
	end
end

--- @param mod ModUpgraded
function Scorched_Baby:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_FAMILIARS)
end

return Scorched_Baby
