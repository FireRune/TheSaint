local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")

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

local targetFlag = TearFlags.TEAR_LIGHT_FROM_HEAVEN

local v = {
	room = {
		--- @type table<string, true | nil>
		playerItemState = {},
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
	end
end

--- Toggle between holding the item above Isaac's head and putting it away
--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
--- @return { Discharge: boolean, Remove: boolean, ShowAnim: boolean }?
local function useItem(_, collectible, rng, player, flags)
	-- prevent "Car Battery"
	if (flags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then return end

	local playerIndex = "HHG_"..isc:getPlayerIndex(player)
	if (not v.room.playerItemState[playerIndex]) then
		v.room.playerItemState[playerIndex] = true
		player:AnimateCollectible(Holy_Hand_Grenade.Target.Type, "LiftItem")
	else
		v.room.playerItemState[playerIndex] = nil
		player:AnimateCollectible(Holy_Hand_Grenade.Target.Type, "HideItem")
	end
end

--- Returns a normalized `Vector` (Length = 1) that corresponds to the major cardinal direction of `inputVector`
--- @param inputVector Vector
--- @return Vector
local function getAxisAlignedVector(inputVector)
	--The projectile can only be launched in 1 of the 4 cardinal directions, even with "Analog Stick" (tested with "Bob's Rotten Head")
	local degrees = inputVector:GetAngleDegrees()

	--- @type Direction
	local targetDirection = isc:angleToDirection(degrees)

	--- @type Vector
	local directionVector = isc:directionToVector(targetDirection)

	return directionVector
end

--- launch the grenade in the first pressed shooting direction
--- @param player EntityPlayer
--- @return boolean `true` if grenade was thrown, otherwise `false`
local function tryThrowGrenade(player)
	local shootingInput = player:GetShootingInput()
	if (shootingInput:Length() > 0) then
		-- hide item
		player:AnimateCollectible(Holy_Hand_Grenade.Target.Type, "HideItem")

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
		player:ThrowHeldEntity(getAxisAlignedVector(shootingInput):Resized(15))

		-- remove item, unless triggered by "? Card"
		if (questionMarkCardUsed) then
			questionMarkCardUsed = false
		else
			player:RemoveCollectible(Holy_Hand_Grenade.Target.Type)
		end
		return true
	end
	return false
end

--- if the given player is currently holding up "Holy Hand Grenade", launch it in the first pressed shooting direction
--- @param player EntityPlayer
local function postPlayerUpdate(_, player)
	-- early exit if player doesn't have "Holy Hand Grenade"
	if (player:HasCollectible(Holy_Hand_Grenade.Target.Type) == false) then return end

	local playerIndex = "HHG_"..isc:getPlayerIndex(player)
	if (v.room.playerItemState[playerIndex]) then
		-- prevent swapping active items if Isaac has "Schoolbag"
		if (Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)) then
			-- Testing with "Bob's Rotten Head" has shown that Active Items don't switch while Pocket Items still cycle through each other when pressing the input.
			-- To mimic this behaviour, call player:SwapActiveItems() instead of cancelling the input in MC_INPUT_ACTION.
			player:SwapActiveItems()
		else
			if (tryThrowGrenade(player) == true) then
				v.room.playerItemState[playerIndex] = nil
			end
		end
	end
end

--- Add "Holy Light"-effect to bombs
--- @param bomb EntityBomb
local function postBombUpdate(_, bomb)
	local player = (bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer())
	if (player) then
		local ptr = GetPtrHash(bomb)
		local data = v.room.bombList[ptr]
		if (data and (data["Holy_Hand_Grenade"] == true)) then
			bomb:AddTearFlags(targetFlag)
			data["Holy_Hand_Grenade"] = nil
		end
		if (bomb:HasTearFlags(targetFlag)) then
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
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate, 0)
	mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, postBombUpdate, BombVariant.BOMB_GIGA)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, entityTakeDamage)
	mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, postEntityKill)
end

return Holy_Hand_Grenade
