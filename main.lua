-- Imports

local isc = require("TheSaint.lib.isaacscript-common")
--local json = require("json")
local utility = include("TheSaint/utility")
local stats = include("TheSaint/stats")
local registry = include("TheSaint/ItemRegistry")
include("TheSaint/EIDRegistry")

-- Init

local TheSaintVanilla = RegisterMod(stats.ModName, 1)
local features = {
    isc.ISCFeature.SAVE_DATA_MANAGER
}
local TheSaint = isc:upgradeMod(TheSaintVanilla, features)

local imports = include("TheSaint/imports")
if (type(imports) == "table") then
    imports:Init(TheSaint)
end

-- Fields

local config = Isaac.GetItemConfig()
local game = Game()
local rng = RNG()
local pool = game:GetItemPool()
local isContinue = true -- to differentiate between a fresh run and a continued run
local char = Isaac.GetPlayerTypeByName(stats.default.name, false)
local taintedChar = Isaac.GetPlayerTypeByName(stats.tainted.name, true)
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
--- @return table|nil
local function GetPlayerStatTable(player)
    local taint = IsTainted(player)
    if (taint == nil) then return nil end

    return (taint and stats.tainted) or stats.default
end

-- Character Code

--- checks wether the given player is a character from this mod and re-evaluates their stats.
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
    if (not IsChar(player)) then return end

    local playerStat = GetPlayerStatTable(player).stats
    if (flag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE) then
        player.Damage = (player.Damage * playerStat.damageMult) + playerStat.damage
    end
    if (flag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY) then
        player.MaxFireDelay = player.MaxFireDelay + playerStat.firedelay
    end

    if (flag & CacheFlag.CACHE_SHOTSPEED == CacheFlag.CACHE_SHOTSPEED) then
        player.ShotSpeed = player.ShotSpeed + playerStat.shotspeed
    end

    if (flag & CacheFlag.CACHE_RANGE == CacheFlag.CACHE_RANGE) then
        player.TearRange = player.TearRange + playerStat.range
    end

    if (flag & CacheFlag.CACHE_SPEED == CacheFlag.CACHE_SPEED) then
        player.MoveSpeed = player.MoveSpeed + playerStat.speed
    end

    if (flag & CacheFlag.CACHE_LUCK == CacheFlag.CACHE_LUCK) then
        player.Luck = player.Luck + playerStat.luck
    end

    if (flag & CacheFlag.CACHE_FLYING == CacheFlag.CACHE_FLYING) and playerStat.flying then
        player.CanFly = true
    end

    if (flag & CacheFlag.CACHE_TEARFLAG == CacheFlag.CACHE_TEARFLAG) then
        player.TearFlags = player.TearFlags | playerStat.tearflags
    end

    if (flag & CacheFlag.CACHE_TEARCOLOR == CacheFlag.CACHE_TEARCOLOR) then
        player.TearColor = playerStat.tearcolor
    end
end
TheSaint:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats)

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

    local itemPool = game:GetItemPool()
    local pType = player:GetPlayerType()
    if (pType == char) then
        player:SetPocketActiveItem(registry.COLLECTIBLE_ALMANACH, ActiveSlot.SLOT_POCKET, false)
    end
    if (pType == taintedChar) then
		itemPool:RemoveCollectible(registry.COLLECTIBLE_MENDING_HEART)
        player:SetPocketActiveItem(registry.COLLECTIBLE_DEVOUT_PRAYER, ActiveSlot.SLOT_POCKET, false)
		player:AddCollectible(registry.COLLECTIBLE_MENDING_HEART)
    end
end
TheSaint:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player)
    if (not isContinue) then postPlayerInitLate(player) end
end)

TheSaint:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, IsContin)
    if IsContin then return end
    isContinue = false
    postPlayerInitLate()
end)

TheSaint:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function() isContinue = true end)

--- Custom commands
--- @param cmd string
function TheSaint:executeCmd(cmd)
    cmd = string.lower(cmd)
    if cmd == "saint_help" then
        print("'The Saint' commands:")
        print("'saint_help': shows this list")
        print("'saint_reloadbooks': reloads the cache of 'book'-items for 'Almanach'")
        print("'saint_marks': check progress for The Saint's completion marks")
        print("'saint_marksb': check progress for Tainted Saint's completion marks")
    end
end
TheSaint:AddCallback(ModCallbacks.MC_EXECUTE_CMD, TheSaint.executeCmd)

-- 'The Saint'-mechanics BEGIN

-- TODO

-- 'The Saint'-mechanics END

-- 'Tainted Saint'-mechanics BEGIN

--[[
    TODO: interactions with the following items:
    - 'Abbadon':
        on collecting, set health to 1 Heart Container with half a heart (MaxHearts = 2, Hearts = 1)
        also turn all lost Heart Containers to Broken Hearts
    - 'Esau Jr.':
        on first activation set health to 1 Heart container and 2 Broken Hearts (MaxHearts = 2, Hearts = 2, BrokenHearts = 2)
        also make sure to retain 'Mending Heart'
]]

--- 'Tainted Saint' took damage that invokes penalties (i.e. decreasing Devil/Angel chance)
--- @param ent Entity
--- @param flag DamageFlag
function TheSaint:onDmgTaken(ent, _, flag)
    local player = ent:ToPlayer()
	if player then
		local pType = player:GetPlayerType()
		if (pType == taintedChar) then
			if (flag & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS)
			and (flag & DamageFlag.DAMAGE_NO_PENALTIES ~= DamageFlag.DAMAGE_NO_PENALTIES) then
				utility:getData(player)["TSaint_DmgTaken"] = true
			end
		end
	end
end
TheSaint:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, TheSaint.onDmgTaken, EntityType.ENTITY_PLAYER)

--- remove all fully depleted heart containers, returns number of removed containers
--- @param player EntityPlayer
local function removeEmptyContainers(player)
    local emptyContainers = ((player:GetMaxHearts() - player:GetHearts()) // 2)
    player:AddMaxHearts(emptyContainers * -2)
    return emptyContainers
end

--- set flag for having an Eternal Heart and remove any Soul Hearts.
--- also, when taking damage that causes penalties, turn all empty containers into Broken Hearts.
--- @param player EntityPlayer
function TheSaint:postPlayerUpdate_TSaint_Hearts(player)
    local dat = utility:getData(player)
    if (player:GetPlayerType() == taintedChar) then
		-- player took damage that causes penalties, then remove all empty Heart Containers, replace with Broken Hearts
		if (dat["TSaint_DmgTaken"] == true) then
			player:AddBrokenHearts(removeEmptyContainers(player))
			dat["TSaint_DmgTaken"] = false
		end
        -- alter charge-behaviour of 'Devout Prayer' as T.Saint
        if (player:GetEternalHearts() > 0) then
            dat["TSaint_EternalHeart"] = true
        else
            dat["TSaint_EternalHeart"] = false
        end
        -- T.Saint can't utilize Soul/Black Hearts
        local soulHearts = player:GetSoulHearts()
        if (soulHearts > 0) then
            player:AddSoulHearts(-soulHearts)
        end
    end
end
TheSaint:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TheSaint.postPlayerUpdate_TSaint_Hearts, 0)

--- Heart Containers removed as payment will be replaced with Broken Hearts
--- @param item EntityPickup
--- @param collider Entity
function TheSaint:prePickupCollision_TSaint_BrokenHearts(item, collider)
    local player = collider:ToPlayer()
    if player and (player:GetPlayerType() == taintedChar) then
        if utility:canPickUpItem(player, item) then
            if (item.Price == PickupPrice.PRICE_ONE_HEART)
            or (item.Price == PickupPrice.PRICE_ONE_HEART_AND_TWO_SOULHEARTS)
			or (item.Price == PickupPrice.PRICE_ONE_HEART_AND_ONE_SOUL_HEART) then
                player:AddBrokenHearts(1)
            elseif (item.Price == PickupPrice.PRICE_TWO_HEARTS) then
                player:AddBrokenHearts(2)
            end
        end
    end
end
TheSaint:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, TheSaint.prePickupCollision_TSaint_BrokenHearts, PickupVariant.PICKUP_COLLECTIBLE)

--- chance to replace Soul/Black/Blended Hearts with an Eternal Heart while playing as 'Tainted Saint'
--- @param heart EntityPickup
function TheSaint:postPickupInit_TSaint_Hearts(heart)
    for i = 0, game:GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if (player:GetPlayerType() == taintedChar) then
            if (heart.SubType == HeartSubType.HEART_SOUL)
            or (heart.SubType == HeartSubType.HEART_BLACK)
            or (heart.SubType == HeartSubType.HEART_HALF_SOUL)
            or (heart.SubType == HeartSubType.HEART_BLENDED) then
                utility:setSeedRNG(rng)
                if ((rng:RandomInt(20) + 1) == 20) then
                    heart:Morph(heart.Type, heart.Variant, HeartSubType.HEART_ETERNAL, true)
                end
            end
			return -- attempt to replace only once, in case more than 1 player is 'Tainted Saint'
        end
    end
end
TheSaint:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, TheSaint.postPickupInit_TSaint_Hearts, PickupVariant.PICKUP_HEART)

--- prevent 'Tainted Saint' from picking up Soul/Black Hearts, as well as Blended Hearts while at full health
--- @param heart EntityPickup
--- @param collider Entity
function TheSaint:prePickupCollision_TSaint_Hearts(heart, collider)
    local player = collider:ToPlayer()
    if player and (player:GetPlayerType() == taintedChar) then
        if (heart.SubType == HeartSubType.HEART_SOUL)
        or (heart.SubType == HeartSubType.HEART_BLACK)
        or (heart.SubType == HeartSubType.HEART_HALF_SOUL)
        or ((heart.SubType == HeartSubType.HEART_BLENDED) and (player:GetHearts() >= player:GetMaxHearts())) then
            return false
        end
    end
end
TheSaint:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, TheSaint.prePickupCollision_TSaint_Hearts, PickupVariant.PICKUP_HEART)

-- 'Tainted Saint'-mechanics END

print("[The Saint] Type 'saint_help' for a list of commands")
