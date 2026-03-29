local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local utils = include("TheSaint.utils")

--- "Divine Bombs"
--- - +5 bombs
--- - Bombs spawn "Holy Light" beams upon exploding
--- @class TheSaint.Items.Collectibles.Divine_Bombs : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Divine_Bombs = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS),
}

local TARGET_FLAG = TearFlags.TEAR_LIGHT_FROM_HEAVEN

--- @class TheSaint.Items.Collectibles.Divine_Bombs.ExplosionData
--- @field FirstFrame boolean
--- @field SpawnerPlayer EntityPlayer

--- Spawn a "Holy Light"-beam
--- @param pos Vector
--- @param spawner? Entity default: `nil`
local function spawnHolyLight(pos, spawner)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, pos, Vector.Zero, spawner)
end

--- Spawns "Holy Light"-beams at the given position, as well as at the position of all surrounding enemies
--- @param pos Vector
--- @param spawner? Entity default: `nil`
local function triggerHolyLight(pos, spawner)
	spawnHolyLight(pos, spawner)
	for _, ent in ipairs(Isaac.GetRoomEntities()) do
		if (utils:IsValidEnemy(ent, false) and ((ent.Position - pos):Length() <= 150)) then
			spawnHolyLight(ent.Position, spawner)
		end
	end
end

--- Luck formula for "Dr. Fetus" and "Epic Fetus"/"Doctor's Remote"
--- @param player EntityPlayer
--- @param item CollectibleType
--- @return boolean
local function shouldApplyEffectToFetus(player, item)
	local rng = player:GetCollectibleRNG(item)
	--- @type number
	local chance = isc:clamp((0.11 + (0.03 * player.Luck)), 0.0, 1.0)

	return (rng:RandomFloat() < chance)
end

--- Add "Holy Light"-TearFlag to bombs spawned by the player
--- @param bomb EntityBomb
local function postBombInitLate(_, bomb)
	if (bomb.Variant == BombVariant.BOMB_GIGA) then return end

	local player = (bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer())
	if (not player) then return end

	if (player:HasCollectible(Divine_Bombs.Target.Type)) then
		bomb:AddTearFlags(TARGET_FLAG)
	end

	-- bombs from "Dr. Fetus" only have a chance to apply bomb effects from items
	-- same luck formula as for "Sad Bombs" and "Brimstone Bombs"
	if (not bomb.IsFetus) then return end

	-- effect has already been applied to the bomb -> rng-check for removal
	if (shouldApplyEffectToFetus(player, CollectibleType.COLLECTIBLE_DR_FETUS)) then return end

	bomb:ClearTearFlags(TARGET_FLAG)
end

--- Spawn light beams on explosion
--- @param bomb EntityBomb
local function postBombUpdate(_, bomb)
	if (bomb.Variant == BombVariant.BOMB_GIGA) then return end

	local player = (bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer())
	if (not ((player) and (bomb:HasTearFlags(TARGET_FLAG)))) then return end

	-- spawn light beams on explosion
	if (bomb:GetSprite():IsPlaying("Explode")) then
		triggerHolyLight(bomb.Position, player)
	end
end

--- Add bomb effect to rockets ("Epic Fetus" and "Doctor's Remote")
--- @param effect EntityEffect
local function postEffectInit(_, effect)
	local parentEffect = (effect.SpawnerEntity and effect.SpawnerEntity:ToEffect())
	if (not ((parentEffect) and (parentEffect.Variant == EffectVariant.ROCKET))) then return end

	local player = (parentEffect.SpawnerEntity and parentEffect.SpawnerEntity:ToPlayer())
	if (not player) then return end

	-- using `GetData()` here, because it'll be accessed on the next frame
	effect:GetData().TheSaint = {
		SpawnerPlayer = player,
	}
end

--- Synergy "Epic Fetus" (or "Doctor's Remote") + "Divine Bombs" or "Holy Light" (due to TearFlags.LIGHT_FROM_HEAVEN)
--- @param explosion EntityEffect
local function postEffectInitLate(_, explosion)
	if (not ((explosion.SpawnerType == EntityType.ENTITY_EFFECT) and (explosion.SpawnerVariant == EffectVariant.ROCKET))) then return end

	local data = explosion:GetData().TheSaint
	if (not data) then return end

	--- @type EntityPlayer
	local player = data.SpawnerPlayer
	if (not ((player) and (isc:hasCollectible(player, CollectibleType.COLLECTIBLE_HOLY_LIGHT, Divine_Bombs.Target.Type)))) then return end

	if (not shouldApplyEffectToFetus(player, CollectibleType.COLLECTIBLE_EPIC_FETUS)) then return end

	triggerHolyLight(explosion.Position, player)
end

--- Initialize the item's functionality.
--- @param mod ModUpgraded
function Divine_Bombs:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_BOMB_INIT_LATE, postBombInitLate)
	mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, postBombUpdate)
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, postEffectInit, EffectVariant.BOMB_EXPLOSION)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_EFFECT_INIT_LATE, postEffectInitLate, EffectVariant.BOMB_EXPLOSION)
end

return Divine_Bombs
