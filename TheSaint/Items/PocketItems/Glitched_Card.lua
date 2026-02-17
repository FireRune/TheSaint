local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local unlockManager = require("TheSaint.UnlockManager")
local utils = include("TheSaint.utils")

local game = Game()
local pool = game:GetItemPool()
local conf = Isaac.GetItemConfig()

--- "Glitched Card"
--- - using it triggers the effect a random card
--- - not guaranteed to be removed after use
--- @class TheSaint.Items.PocketItems.Glitched_Card : TheSaint.classes.ModFeatureTargeted<Card>
local Glitched_Card = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<Card>
	Target = featureTarget:new(enums.Card.CARD_GLITCHED),
}

--- @param card Card
--- @param player EntityPlayer
--- @param flags UseFlag
local function useCard(_, card, player, flags)
	local rng_card = player:GetCardRNG(Glitched_Card.Target.Type)
	local initSeed = rng_card:RandomInt(math.maxinteger)
	local rng_removal = utils:CreateNewRNG(initSeed)

	local newCard
	local isValid = false
	local isGreedMode = game:IsGreedMode()
	repeat
		newCard = pool:GetCard(initSeed, true, false, false)
		local cardConf = conf:GetCard(newCard)
		if ((cardConf:IsAvailable()) and (unlockManager:IsPickupUnlocked(PickupVariant.PICKUP_TAROTCARD, newCard))
		and ((not isGreedMode) or (cardConf.GreedModeAllowed))) then
			isValid = true
		end
	until (isValid)

	player:UseCard(newCard, flags)

	if ((flags & UseFlag.USE_MIMIC ~= UseFlag.USE_MIMIC)
	and (rng_removal:RandomFloat() >= 0.1)) then
		player:AddCard(card)
	end
end

--- @param mod ModUpgraded
function Glitched_Card:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_USE_CARD, useCard, self.Target.Type)
end

return Glitched_Card
