local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local statusEffects = require("TheSaint.StatusEffects")

--- "Copper Stakes"
--- - +1 range
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

	if (flag & CacheFlag.CACHE_RANGE == CacheFlag.CACHE_RANGE) then
		player.TearRange = (player.TearRange + 40)
	end
end

--- @param tear EntityTear
local function postTearInit(_, tear)
	local player = tear.SpawnerEntity:ToPlayer()

	if ((player) and (player:HasCollectible(Copper_Stakes.Target.Type))) then
		-- same luck formula as "Mom's Contacts"
		local chance = math.min((1 / (5 - math.floor(player.Luck * 0.15))), 0.5)
		local rng = player:GetCollectibleRNG(Copper_Stakes.Target.Type)
		if (rng:RandomFloat() < chance) then
			tear:AddTearFlags(TearFlags.TEAR_JACOBS)
			tear:GetData().TheSaint = {}
		end
	end
end

--- @param tear EntityTear
--- @param collider Entity
--- @param low boolean
local function preTearCollision(_, tear, collider, low)
	local data = tear:GetData().TheSaint
	if (not data) then return end

	local enemy = ((collider:IsActiveEnemy() and collider:ToNPC()) or nil)
	if (not enemy) then return end

	local player = tear.SpawnerEntity:ToPlayer() --- @cast player -?
	statusEffects:ApplyStatus(enemy, enums.StatusEffect.ELECTRIFIED, 90, player)
end

--- @param mod ModUpgraded
function Copper_Stakes:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_RANGE)
	mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, postTearInit)
	mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, preTearCollision)
end

return Copper_Stakes
