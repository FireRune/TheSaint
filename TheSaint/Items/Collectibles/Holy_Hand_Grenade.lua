local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
include("TheSaint.lib.throwableitemlib").Init()

local game = Game()

--- "Holy Hand Grenade"
--- - single use
--- - on activation, hold the item above Isaac's head or put it back again
--- - while held above the head, press any shooting input to throw the grenade in that direction
--- - causes a "Mama Mega"-like explosion in the current room that instantly kills any enemy hit by the explosion/shockwave
--- - only kills one phase of multi-phase bosses like "Mega Satan", "Mother", etc.
--- @class TheSaint.Items.Collectibles.Holy_Hand_Grenade : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Holy_Hand_Grenade = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE),
	SaveDataKey = "Holy_Hand_Grenade",
}

local THROWABLE_IDENTIFIER = "TheSaint_HolyHandGrenade"
local TARGET_FLAG = TearFlags.TEAR_LIGHT_FROM_HEAVEN

local v = {
	room = {
		--- @type table<integer, table<string, boolean>>
		bombList = {},
		bigExplosion = false,
	}
}

-- flag to check if "Holy Hand Grenade" is triggered from "? Card"
local questionMarkCardUsed = false

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard_QuestionMark(_, card, player, flags)
	if (player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == Holy_Hand_Grenade.Target.Type) then
		questionMarkCardUsed = true
		ThrowableItemLib.Utility:ScheduleLift(player, Holy_Hand_Grenade.Target.Type, ThrowableItemLib.Type.ACTIVE, ActiveSlot.SLOT_PRIMARY)
	end
end

--- @param player EntityPlayer
--- @param vect Vector
--- @param slot ActiveSlot
--- @param mimic CollectibleType
local function throwGrenade(player, vect, slot, mimic)
	-- spawn bomb entity
	local grenade = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_GIGA, 0, player.Position, Vector.Zero, player):ToBomb() --- @cast grenade -?

	-- replace spritesheet
	local sprite = grenade:GetSprite()
	sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_giga_bomb.png")
	sprite:LoadGraphics()

	-- set flag
	local ptr = GetPtrHash(grenade)
	v.room.bombList[ptr] = {["Holy_Hand_Grenade"] = true}

	-- throw grenade
	player:TryHoldEntity(grenade)
	player:ThrowHeldEntity(ThrowableItemLib.Utility:CardinalClamp(vect):Resized(15))

	-- remove item, unless triggered by "? Card"
	if (questionMarkCardUsed) then
		questionMarkCardUsed = false
	else
		player:RemoveCollectible(Holy_Hand_Grenade.Target.Type)
	end
end

ThrowableItemLib:RegisterThrowableItem({
	ID = Holy_Hand_Grenade.Target.Type,
	Type = ThrowableItemLib.Type.ACTIVE,
	Identifier = THROWABLE_IDENTIFIER,
	ThrowFn = throwGrenade,
	AnimateFn = function (player, state)
		if (state == ThrowableItemLib.State.THROW) then
			player:AnimatePickup(Sprite(), true, "HideItem")
			return true
		end
	end,
	Flags = ThrowableItemLib.Flag.NO_SPARKLE,
})

--- Add "Holy Light"-effect to bombs
--- @param bomb EntityBomb
local function postBombUpdate(_, bomb)
	local player = (bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer())
	if (player) then
		local ptr = GetPtrHash(bomb)
		local data = v.room.bombList[ptr]
		if (data and (data["Holy_Hand_Grenade"] == true)) then
			bomb:AddTearFlags(TARGET_FLAG)
			data["Holy_Hand_Grenade"] = nil
		end
		if (bomb:HasTearFlags(TARGET_FLAG)) then
			if (bomb:GetSprite():IsPlaying("Explode")) then
				v.room.bigExplosion = true
				game:GetRoom():MamaMegaExplosion(bomb.Position)
			end
		end
	end
end

--- Spawn a "Holy Light"-beam
--- @param pos Vector
--- @param spawner? Entity default: `nil`
local function spawnHolyLight(pos, spawner)
	Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 0, pos, Vector.Zero, spawner)
end

--- @param entity Entity
--- @param amount number
--- @param dmgFlags DamageFlag
--- @param source EntityRef
--- @param countdownFrames integer
local function entityTakeDamage(_, entity, amount, dmgFlags, source, countdownFrames)
	if (v.room.bigExplosion) then
		if ((source.Type == EntityType.ENTITY_EFFECT) and (source.Variant == EffectVariant.MAMA_MEGA_EXPLOSION)) then
			entity:Die()
			return false
		end
	end
end

--- @param entity Entity
local function postEntityKill(_, entity)
	if (v.room.bigExplosion) then
		spawnHolyLight(entity.Position)
	end
end

--- Initialize this item's functionality
--- @param mod ModUpgraded
function Holy_Hand_Grenade:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard_QuestionMark, Card.CARD_QUESTIONMARK)
	mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, postBombUpdate, BombVariant.BOMB_GIGA)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, entityTakeDamage)
	mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, postEntityKill)
end

return Holy_Hand_Grenade
