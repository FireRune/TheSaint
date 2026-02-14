local enums = require("TheSaint.Enums")
local stats = include("TheSaint.stats")

--- @class TheSaint.Characters.Characters : TheSaint.classes.ModFeature
local Characters = {
	IsInitialized = false,
}

-- Fields

local config = Isaac.GetItemConfig()
local game = Game()
local pool = game:GetItemPool()
local isContinue = true -- to differentiate between a fresh run and a continued run
local char = enums.PlayerType.PLAYER_THE_SAINT
local taintedChar = enums.PlayerType.PLAYER_THE_SAINT_B
taintedChar = taintedChar == -1 and char or taintedChar

-- Utility Functions

--- checks wether the given player is a character from this mod.
--- @param player EntityPlayer
local function IsChar(player)
	if (player == nil) then return nil end
	local pType = player:GetPlayerType()
	if (pType ~= char and pType ~= taintedChar) then return false end
	return true
end

--- checks wether the given player is a tainted character from this mod.
--- @param player EntityPlayer
local function IsTainted(player)
	if (player == nil) then return nil end
	local pType = player:GetPlayerType()
	if (pType ~= char and pType ~= taintedChar) then return nil end
	if (pType == char) then return false end
	return true
end

--- if the given player is a character from this mod, returns the corresponding stat-table from stats.lua; otherwise nil
--- @param player EntityPlayer
--- @return TheSaint.stats.Character?
local function GetPlayerStatTable(player)
	local taint = IsTainted(player)
	if (taint == nil) then return nil end

	return (taint and stats.tSaint) or stats.saint
end

-- Character Code

--- checks wether the given player is a character from this mod and re-evaluates their stats.
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (not IsChar(player)) then return end

	local playerStat = GetPlayerStatTable(player).stats
	if (flag == CacheFlag.CACHE_DAMAGE) then
		player.Damage = (player.Damage * playerStat.damageMult) + playerStat.damage
	elseif (flag == CacheFlag.CACHE_FIREDELAY) then
		player.MaxFireDelay = player.MaxFireDelay + playerStat.firedelay
	elseif (flag == CacheFlag.CACHE_SHOTSPEED) then
		player.ShotSpeed = player.ShotSpeed + playerStat.shotspeed
	elseif (flag == CacheFlag.CACHE_RANGE) then
		player.TearRange = player.TearRange + playerStat.range
	elseif (flag == CacheFlag.CACHE_SPEED) then
		player.MoveSpeed = player.MoveSpeed + playerStat.speed
	elseif (flag == CacheFlag.CACHE_TEARFLAG) then
		player.TearFlags = player.TearFlags | playerStat.tearflags
	elseif (flag == CacheFlag.CACHE_TEARCOLOR) then
		player.TearColor = playerStat.tearcolor
	elseif (flag == CacheFlag.CACHE_FLYING) and playerStat.flying then
		player.CanFly = true
	-- elseif (flag == CacheFlag.CACHE_WEAPON) then
	-- elseif (flag == CacheFlag.CACHE_FAMILIARS) then
	elseif (flag == CacheFlag.CACHE_LUCK) then
		player.Luck = player.Luck + playerStat.luck
	-- elseif (flag == CacheFlag.CACHE_SIZE) then
	-- elseif (flag == CacheFlag.CACHE_COLOR) then
	-- elseif (flag == CacheFlag.CACHE_PICKUP_VISION) then
	end
end

--- actually adds the costume
--- @param CostumeName string
--- @param player EntityPlayer
local function AddCostume(CostumeName, player)
	local cost = Isaac.GetCostumeIdByPath("gfx/characters/" .. CostumeName .. ".anm2")
	if (cost ~= -1) then player:AddNullCostume(cost) end
end

--- apply all given costumes to the specified player
--- @param AppliedCostume table|string
--- @param player EntityPlayer
local function AddCostumes(AppliedCostume, player)
	if (type(AppliedCostume) == "table") then
		for i = 1, #AppliedCostume do
			AddCostume(AppliedCostume[i], player)
		end
	else
		AddCostume(AppliedCostume, player)
	end
end

--- actually removes the costume
--- @param CostumeName string
--- @param player EntityPlayer
local function RemoveCostume(CostumeName, player)
	local cost = Isaac.GetCostumeIdByPath("gfx/characters/" .. CostumeName .. ".anm2")
	if (cost ~= -1) then player:TryRemoveNullCostume(cost) end
end

--- remove all given costumes from the specified player
--- @param AppliedCostume table|string
--- @param player EntityPlayer
local function RemoveCostumes(AppliedCostume, player)
	if (type(AppliedCostume) == "table") then
		for i = 1, #AppliedCostume do
			RemoveCostume(AppliedCostume[i], player)
		end
	else
		RemoveCostume(AppliedCostume, player)
	end
end

--- when starting a new run, add costumes and items to the specified player
--- @param player EntityPlayer? default: `nil`
local function postPlayerInitLate(player)
	if not player then player = Isaac.GetPlayer() end
	if not (IsChar(player)) then return end
	local statTable = GetPlayerStatTable(player)
	if not (statTable == nil) then
		-- Costume
		AddCostumes(statTable.costume, player)

		local items = statTable.items
		if (#items > 0) then
			for _, item in ipairs(items) do
				player:AddCollectible(item.ID)
				if (item.Costume) then
					local conf = config:GetCollectible(item.ID)
					player:RemoveCostume(conf)
				end
			end
			local charge = statTable.charge
			if (player:GetActiveItem() and charge ~= -1) then
				if (charge == true) then
					player:FullCharge()
				else
					player:SetActiveCharge(charge)
				end
			end
		end

		local trinket = statTable.trinket
		if (trinket ~= 0) then player:AddTrinket(trinket, true) end

		local pill = statTable.pill
		if (pill ~= false) then player:SetPill(0, pool:ForceAddPillEffect(pill)) end

		local card = statTable.card
		if (card ~= 0) then player:SetCard(0, card) end
	end

	local pType = player:GetPlayerType()
	if (pType == char) then
		pool:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_ALMANACH)
		pool:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_PROTECTIVE_CANDLE)
		player:AddCollectible(enums.CollectibleType.COLLECTIBLE_ALMANACH, -1) -- -1 for full charge
	end
	if (pType == taintedChar) then
		pool:RemoveCollectible(enums.CollectibleType.COLLECTIBLE_MENDING_HEART)
		player:SetPocketActiveItem(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER, ActiveSlot.SLOT_POCKET, false)
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
