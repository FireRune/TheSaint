local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local utils = include("TheSaint.utils")

local game = Game()
local conf = Isaac.GetItemConfig()

--- "Sacred Blindfold"
--- - permanent "Curse of the Unknown" + "Curse of Darkness" + "Curse of the Lost"
--- - Treasure Rooms on subsequent floors will contain an extra item
--- - all items of quality 0 will be rerolled (except quest items)
--- @class TheSaint.Items.Collectibles.Sacred_Blindfold : TheSaint.classes.ModFeatureTargeted<CollectibleType>
local Sacred_Blindfold = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<CollectibleType>
	Target = featureTarget:new(enums.CollectibleType.COLLECTIBLE_SACRED_BLINDFOLD),
}

--- @type integer?
local triggerPlayerIndex = nil

--- make sure that "Curse of Darkness", "Curse of the Lost" and "Curse of the Unknown" are applied while any player has "Sacred Blindfold"
local function postUpdate()
	if (not isc:anyPlayerHasCollectible(Sacred_Blindfold.Target.Type)) then return end

	local level = game:GetLevel()
	local curses = level:GetCurses()
	if ((curses & LevelCurse.CURSE_OF_DARKNESS == 0)
	or (curses & LevelCurse.CURSE_OF_THE_LOST == 0)
	or (curses & LevelCurse.CURSE_OF_THE_UNKNOWN == 0)) then
		level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, false)
		level:AddCurse(LevelCurse.CURSE_OF_THE_LOST, false)
		level:AddCurse(LevelCurse.CURSE_OF_THE_UNKNOWN, false)
	end
end

--- add 7 "Golden Horseshoe" before going to the next level, to guarantee a Double Treasure Room
--- @param player EntityPlayer
local function preNewLevel(_, player)
	if (not isc:anyPlayerHasCollectible(Sacred_Blindfold.Target.Type)) then return end

	triggerPlayerIndex = isc:getPlayerIndex(player)

	-- first save the players Trinkets (if any)
	--- @type TrinketType, TrinketType?
	local t1, t2
	t1 = player:GetTrinket(0)
	if (t1 ~= TrinketType.TRINKET_NULL) then
		-- check for 2nd Trinket slot
		if (player:GetMaxTrinkets() == 2) then
			t2 = player:GetTrinket(1)
			if (t2 ~= TrinketType.TRINKET_NULL) then
				player:TryRemoveTrinket(t2)
			end
		end
		player:TryRemoveTrinket(t1)
	end

	-- then add 7x "Golden Horseshoe" (15% * 7 = 105%)
	for _ = 1, 7 do
		player:AddTrinket(TrinketType.TRINKET_GOLDEN_HORSE_SHOE)
		player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, UseFlag.USE_NOANIM)
	end

	-- finally re-add the saved Trinkets (if any), starting with the 2nd one to preserve the order they were in before
	if (t1 ~= TrinketType.TRINKET_NULL) then
		if ((t2) and (t2 ~= TrinketType.TRINKET_NULL)) then
			player:AddTrinket(t2, false)
		end
		player:AddTrinket(t1, false)
	end
end

--- remove the 7 "Golden Horseshoe" given before going to the next level
--- @param stage LevelStage
--- @param stageType StageType
local function postNewLevelReordered(_, stage, stageType)
	if (not isc:anyPlayerHasCollectible(Sacred_Blindfold.Target.Type)) then return end

	-- no saved player index -> early exit
	if (not triggerPlayerIndex) then return end

	--- @type EntityPlayer?
	local player = isc:getPlayerFromIndex(triggerPlayerIndex)

	-- shouldn't happen but just in case
	if (not player) then return end

	-- first remove 7x "Golden Horseshoe"
	for _ = 1, 7 do
		player:TryRemoveTrinket(TrinketType.TRINKET_GOLDEN_HORSE_SHOE)
	end

	triggerPlayerIndex = nil
end

--- Reroll all collectibles of quality 0 (except quest items)
--- @param pickup EntityPickup
local function postPickupInitFirst(_, pickup)
	if (not isc:anyPlayerHasCollectible(Sacred_Blindfold.Target.Type)) then return end

	-- no rerolls in the "Death Certificate" area
	if (isc:inDimension(isc.Dimension.DEATH_CERTIFICATE)) then return end

	local collectible = pickup.SubType
	if (collectible == CollectibleType.COLLECTIBLE_NULL) then return end

	local itemConf = conf:GetCollectible(collectible)

	-- don't reroll quest items
	if (itemConf:HasTags(ItemConfig.TAG_QUEST)) then return end

	local pool = game:GetItemPool()
	local room = game:GetRoom()
	local level = game:GetLevel()
	local seeds = game:GetSeeds()
	local seed = seeds:GetStageSeed(level:GetStage())
	local itemPool = pool:GetPoolForRoom(room:GetType(), seed)
	local rng = utils:CreateNewRNG(pickup.InitSeed)
	--- @type CollectibleType?
	local newCollectible

	while (itemConf.Quality == 0) do
		newCollectible = pool:GetCollectible(itemPool, true, rng:Next())
		itemConf = conf:GetCollectible(newCollectible)
	end

	if (newCollectible) then isc:setCollectibleSubType(pickup, newCollectible) end
end

--- @param mod ModUpgraded
function Sacred_Blindfold:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_POST_UPDATE, postUpdate)
	mod:AddCallbackCustom(isc.ModCallbackCustom.PRE_NEW_LEVEL, preNewLevel)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst, PickupVariant.PICKUP_COLLECTIBLE)
end

return Sacred_Blindfold
