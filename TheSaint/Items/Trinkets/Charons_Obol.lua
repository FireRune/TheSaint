local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local utils = include("TheSaint.utils")

local sfx = SFXManager()

--- "Charon's Obol"
--- - picking up Soul/Black Hearts has a 50% chance to spawn wisps instead of healing the player
--- - allows picking up Soul/Black Hearts even at full health; chance for wisps goes to 100%
--- - Soul Hearts spawn regular wisps, Black Hearts spawn "Necronomicon" wisps
--- - only works with regular and half Soul Hearts, as well as regular Black Hearts
--- @class TheSaint.Items.Trinkets.Charons_Obol : TheSaint.classes.ModFeatureTargeted<TrinketType>
local Charons_Obol = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<TrinketType>
	Target = featureTarget:new(enums.TrinketType.TRINKET_CHARONS_OBOL),
}

--- @type table<PlayerType, string>
local redHeartOnlyChars = {}

--- Adds the given player types to the `redHeartOnlyChars`-table, if not already set
--- @param modName string
--- @param chars PlayerType[]
local function addRedHeartOnlyCharacter(modName, chars)
	for _, char in ipairs(chars) do
		if (not redHeartOnlyChars[char]) then
			redHeartOnlyChars[char] = modName
		end
	end
end
--- Exposed API version of `addRedHeartOnlyCharacter`<br>
--- Adds the given character(s) to the `redHeartOnlyChars`-table, if not already set
--- @param mod ModReference
--- @param char PlayerType | PlayerType[]
function TheSaintAPI:AddRedHeartOnlyCharacter(mod, char)
	if (type(char) ~= "table") then char = {char} end
	addRedHeartOnlyCharacter(mod.Name, char)
end

--- @param player EntityPlayer
--- @param isBlackHeart boolean
--- @return boolean
local function canPickSoulOrBlackHearts(player, isBlackHeart)
	if ((utils:AlabasterBoxNeedsCharge(player))
	or (isc:isCharacter(player, redHeartOnlyChars) == false)
	or ((not isBlackHeart) and (player:CanPickSoulHearts()))
	or ((isBlackHeart) and (player:CanPickBlackHearts()))) then
		return true
	end
	return false
end

--- @param pickup EntityPickup
--- @param collider Entity
--- @param low boolean
local function prePickupCollision_Hearts(_, pickup, collider, low)
	local player = collider:ToPlayer()
	if (not player) then return end

	-- force value to be an integer from 0 to 3
	local trinketMult = math.min(player:GetTrinketMultiplier(Charons_Obol.Target.Type), 3)
	if (trinketMult == 0) then return end

	--- @type HeartSubType
	local subType = pickup.SubType

	local isBlackHeart = false
	local numWisps = 2
	if ((subType == HeartSubType.HEART_SOUL)) then
	elseif (subType == HeartSubType.HEART_BLACK) then
		isBlackHeart = true
	elseif (subType == HeartSubType.HEART_HALF_SOUL) then
		numWisps = 1
	else
		-- early exit on any other heart type
		return
	end

	local chance = ((canPickSoulOrBlackHearts(player, isBlackHeart) and 0.5) or 1)

	local rng = player:GetTrinketRNG(Charons_Obol.Target.Type)
	if (rng:RandomFloat() < chance) then
		-- play "Collect" animation
		local sprite = pickup:GetSprite()
		sprite:Play("Collect")
		pickup:Die()

		-- play corresponding sfx
		local sfxId = (((isBlackHeart) and SoundEffect.SOUND_UNHOLY) or SoundEffect.SOUND_HOLY)
		sfx:Play(sfxId)

		-- spawn wisps
		local wispType = (((isBlackHeart) and CollectibleType.COLLECTIBLE_NECRONOMICON) or CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES)
		for _ = 1, (numWisps * trinketMult) do
			player:AddWisp(wispType, player.Position, true)
		end
		return true
	end
end

--- @param mod ModUpgraded
function Charons_Obol:Init(mod)
	if (self.IsInitialized) then return end

	addRedHeartOnlyCharacter(mod.Name, {enums.PlayerType.PLAYER_THE_SAINT_B})
	mod:AddPriorityCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, CallbackPriority.EARLY, prePickupCollision_Hearts, PickupVariant.PICKUP_HEART)
end

return Charons_Obol
