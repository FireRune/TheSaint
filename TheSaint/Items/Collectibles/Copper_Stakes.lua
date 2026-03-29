local isc = require("TheSaint.lib.isaacscript-common")
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

	if (flag == CacheFlag.CACHE_RANGE) then
		player.TearRange = (player.TearRange + utils:RangeStatToValue(1))
	end
end

--- @param weapon EntityTear | EntityKnife | EntityLaser
local function shouldApplyEffect(weapon)
	local player = (weapon.SpawnerEntity and weapon.SpawnerEntity:ToPlayer())
	if (not player) then return end

	if (player:HasCollectible(Copper_Stakes.Target.Type)) then
		-- same luck formula as "Mom's Contacts"
		local chance = math.min((1 / (5 - math.floor(player.Luck * 0.15))), 0.5)
		local rng = player:GetCollectibleRNG(Copper_Stakes.Target.Type)
		if (rng:RandomFloat() < chance) then
			weapon:AddTearFlags(TearFlags.TEAR_JACOBS)
			weapon:GetData().TheSaint = {}
		else
			weapon:GetData().TheSaint = nil
		end
	else
		weapon:GetData().TheSaint = nil
	end
end

--- @param weapon EntityTear | EntityKnife | EntityLaser
--- @param collider Entity
--- @return EntityPlayer?
local function onCollision(weapon, collider)
	local data = weapon:GetData().TheSaint
	if (not data) then return end

	local enemy = ((utils:IsValidEnemy(collider, false) and collider:ToNPC()) or nil)
	if (not enemy) then return end

	local player = weapon.SpawnerEntity:ToPlayer() --- @cast player -?
	local enemyData = enemy:GetData().TheSaint
	if (enemyData) then
		enemyData.CollisionDetected = true
	else
		enemyData = {
			CollisionDetected = true,
		}
	end
	enemy:GetData().TheSaint = enemyData
	return player
end

--- @param enemy EntityNPC
--- @param player EntityPlayer
local function enemyDamaged(enemy, player)
	local enemyData = enemy:GetData().TheSaint
	if ((enemyData) and (enemyData.CollisionDetected)) then
		statusEffects:ApplyStatus(enemy, enums.StatusEffect.ELECTRIFIED, 90, player)
		enemyData.CollisionDetected = false
	end
	enemy:GetData().TheSaint = enemyData
end

--- @param ent Entity
--- @param amount number	@ value is an integer when `ent` is `EntityPlayer`, otherwise it's a float
--- @param flags DamageFlag
--- @param source EntityRef
--- @param countdown integer
local function entityTakeDmg(_, ent, amount, flags, source, countdown)
	local enemy = ((utils:IsValidEnemy(ent, false) and ent:ToNPC()) or nil)
	if (not enemy) then return end

	-- `source.Entity` can be nil (if the source is a GridEntity)
	if (not source.Entity) then return end

	--- @type EntityPlayer
	local player = isc:getPlayerFromEntity(source.Entity)

	enemyDamaged(enemy, player)
end

--- @param tear EntityTear
local function postTearInit(_, tear)
	shouldApplyEffect(tear)
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
	if ((knife.Variant ~= knifeVariant.MOMS_KNIFE) and (knife.Variant ~= knifeVariant.SUMPTORIUM)) then return end

	shouldApplyEffect(knife)
	onCollision(knife, collider)
end

--- @param laser EntityLaser
--- @param receiver Entity
local function laserDamage(_, laser, receiver)
	local enemy = ((utils:IsValidEnemy(receiver, false) and receiver:ToNPC()) or nil)
	if (not enemy) then return end

	shouldApplyEffect(laser)
	local player = onCollision(laser, receiver)

	if (not player) then return end

	enemyDamaged(enemy, player)
end

--- @param mod ModUpgraded
function Copper_Stakes:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_RANGE)
	mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, utils.CallbackPriority_VERY_LATE, entityTakeDmg)
	-- Tears
	mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, postTearInit)
	mod:AddPriorityCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, utils.CallbackPriority_VERY_LATE, preTearCollision)
	-- Knife
	mod:AddPriorityCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, utils.CallbackPriority_VERY_LATE, preKnifeCollision)
	-- Laser
	utils:AddTargetedCallback(mod, enums.Callbacks.LASER_DAMAGE, laserDamage, {LaserVariant.THICK_RED, LaserVariant.THIN_RED, LaserVariant.GIANT_RED, LaserVariant.BRIM_TECH, LaserVariant.THICKER_RED, LaserVariant.THICKER_BRIM_TECH, LaserVariant.GIANT_BRIM_TECH})
end

return Copper_Stakes
