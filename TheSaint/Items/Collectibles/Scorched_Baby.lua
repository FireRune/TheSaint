local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

--- @class TheSaint.Items.Collectibles.Scorched_Baby : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Scorched_Baby = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_SCORCHED_BABY, enums.FamiliarVariant.SCORCHED_BABY),
}

--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (flag == CacheFlag.CACHE_FAMILIARS) then
		isc:checkFamiliarFromCollectibles(player, Scorched_Baby.Target.Type, Scorched_Baby.Target.Familiar)
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
	local fireDirection = player:GetFireDirection()

	if ((fireDirection == Direction.NO_DIRECTION) and (familiar.FireCooldown <= 0)) then
		familiar.ShootDirection = Direction.NO_DIRECTION
		familiar:PlayFloatAnim(Direction.DOWN)
	else
		if (fireDirection ~= Direction.NO_DIRECTION) then
			familiar.ShootDirection = fireDirection
		end
		--- @type Vector
		local tearVector = isc:directionToVector(familiar.ShootDirection)
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
		familiar:PlayShootAnim(familiar.ShootDirection)
	end
	familiar.FireCooldown = familiar.FireCooldown - 1
end

--- @param mod ModUpgraded
function Scorched_Baby:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_FAMILIARS)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, familiarInit, self.Target.Familiar)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, familiarUpdate, self.Target.Familiar)
end

return Scorched_Baby
