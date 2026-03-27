local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local utils = include("TheSaint.utils")

local game = Game()
local conf = Isaac.GetItemConfig()

--- "Sacred Blindfold"
--- - permanent "Curse of the Blind" (postUpdate)
--- - effects of "There's Options" and "More Options" (postPEffectUpdate)
--- - all items of quality 0 will be rerolled (postPickupInitFirst)
--- @class TheSaint.Items.Collectibles.Sacred_Blindfold : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Sacred_Blindfold = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_SACRED_BLINDFOLD),
}

--- make sure that "Curse of the Blind" is applied while any player has "Sacred Blindfold"
local function postUpdate()
	if (not isc:anyPlayerHasCollectible(Sacred_Blindfold.Target.Type)) then return end

	local level = game:GetLevel()
	local curses = level:GetCurses()
	if (curses & LevelCurse.CURSE_OF_BLIND ~= LevelCurse.CURSE_OF_BLIND) then
		level:AddCurse(LevelCurse.CURSE_OF_BLIND, true)
	end
end

--- (doesn't work)
--- constantly apply the effects of "There's Options" and "More Options"
--- @param player EntityPlayer
local function postPEffectUpdate(_, player)
	if (not player:HasCollectible(Sacred_Blindfold.Target.Type)) then return end

	local effects = player:GetEffects()
	if (not effects:GetCollectibleEffect(CollectibleType.COLLECTIBLE_THERES_OPTIONS)) then
		effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_THERES_OPTIONS)
	end
	if (not effects:GetCollectibleEffect(CollectibleType.COLLECTIBLE_MORE_OPTIONS)) then
		effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_MORE_OPTIONS)
	end
end

--- Reroll all collectibles of quality 0
--- @param pickup EntityPickup
local function postPickupInitFirst(_, pickup)
	if (not isc:anyPlayerHasCollectible(Sacred_Blindfold.Target.Type)) then return end

	local collectible = pickup.SubType
	if (collectible == CollectibleType.COLLECTIBLE_NULL) then return end

	local itemConf = conf:GetCollectible(collectible)
	if (itemConf.Quality == 0) then
		local pool = game:GetItemPool()
		local room = game:GetRoom()
		local seed = game:GetSeeds():GetStartSeed()
		local itemPool = pool:GetPoolForRoom(room:GetType(), seed)
		local newCollectible = pool:GetCollectible(itemPool, true, pickup.InitSeed)
		pool:RemoveCollectible(newCollectible)
		isc:setCollectibleSubType(pickup, newCollectible)
	end
end

--- @param mod ModUpgraded
function Sacred_Blindfold:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_POST_UPDATE, postUpdate)
	-- mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, postPEffectUpdate)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst, PickupVariant.PICKUP_COLLECTIBLE)
end

return Sacred_Blindfold
