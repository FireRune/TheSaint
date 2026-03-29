local enums = require("TheSaint.Enums")
local stats = include("TheSaint.stats")
local utils = include("TheSaint.utils")

local game = Game()
local pool = game:GetItemPool()
local config = Isaac.GetItemConfig()

--- @class TheSaint.Characters.Characters : TheSaint.classes.ModFeature
local Characters = {
	IsInitialized = false,
}

-- Fields

local isContinue = true -- to differentiate between a fresh run and a continued run
local char = enums.PlayerType.PLAYER_THE_SAINT
local taintedChar = enums.PlayerType.PLAYER_THE_SAINT_B
taintedChar = (((taintedChar == -1) and char) or taintedChar)

-- Utility Functions

--- checks wether the given player is a character from this mod.
--- @param player EntityPlayer
--- @return boolean?
local function isChar(player)
	if (not player) then return end

	local pType = player:GetPlayerType()
	return (not ((pType ~= char) and (pType ~= taintedChar)))
end

--- checks wether the given player is a tainted character from this mod.
--- @param player EntityPlayer
--- @return boolean?
local function isTainted(player)
	if (not player) then return end

	local pType = player:GetPlayerType()
	if ((pType ~= char) and (pType ~= taintedChar)) then return end

	return (not (pType == char))
end

--- if the given player is a character from this mod, returns the corresponding stat-table from stats.lua; otherwise nil
--- @param player EntityPlayer
--- @return TheSaint.stats.Character?
local function getPlayerStatTable(player)
	local taint = isTainted(player)
	if (taint == nil) then return end

	return ((taint and stats.TSaint) or stats.Saint)
end

-- Character Code

--- checks wether the given player is a character from this mod and re-evaluates their stats.
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (not isChar(player)) then return end

	local playerStatTable = getPlayerStatTable(player)
	if (not playerStatTable) then return end

	local playerStat = playerStatTable.Stats
	if (flag == CacheFlag.CACHE_DAMAGE) then
		player.Damage = ((player.Damage * playerStat.DamageMult) + playerStat.Damage)

	elseif (flag == CacheFlag.CACHE_FIREDELAY) then
		player.MaxFireDelay = (player.MaxFireDelay + playerStat.Firedelay)

	elseif (flag == CacheFlag.CACHE_SHOTSPEED) then
		player.ShotSpeed = (player.ShotSpeed + playerStat.Shotspeed)

	elseif (flag == CacheFlag.CACHE_RANGE) then
		player.TearRange = (player.TearRange + utils:RangeStatToValue(playerStat.Range))

	elseif (flag == CacheFlag.CACHE_SPEED) then
		player.MoveSpeed = (player.MoveSpeed + playerStat.Speed)

	elseif (flag == CacheFlag.CACHE_TEARFLAG) then
		player.TearFlags = (player.TearFlags | playerStat.Tearflags)

	elseif (flag == CacheFlag.CACHE_TEARCOLOR) then
		player.TearColor = playerStat.Tearcolor

	elseif ((flag == CacheFlag.CACHE_FLYING) and playerStat.Flying) then
		player.CanFly = true

	-- elseif (flag == CacheFlag.CACHE_WEAPON) then
	-- elseif (flag == CacheFlag.CACHE_FAMILIARS) then

	elseif (flag == CacheFlag.CACHE_LUCK) then
		player.Luck = (player.Luck + playerStat.Luck)

	-- elseif (flag == CacheFlag.CACHE_SIZE) then
	-- elseif (flag == CacheFlag.CACHE_COLOR) then
	-- elseif (flag == CacheFlag.CACHE_PICKUP_VISION) then
	end
end

--- actually adds the costume
--- @param costumeName string
--- @param player EntityPlayer
local function addCostume(costumeName, player)
	local cost = Isaac.GetCostumeIdByPath("gfx/characters/"..costumeName..".anm2")
	if (cost ~= -1) then player:AddNullCostume(cost) end
end

--- apply all given costumes to the specified player
--- @param appliedCostume table|string
--- @param player EntityPlayer
local function addCostumes(appliedCostume, player)
	if (type(appliedCostume) == "table") then
		for i = 1, #appliedCostume do
			addCostume(appliedCostume[i], player)
		end
	else
		addCostume(appliedCostume, player)
	end
end

--- actually removes the costume
--- @param costumeName string
--- @param player EntityPlayer
local function removeCostume(costumeName, player)
	local cost = Isaac.GetCostumeIdByPath("gfx/characters/"..costumeName..".anm2")
	if (cost ~= -1) then player:TryRemoveNullCostume(cost) end
end

--- remove all given costumes from the specified player
--- @param appliedCostume table|string
--- @param player EntityPlayer
local function removeCostumes(appliedCostume, player)
	if (type(appliedCostume) == "table") then
		for i = 1, #appliedCostume do
			removeCostume(appliedCostume[i], player)
		end
	else
		removeCostume(appliedCostume, player)
	end
end

--- when starting a new run, add costumes and items to the specified player
--- @param player EntityPlayer? default: `nil`
local function postPlayerInitLate(player)
	if (not player) then player = Isaac.GetPlayer() end
	if (not isChar(player)) then return end

	local statTable = getPlayerStatTable(player)
	if (not statTable) then return end

	-- Costume
	addCostumes(statTable.Costume, player)

	-- Items
	local items = statTable.Items
	for _, item in ipairs(items) do
		if (item.Type == "active") then
			if (item.Pocket) then
				player:SetPocketActiveItem(item.ID, ActiveSlot.SLOT_POCKET, false)
			else
				player:AddCollectible(item.ID, statTable.Charge)
			end
		elseif (not item.Innate) then
			player:AddCollectible(item.ID)
		end
		pool:RemoveCollectible(item.ID)
	end

	local trinket = statTable.Trinket
	if (trinket ~= TrinketType.TRINKET_NULL) then
		player:AddTrinket(trinket, true)
	end

	local pill = statTable.Pill
	if (pill ~= PillEffect.PILLEFFECT_NULL) then
		player:SetPill(0, pool:ForceAddPillEffect(pill))
	end

	local card = statTable.Card
	if (card ~= Card.CARD_NULL) then
		player:SetCard(0, card)
	end
end

--- @param mod ModUpgraded
function Characters:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats)
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
	    if (not isContinue) then postPlayerInitLate(player) end
	end)
	mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, IsContin)
		if IsContin then return end
		isContinue = false
		postPlayerInitLate()
	end)
	mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function() isContinue = true end)
end

return Characters
