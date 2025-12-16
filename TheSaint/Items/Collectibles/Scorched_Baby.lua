local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

--- @class TheSaint.Items.Collectibles.Scorched_Baby : TheSaint_Feature
local Scorched_Baby = {
	IsInitialized = false,
	FeatureSubType = enums.CollectibleType.COLLECTIBLE_SCORCHED_BABY,
}

--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (flag == CacheFlag.CACHE_FAMILIARS) then
		isc:checkFamiliarFromCollectibles(player, Scorched_Baby.FeatureSubType, enums.FamiliarVariant.SCORCHED_BABY)
	end
end

--- @param familiar EntityFamiliar
local function familiarInit(_, familiar)
	familiar:AddToFollowers()
	familiar.FireCooldown = 2
	familiar:PlayFloatAnim(Direction.DOWN)
end

--- @param familiar EntityFamiliar
local function familiarUpdate(_, familiar)
	familiar:FollowParent()

	local player = familiar.Player
	local moveDirection = player:GetMovementDirection()
	local fireDirection = player:GetFireDirection()

	if (fireDirection == Direction.NO_DIRECTION) then
		familiar:PlayFloatAnim(moveDirection)
	else
		--- @type Vector
		local tearVector = isc:directionToVector(fireDirection)
		if (familiar.FireCooldown <= 0) then
			local tear = familiar:FireProjectile(tearVector)
			tear:AddTearFlags(TearFlags.TEAR_BURN)
			tear:ChangeVariant(TearVariant.FIRE_MIND)
			if (player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)) then
				tear.CollisionDamage = 7
				tear.Scale = 1.15
			else
				tear.CollisionDamage = 3.5
				tear.Scale = 0.7
			end

			if (player:HasTrinket(TrinketType.TRINKET_FORGOTTEN_LULLABY)) then
				familiar.FireCooldown = 11
			else
				familiar.FireCooldown = 22
			end
		end
		familiar:PlayShootAnim(fireDirection)
	end
	familiar.FireCooldown = familiar.FireCooldown - 1
end

--- @param mod ModUpgraded
function Scorched_Baby:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_FAMILIARS)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, familiarInit, enums.FamiliarVariant.SCORCHED_BABY)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, familiarUpdate, enums.FamiliarVariant.SCORCHED_BABY)
end

return Scorched_Baby
