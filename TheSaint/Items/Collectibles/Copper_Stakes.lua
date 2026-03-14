local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local statusEffects = require("TheSaint.StatusEffects")
local utils = include("TheSaint.utils")

--- "Copper Stakes"
--- - +1 range
--- - chance to inflict "electrified" status effect
--- @class TheSaint.Items.Collectibles.Copper_Stakes : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Copper_Stakes = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_COPPER_STAKES),
}

local knifeVariant
if (REPENTOGON) then
	knifeVariant = KnifeVariant
else
	knifeVariant = {
		MOMS_KNIFE = 0,
		BONE_CLUB = 1,
		BONE_SCYTHE = 2,
		DONKEY_JAWBONE = 3,
		BERSERK_CLUB = 3,
		BAG_OF_CRAFTING = 4,
		SUMPTORIUM = 5,
		NOTCHED_AXE = 9,
		SPIRIT_SWORD = 10,
		TECH_SWORD = 11,
	}
end

--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (not (player:HasCollectible(Copper_Stakes.Target.Type))) then return end

	if (flag & CacheFlag.CACHE_RANGE == CacheFlag.CACHE_RANGE) then
		player.TearRange = (player.TearRange + 40)
	end
end

--- @param weapon EntityTear | EntityKnife | EntityLaser
local function tryApplyEffect(weapon)
	local player = weapon.SpawnerEntity:ToPlayer()

	if ((player) and (player:HasCollectible(Copper_Stakes.Target.Type))) then
		-- same luck formula as "Mom's Contacts"
		local chance = math.min((1 / (5 - math.floor(player.Luck * 0.15))), 0.5)
		local rng = player:GetCollectibleRNG(Copper_Stakes.Target.Type)
		if (rng:RandomFloat() < chance) then
			weapon:AddTearFlags(TearFlags.TEAR_JACOBS)
			weapon:GetData().TheSaint = {}
		else
			weapon:GetData().TheSaint = nil
		end
	end
end

--- @param weapon EntityTear | EntityKnife | EntityLaser
--- @param collider Entity
local function onCollision(weapon, collider)
	local data = weapon:GetData().TheSaint
	if (not data) then return end

	local enemy = ((utils:IsValidEnemy(collider, false) and collider:ToNPC()) or nil)
	if (not enemy) then return end

	local player = weapon.SpawnerEntity:ToPlayer() --- @cast player -?
	statusEffects:ApplyStatus(enemy, enums.StatusEffect.ELECTRIFIED, 90, player)
end

--- @param tear EntityTear
local function postTearInit(_, tear)
	tryApplyEffect(tear)
end

--- @param tear EntityTear
--- @param collider Entity
--- @param low boolean
local function preTearCollision(_, tear, collider, low)
	onCollision(tear, collider)
end

--- @param knife EntityKnife
--- @param collider Entity
--- @param low boolean
local function preKnifeCollision(_, knife, collider, low)
	-- only apply to "Mom's Knife" and T. Eve's "Sumptorium"
	if (knife.Variant ~= knifeVariant.MOMS_KNIFE and knife.Variant ~= knifeVariant.SUMPTORIUM) then return end

	tryApplyEffect(knife)
	onCollision(knife, collider)
end

--- @param mod ModUpgraded
function Copper_Stakes:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_RANGE)
	-- Tears
	mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, postTearInit)
	mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, preTearCollision)
	-- Knife
	mod:AddCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, preKnifeCollision)
end

return Copper_Stakes
