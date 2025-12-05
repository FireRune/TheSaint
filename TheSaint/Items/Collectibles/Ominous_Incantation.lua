local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local PlayerLoadout = require("TheSaint.classes.PlayerLoadout")

--- @class TheSaint.Items.Collectibles.Ominous_Incantation : TheSaint_Feature
local Ominous_Incantation = {
	IsInitialized = false,
	FeatureSubType = enums.CollectibleType.COLLECTIBLE_OMINOUS_INCANTATION,
	SaveDataKey = "Ominous_Incantation",
}

--- @type ModUpgraded
local thisMod

local RevivalState = {
	NONE = 0,
	USE_GENESIS = 1,
	USE_R_KEY = 2,
}

local currentRevivalState = RevivalState.NONE
--- @type EntityPlayer?
local currentRevivalPlayer = nil

local v = {
	run = {
		--- @type table<string, SerializablePlayerLoadout>
		PlayerLoadouts = {},
	}
}

--- Save the given player's current loadout
--- @param player EntityPlayer
local function saveLoadout(player)
	local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)

	local loadout = PlayerLoadout.createFromPlayer(thisMod, player)

	v.run.PlayerLoadouts[playerIndex] = loadout:serialize()
end

--- @param player EntityPlayer
--- @return SerializablePlayerLoadout
local function getLoadout(player)
	local playerIndex = "OI_Loadout_"..isc:getPlayerIndex(player)
	return v.run.PlayerLoadouts[playerIndex]
end

--- @param player EntityPlayer
local function preCustomRevive(_, player)
	if (player:HasCollectible(Ominous_Incantation.FeatureSubType)) then
		return Ominous_Incantation.FeatureSubType
	end
	return nil
end

--- @param player EntityPlayer
--- @param revivalType integer
local function postCustomRevive(_, player, revivalType)
	player:RemoveCollectible(Ominous_Incantation.FeatureSubType)

	-- during "The Beast" fight, functions as a simple extra life
	if (isc:inBeastRoom()) then
		player:AnimateCollectible(Ominous_Incantation.FeatureSubType)
	else
		saveLoadout(player)
		currentRevivalPlayer = player
		currentRevivalState = RevivalState.USE_GENESIS
		isc:useActiveItemTemp(player, CollectibleType.COLLECTIBLE_GENESIS)
	end
end

--- @param room RoomType
local function postNewRoomEarly(_, room)
	if (currentRevivalState == RevivalState.USE_GENESIS) then
		currentRevivalState = RevivalState.USE_R_KEY
		isc:useActiveItemTemp(currentRevivalPlayer, CollectibleType.COLLECTIBLE_R_KEY)
	end
end

--- @param stage LevelStage
--- @param stageType StageType
local function postNewLevelReordered(_, stage, stageType)
	if (currentRevivalState == RevivalState.USE_R_KEY) then
		currentRevivalState = RevivalState.NONE
		if (currentRevivalPlayer) then
			currentRevivalPlayer:AnimateCollectible(Ominous_Incantation.FeatureSubType)
			currentRevivalPlayer = nil
		end
	end
end

--- @param mod ModUpgraded
function Ominous_Incantation:Init(mod)
	if (self.IsInitialized) then return end

	thisMod = mod

	mod:saveDataManager(self.SaveDataKey, v)

	-- want to run this callback pretty late, so using priority of 1000
	mod:AddPriorityCallbackCustom(isc.ModCallbackCustom.PRE_CUSTOM_REVIVE, 1000, preCustomRevive, 0)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_CUSTOM_REVIVE, postCustomRevive, self.FeatureSubType)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_EARLY, postNewRoomEarly)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_LEVEL_REORDERED, postNewLevelReordered)
end

return Ominous_Incantation
