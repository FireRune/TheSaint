local isc = require("TheSaint.lib.isaacscript-common")
local enums = require("TheSaint.Enums")
local featureTarget = require("TheSaint.structures.FeatureTarget")
local utils = include("TheSaint.utils")

local config = Isaac.GetItemConfig()

--- "Old Hive"
--- - entering a room has a 25% chance to grant the effects of a random Fly/Spider item for that room.
--- @class TheSaint.Items.Trinkets.Old_Hive : TheSaint.classes.ModFeatureTargeted<TrinketType>
local Old_Hive = {
	IsInitialized = false,
	--- @type TheSaint.structures.FeatureTarget<TrinketType>
	Target = featureTarget:new(enums.TrinketType.TRINKET_OLD_HIVE),
}

--- @type CollectibleType[]
local hiveItems = {}

--- caches all items with the `fly` and/or `spider`-tag
local function getFlyOrSpiderItems()
	if (#hiveItems > 0) then return end
	utils:DebugStringWithHeader("(INFO) <Old Hive> generate list of passive items with 'fly' and/or 'spider'-tag")
	--- API says that `GetCollectibles()` returns `userdata`, but it's actually `ItemConfigList`
	--- @type ItemConfigList
	--- @diagnostic disable-next-line
	local collectibles = config:GetCollectibles()
	for i = 0, collectibles.Size - 1 do
		local collectible = config:GetCollectible(i)
		if ((collectible)
		and (collectible.Type ~= ItemType.ITEM_ACTIVE)
		and (collectible:HasTags(ItemConfig.TAG_FLY) or collectible:HasTags(ItemConfig.TAG_SPIDER))) then
			local id = collectible.ID
			table.insert(hiveItems, id)
			utils:DebugStringWithHeader("(INFO) <Old Hive> add ["..id.."] '"..collectible.Name.."'")
		end
	end
end

--- @param room RoomType
local function postNewRoomReordered(_, room)
	--- @type EntityPlayer[]
	local players = isc:getPlayersWithTrinket(Old_Hive.Target.Type)
	for _, player in ipairs(players) do
		--- value is 1, 2 or 3
		local mult = math.min(player:GetTrinketMultiplier(Old_Hive.Target.Type), 3)
		local chance = (((mult == 3) and 1) or (0.25 * mult))
		local rng = player:GetTrinketRNG(Old_Hive.Target.Type)
		local item = isc:getRandomArrayElement(hiveItems, rng)
		if (rng:RandomFloat() < chance) then
			player:GetEffects():AddCollectibleEffect(item)
		end
	end
end

--- reload the hiveItems-table via the Debug Console
local function thesaint_reloadhive()
	hiveItems = {}
	getFlyOrSpiderItems()
	utils:PrintWithHeader("reloaded hive-cache")
end

--- @param mod ModUpgraded
function Old_Hive:Init(mod)
	if (self.IsInitialized) then return end

	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_GAME_STARTED_REORDERED_LAST, getFlyOrSpiderItems)
	mod:AddCallbackCustom(isc.ModCallbackCustom.POST_NEW_ROOM_REORDERED, postNewRoomReordered)
	mod:addConsoleCommand("thesaint_reloadhive", thesaint_reloadhive)
end

return Old_Hive
