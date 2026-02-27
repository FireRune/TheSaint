local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local unlockManager = require("TheSaint.UnlockManager")
local utils = include("TheSaint.utils")

local game = Game()
local sfx = SFXManager()

--#region typedef

--- "Appear" -> "Idle" -> ("Open" -> wait 40 frames -> "Close")
--- @alias TheSaint.Items.Pickups.Sinful_Chest.ChestAnimation
--- | "Idle"	@ idle (closed)
--- | "Open"	@ opening the chest
--- | "Appear"	@ spawn
--- | "Opened"	@ idle (opened) ! NEVER USED !
--- | "Close"	@ closing the chest

--- @class TheSaint.Items.Pickups.Sinful_Chest.SinfulChestData
--- @field NextPayoutEmpty boolean
--- @field SpritesheetSuffix ("_lock" | "_coinslot")?
--- @field Timer integer?

--#endregion

--#region constants

-- SubType of a fresh, unopened Eternal Chest is 2. After it closes itself again it's SubType changes to 1 (CHEST_CLOSED)
local CHEST_CLOSED_INIT = 2
-- local CHEST_OPENED_REMOVE = 3

-- paths to alternate spritesheets

local SPRITESHEET_SUFFIXES = {
	LOCK = "_lock",
	COINSLOT = "_coinslot",
}

--- @param suffix? string
--- @return string
local function SPRITESHEET_CHEST(suffix)
	local filePath = "gfx/items/pick ups/sinful_chest"
	if (suffix) then
		filePath = filePath..suffix
	end
	return filePath..".png"
end

--- @param suffix? string
--- @return string
local function SPRITESHEET_PEDESTAL(suffix)
	local filePath = "gfx/items/pick ups/sinful_chest_pedestal"
	if (suffix) then
		filePath = filePath..suffix
	end
	return filePath..".png"
end

--#endregion

--- "Sinful Chest"
--- - works like an Eternal Chest, but with the rewards of Red Chests (25% chance for nothing, no longer re-closes if payout was nothing or an item)
--- - has a chance to replace regular Red Chests (higher chance in Devil Rooms)
--- @class TheSaint.Items.Pickups.Sinful_Chest : TheSaint.classes.ModFeatureTargeted<PickupVariant>
local Sinful_Chest = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<PickupVariant>
	Target = featureTarget:new(enums.PickupVariant.PICKUP_SINFULCHEST),
	SaveDataKey = "Sinful_Chest",
}

local v = {
	level = {
		--- @type table<string, table<string, TheSaint.Items.Pickups.Sinful_Chest.SinfulChestData>>
		SinfulChests = {},
	},
}

--#region Helper functions

--- Get the index for the current room (to use in `v.level.SinfulChests`)
--- @return string
local function getRoomListIdx()
	return "SinfulChest_"..game:GetLevel():GetCurrentRoomDesc().ListIndex
end

--- Get the table associated with the current room holding data relevant to Sinful Chests
--- @return table<string, TheSaint.Items.Pickups.Sinful_Chest.SinfulChestData>
local function getRoomSinfulChestTable()
	local roomListIdx = getRoomListIdx()
	return v.level.SinfulChests[roomListIdx]
end

--- Update Sinful Chest data
--- @param chestIdx string
--- @param data TheSaint.Items.Pickups.Sinful_Chest.SinfulChestData | nil
local function updateRoomSinfulChestTable(chestIdx, data)
	local roomListIdx = getRoomListIdx()
	v.level.SinfulChests[roomListIdx][chestIdx] = data
end

--- Get the index of the pickup (to use in a table returned by `getRoomSinfulChestTable` or for `updateRoomSinfulChestTable`)
--- @param chest EntityPickup
--- @return string
local function getChestIdx(chest)
	return "SinfulChest_"..Sinful_Chest.ThisMod:getPickupIndex(chest)
end

--- Get the new suffix to use for sprite replacements
--- @return string
local function getNewSuffix()
	local hasPayToPlay = isc:anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY)
	return ((hasPayToPlay and SPRITESHEET_SUFFIXES.COINSLOT) or SPRITESHEET_SUFFIXES.LOCK)
end

--- Replace the spritesheet of a Sinful Chest with the lock/coinslot variant, and optionally reload graphics
--- @param sprite Sprite
--- @param reloadGraphics? boolean	@ default: `false`
local function replaceChestSpritesheet(sprite, reloadGraphics)
	local suffix = getNewSuffix()
	sprite:ReplaceSpritesheet(0, SPRITESHEET_CHEST(suffix))
	if (reloadGraphics) then
		sprite:LoadGraphics()
	end
end

--- Replace the spritesheet of an item pedestal from a Red Chest (Sinful) with the regular/lock/coinslot variant, and optionally reload graphics
--- @param sprite Sprite
--- @param chestData TheSaint.Items.Pickups.Sinful_Chest.SinfulChestData
--- @param reloadGraphics? boolean	@ default: `false`
local function replacePedestalSpritesheet(sprite, chestData, reloadGraphics)
	sprite:ReplaceSpritesheet(5, SPRITESHEET_PEDESTAL(chestData.SpritesheetSuffix))
	if (reloadGraphics) then
		sprite:LoadGraphics()
	end
end

--- Return `true` if the given player is able to unlock a Sinful Chest, otherwise `false`
--- @param player EntityPlayer
--- @return boolean
local function hasResourceToUnlock(player)
	-- "Paper Clip" unlocks chests regardless of the effect of "Pay to Play"
	if (player:HasTrinket(TrinketType.TRINKET_PAPER_CLIP)) then
		return true
	end

	local hasPayToPlay = isc:anyPlayerHasCollectible(CollectibleType.COLLECTIBLE_PAY_TO_PLAY)
	if ((hasPayToPlay) and (player:GetNumCoins() > 0)) then
		player:AddCoins(-1)
		return true
	else
		if (player:HasGoldenKey()) then
			return true
		elseif (player:GetNumKeys() > 0) then
			player:AddKeys(-1)
			return true
		end
	end
	return false
end

--#endregion

--#region Callbacks

--- Init chest table for the current room if it doesn't exist
--- @param room RoomType
local function postNewRoomReordered(_, room)
	local roomListIdx = getRoomListIdx()
	if (not v.level.SinfulChests[roomListIdx]) then
		v.level.SinfulChests[roomListIdx] = {}
	end
end

--- Change Red Chests to Sinful Chests with the following chance:
--- - in a Devil Room: ~66.6%
--- - otherwise: ~1.05%
--- @param pickup EntityPickup
local function postPickupInitFirst_RedChest(_, pickup)
	-- only change Red Chests when Sinful Chests are unlocked
	if (unlockManager:IsPickupUnlocked(Sinful_Chest.Target.Type, 0) == false) then return end

	local level = game:GetLevel()
	local room = game:GetRoom()

	-- don't change Red Chests in the starting room of the "Chest"/"Dark Room" floor
	if ((not game:IsGreedMode()) and (level:GetAbsoluteStage() == LevelStage.STAGE6) and (isc:inStartingRoom())) then
		return
	end

	local chance = (((room:GetType() == RoomType.ROOM_DEVIL) and (2/3)) or (7/666))
	local rng = utils:CreateNewRNG(pickup.InitSeed)
	if (rng:RandomFloat() < chance) then
		pickup:Morph(EntityType.ENTITY_PICKUP, Sinful_Chest.Target.Type, 0, false, false, true)
	end
end

--- First Init: set SubType to `CHEST_CLOSED_INIT` (2) and add entry to chest table for current room
--- @param pickup EntityPickup
local function postPickupInitFirst_SinfulChest(_, pickup)
	pickup.SubType = CHEST_CLOSED_INIT
	local chestIdx = getChestIdx(pickup)
	updateRoomSinfulChestTable(chestIdx, { NextPayoutEmpty = false, })
end

--- This function is only called in 3 distinct cases:
--- - immediately after the POST_PICKUP_INIT_FIRST callback
--- - when `chestData.NextPayoutEmpty` is `true`
--- - when `chestData` is `nil`
--- @param pickup EntityPickup
local function postPickupInit_SinfulChest(_, pickup)
	local chestIdx = getChestIdx(pickup)
	local chestTable = getRoomSinfulChestTable()
	local chestData = chestTable[chestIdx]

	if (not chestData) then
		-- no chestData means the chest gets removed
		pickup:Remove()
	elseif (chestData.NextPayoutEmpty) then
		-- next payout is nothing, only need to change sprite
		pickup.SubType = ChestSubType.CHEST_CLOSED
		local sprite = pickup:GetSprite()
		replaceChestSpritesheet(sprite, true)
		chestData.Timer = nil
		chestData.SpritesheetSuffix = getNewSuffix()
		updateRoomSinfulChestTable(chestIdx, chestData)
	else
		-- set Variant to PICKUP_REDCHEST, and refresh "Guppy's Eye" vision
		pickup.Variant = PickupVariant.PICKUP_REDCHEST
		game:GetRoom():InvalidatePickupVision()
	end
end

--- Chest entity had already spawned before in this run, reapply the Sinful Chest sprite
--- @param pickup EntityPickup
local function postPickupInit_RedChest_Sinful(_, pickup)
	local chestIdx = getChestIdx(pickup)
	local chestTable = getRoomSinfulChestTable()
	local chestData = chestTable[chestIdx]

	-- no chestData means regular Red Chest -> early exit
	if (not chestData) then return end

	local sprite = pickup:GetSprite()
	sprite:Load("gfx/sinful_chest.anm2", true)
	if (pickup.SubType ~= CHEST_CLOSED_INIT) then
		replaceChestSpritesheet(sprite, true)
		chestData.SpritesheetSuffix = getNewSuffix()
	end
	sprite:Play("Idle")
	updateRoomSinfulChestTable(chestIdx, chestData)
end

--- Collectible that spawned from a Sinful Chest, replace the pedestal sprite
--- @param pickup EntityPickup
local function postPickupInit_Collectible_Sinful(_, pickup)
	local chestIdx = getChestIdx(pickup)
	local chestTable = getRoomSinfulChestTable()
	local chestData = ((chestTable and chestTable[chestIdx]) or nil)

	-- didn't spawn from a Sinful Chest, early exit
	if (not chestData) then return end

	local sprite = pickup:GetSprite()
	replacePedestalSpritesheet(sprite, chestData, true)
end

--- handle animation events
--- @param pickup EntityPickup
local function postPickupUpdate_SinfulChest(_, pickup)
	local sprite = pickup:GetSprite()
	local animName = sprite:GetAnimation() --- @cast animName TheSaint.Items.Pickups.Sinful_Chest.ChestAnimation

	if (animName == "Appear") then
		if (sprite:IsEventTriggered("DropSound")) then
			sfx:Play(SoundEffect.SOUND_CHEST_DROP)
		end
	end
end

--- handle closing animation
--- @param pickup EntityPickup
local function postPickupUpdate_RedChest_Sinful(_, pickup)
	local chestIdx = getChestIdx(pickup)
	local chestTable = getRoomSinfulChestTable()
	local chestData = chestTable[chestIdx]

	-- no chestData means regular Red Chest -> early exit
	if (not chestData) then return end

	local sprite = pickup:GetSprite()
	if ((pickup.SubType == ChestSubType.CHEST_OPENED) and (sprite:IsFinished("Open"))) then
		local chestTimer = chestData.Timer
		if (not chestTimer) then
			chestTimer = 40
		else
			chestTimer = (chestTimer - 1)
		end
		if (chestTimer <= 0) then
			sprite:LoadGraphics()
			sprite:Play("Close")
			sfx:Play(SoundEffect.SOUND_CHEST_DROP)
			pickup.SubType = ChestSubType.CHEST_CLOSED
			chestTimer = nil
			if (chestData.NextPayoutEmpty) then
				pickup.Variant = Sinful_Chest.Target.Type
			end
			game:GetRoom():InvalidatePickupVision()
			chestData.SpritesheetSuffix = getNewSuffix()
		end
		chestData.Timer = chestTimer
		updateRoomSinfulChestTable(chestIdx, chestData)
	end
end

--- Only triggered if Chest entity has it's true variant, meaning next payout will be empty
--- @param pickup EntityPickup
--- @param collider Entity
--- @param low boolean
local function prePickupCollision_SinfulChest(_, pickup, collider, low)
	local player = collider:ToPlayer()
	if ((not player) or (pickup.Wait > 0)) then return end

	local sprite = pickup:GetSprite()
	if (((sprite:GetAnimation() == "Idle") or (sprite:IsFinished("Close"))) and (hasResourceToUnlock(player))) then
		local chestIdx = getChestIdx(pickup)
		pickup.SubType = ChestSubType.CHEST_OPENED
		sprite:Play("Open")
		sfx:Play(SoundEffect.SOUND_UNLOCK00)
		sfx:Play(SoundEffect.SOUND_CHEST_OPEN)
		updateRoomSinfulChestTable(chestIdx, nil)
	end
end

--- After opening a Sinful Chest, determine whether the payout will be nothing
--- @param pickup EntityPickup
--- @param collider Entity
--- @param low boolean
local function prePickupCollision_RedChest_Sinful(_, pickup, collider, low)
	local chestIdx = getChestIdx(pickup)
	local chestTable = getRoomSinfulChestTable()
	local chestData = chestTable[chestIdx]

	-- no chestData means regular Red Chest -> early exit
	if (not chestData) then return end

	local player = collider:ToPlayer()
	if ((not player) or (pickup.Wait > 0)) then return end

	local sprite = pickup:GetSprite()
	if ((sprite:GetAnimation() == "Idle") or (sprite:IsFinished("Close"))) then
		local chance = 0.75
		if (pickup.SubType == CHEST_CLOSED_INIT) then
			chance = 1.0
			replaceChestSpritesheet(sprite)
		else
			-- player lacks resource to unlock chest -> only collide
			if (not hasResourceToUnlock(player)) then return false end
			sfx:Play(SoundEffect.SOUND_UNLOCK00)
		end
		local seed = pickup:GetDropRNG():GetSeed()
		local rng = utils:CreateNewRNG(seed)
		if (rng:RandomFloat() >= chance) then
			chestData.NextPayoutEmpty = true
		end
		updateRoomSinfulChestTable(chestIdx, chestData)
	end
end

--#endregion

--- @param mod ModUpgraded
function Sinful_Chest:Init(mod)
	if (self.IsInitialized) then return end

	self.ThisMod = mod

	mod:saveDataManager(self.SaveDataKey, v)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_REORDERED, postNewRoomReordered)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_RedChest, PickupVariant.PICKUP_REDCHEST)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_PICKUP_INIT_FIRST, postPickupInitFirst_SinfulChest, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, postPickupInit_SinfulChest, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, postPickupInit_RedChest_Sinful, PickupVariant.PICKUP_REDCHEST)
	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, postPickupInit_Collectible_Sinful, PickupVariant.PICKUP_COLLECTIBLE)
	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, postPickupUpdate_SinfulChest, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, postPickupUpdate_RedChest_Sinful, PickupVariant.PICKUP_REDCHEST)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, prePickupCollision_SinfulChest, self.Target.Type)
	mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, prePickupCollision_RedChest_Sinful, PickupVariant.PICKUP_REDCHEST)
end

return Sinful_Chest
