local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")

local game = Game()

--- "Mending Heart"
--- - At the start of each new floor, replaces 1 Broken Heart with an empty Heart Container
--- - When no damage was taken on the previous floor, will replace 2 instead
--- - +0.25 damage per heart replaced
--- @class TheSaint.Items.Collectibles.Mending_Heart : TheSaint_Feature
local Mending_Heart = {
	IsInitialized = false,
	FeatureSubType = enums.CollectibleType.COLLECTIBLE_MENDING_HEART,
	SaveDataKey = "Mending_Heart",
}

--- @class MendingHeart_Counters
--- @field heartsRestored integer

local v = {
	run = {
		blockNewRun = true,
		--- @type table<string, MendingHeart_Counters>
		counters = {},
	},
}

--- animation state flag
local playMovie = -1

--- @param player EntityPlayer
--- @return boolean @ `true` if the player has "Mending Heart" or is "Tainted Saint", otherwise `false`
--- @return integer @ number of "Mending Heart" copies that `player` has
local function hasMendingHeart(player)
	local numMendingHeart = player:GetCollectibleNum(Mending_Heart.FeatureSubType)
	if (player:GetPlayerType() == enums.PlayerType.PLAYER_THE_SAINT_B) then
		numMendingHeart = numMendingHeart + 1
	end
	return (numMendingHeart > 0), numMendingHeart
end

--- @param player EntityPlayer
--- @return MendingHeart_Counters
local function getPlayerCounters(player)
	local playerIndex = "MendingHeart_"..isc:getPlayerIndex(player)
	if (not v.run.counters[playerIndex]) then
		v.run.counters[playerIndex] = {
			heartsRestored = 0,
		}
	end
	return v.run.counters[playerIndex]
end

--- When entering a new floor, replace Broken Heart(s) with empty Heart Container(s), then set the animation flag
--- @param stage LevelStage
--- @param stageType StageType
local function postNewLevelReordered(_, stage, stageType)
	-- prevent accidental trigger when starting a new run
	if (v.run.blockNewRun == true) then
		v.run.blockNewRun = false
	else
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			local hasCollectible, collectibleNum = hasMendingHeart(player)
			if (hasCollectible) then
				local brokenHearts = player:GetBrokenHearts()
				if (brokenHearts > 0) then
					-- set how many broken hearts to replace
					local amount = 1
					if (game:GetStagesWithoutDamage() > 0) then amount = 2 end
					-- multiply amount of hearts to restore by number of copies of "Mending Heart"
					amount = (amount * collectibleNum)
					-- replace broken hearts
					player:AddBrokenHearts(-amount)
					player:AddMaxHearts(2 * amount)
					-- add counters for damage up effect
					local heartsReplaced = (brokenHearts - player:GetBrokenHearts())
					local counters = getPlayerCounters(player)
					counters.heartsRestored = counters.heartsRestored + heartsReplaced
					-- set animation state flag
					playMovie = 0
				end
			end
		end
	end
end

--- giantbook animation
local mov = Sprite()
mov:Load("gfx/ui/giantbook/giantbook_mendingheart.anm2", true)

--- play the animation for 'mending' the Broken Heart(s)
local function postRender()
	if (playMovie == 0) then
		playMovie = 1
		mov:Play("Appear", true)
		mov:SetFrame("Appear", 0)
		mov:SetOverlayRenderPriority(true)
		mov:Render(Vector(240, 135), Vector.Zero, Vector.Zero)
	elseif (playMovie == 1) then
		if (mov:GetFrame() < 28 and game:GetFrameCount() % 2 == 0) then
			mov:SetFrame("Appear", mov:GetFrame() + 1)
		end
		mov:SetOverlayRenderPriority(true)
		mov:Render(Vector(240, 135), Vector.Zero, Vector.Zero)
		if (mov:GetFrame() == 28) then
			playMovie = -1
		end
	end
end

--- Increase the players damage by 0.25 per heart restored with "Mending Heart"
--- @param player EntityPlayer
--- @param flag CacheFlag
local function evaluateStats(_, player, flag)
	if (hasMendingHeart(player)) then
		local counters = getPlayerCounters(player)

		if (flag & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE) then
			player.Damage = player.Damage + (0.25 * counters.heartsRestored)
		end
	end
end

--- Initialize the item's functionality
--- @param mod ModUpgraded
function Mending_Heart:Init(mod)
	if (self.IsInitialized) then return end

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
	mod:AddCallback(ModCallbacks.MC_POST_RENDER, postRender)
	mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, evaluateStats, CacheFlag.CACHE_DAMAGE)
end

return Mending_Heart
