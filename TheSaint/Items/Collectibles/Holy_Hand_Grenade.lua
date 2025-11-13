local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local game = Game()

local Holy_Hand_Grenade = {}

local targetFlag = TearFlags.TEAR_LIGHT_FROM_HEAVEN

local v = {
	room = {
		--- @type table<string, boolean>
		playerItemState = {},
		--- @type table<integer, table<string, boolean>>
		bombList = {},
		bigExplosion = false,
	}
}

--- Toggle between holding the item above Isaac's head and putting it away
--- @param collectible CollectibleType
--- @param rng RNG
--- @param player EntityPlayer
--- @param flags UseFlag
local function useItem(_, collectible, rng, player, flags)
	local retVal = {
		Discharge = false,
		Remove = false,
		ShowAnim = false,
	}
	-- prevent "Car Battery"
	if (flags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY) then return retVal end

	local playerIndex = "HHG_"..isc:getPlayerIndex(player)
	if (not v.room.playerItemState[playerIndex]) then
		v.room.playerItemState[playerIndex] = true
		player:AnimateCollectible(enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE, "LiftItem")
	else
		v.room.playerItemState[playerIndex] = false
		player:AnimateCollectible(enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE, "HideItem")
	end
	return retVal
end

--- Returns a normalized `Vector` (Length = 1) that corresponds to the major cardinal direction of `inputVector`
--- @param inputVector Vector
--- @return Vector
local function getAxisAlignedVector(inputVector)
	--[[
		The projectile can only be launched in 1 of the 4 cardinal directions, even with "Analog Stick" (tested with "Bob's Rotten Head")
		Attempting a diagonal input will prefer going North/South over East/West
	]]
	local degrees = inputVector:GetAngleDegrees()
	local targetDegrees = 0.0
	if ((degrees >= -135.0) and (degrees <= -45.0)) then
		targetDegrees = -90.0
	elseif ((degrees > -45.0) and (degrees < 45.0)) then
		targetDegrees = 0.0
	elseif ((degrees >= 45.0) and (degrees <= 135.0)) then
		targetDegrees = 90.0
	elseif ((degrees > 135.0) or (degrees < -135.0)) then
		targetDegrees = 180.0
	end
	return Vector.FromAngle(targetDegrees)
end

--- launch the grenade in the first pressed shooting direction
--- @param player EntityPlayer
--- @return boolean `true` if grenade was thrown, otherwise `false`
local function tryThrowGrenade(player)
	local shootingInput = player:GetShootingInput()
	if (shootingInput:Length() > 0) then
		player:AnimateCollectible(enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE, "HideItem")
		local launchVector = getAxisAlignedVector(shootingInput):Resized(15)
		local grenade = Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_GIGA, 0, player.Position, Vector.Zero, player):ToBomb()
		if (grenade) then
			local sprite = grenade:GetSprite()
			sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/pickup_giga_bomb.png")
			sprite:LoadGraphics()
			local ptr = GetPtrHash(grenade)
			v.room.bombList[ptr] = {["Holy_Hand_Grenade"] = true}
			player:TryHoldEntity(grenade)
			player:ThrowHeldEntity(launchVector)
			player:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE)
		end
		return true
	end
	return false
end

--- if the given player is currently holding up "Holy Hand Grenade", launch it in the first pressed shooting direction
--- @param player EntityPlayer
local function postPlayerUpdate(_, player)
	local playerIndex = "HHG_"..isc:getPlayerIndex(player)
	if (v.room.playerItemState[playerIndex] == true) then
		-- prevent swapping active items if Isaac has "Schoolbag"
		if (Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)) then
			-- testing with "Bob's Rotten Head" has shown, that Pocket Items still cycle through each other when pressing the input,
			-- which is why it's solved like this, and not by cancelling the input in MC_INPUT_ACTION
			player:SwapActiveItems()
		else
			if (tryThrowGrenade(player) == true) then
				v.room.playerItemState[playerIndex] = false
			end
		end
	end
end

--- Add 'Holy Light'-effect to bombs
--- @param bomb EntityBomb
local function postBombUpdate(_, bomb)
    if bomb.SpawnerEntity then
        local player = bomb.SpawnerEntity:ToPlayer()
        if player then
			local ptr = GetPtrHash(bomb)
            local data = v.room.bombList[ptr]
            if (data and data["Holy_Hand_Grenade"] == true) then
                bomb:AddTearFlags(targetFlag)
                data["Holy_Hand_Grenade"] = nil
            end
			if bomb:HasTearFlags(targetFlag) then
				if bomb:GetSprite():IsPlaying("Explode") then
					v.room.bigExplosion = true
					game:GetRoom():MamaMegaExplosion(bomb.Position)
				end
			end
        end
    end
end

--- Spawn a 'Holy Light'-beam
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

local function postEntityKill(_, entity)
	if (v.room.bigExplosion) then
		spawnHolyLight(entity.Position)
	end
end

--- Initialize this item's functionality
--- @param mod ModReference
function Holy_Hand_Grenade:Init(mod)
	mod:saveDataManager("Holy_Hand_Grenade", v)
	mod:AddCallback(ModCallbacks.MC_USE_ITEM, useItem, enums.CollectibleType.COLLECTIBLE_HOLY_HAND_GRENADE)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, postPlayerUpdate, 0)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, postBombUpdate, BombVariant.BOMB_GIGA)
	mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, entityTakeDamage)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, postEntityKill)
end

return Holy_Hand_Grenade
