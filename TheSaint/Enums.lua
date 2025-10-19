local stats = include("TheSaint.stats")

--- @enum TheSaint.CollectibleType
local collectibleType = {
	-- actives

	COLLECTIBLE_ALMANACH = Isaac.GetItemIdByName("Almanach"),
	COLLECTIBLE_DEVOUT_PRAYER = Isaac.GetItemIdByName("Devout Prayer"),

	-- passives

	COLLECTIBLE_MENDING_HEART = Isaac.GetItemIdByName("Mending Heart")
}

--- @enum TheSaint.PlayerType
local playerType = {
	PLAYER_THE_SAINT = Isaac.GetPlayerTypeByName(stats.default.name, false),
	PLAYER_THE_SAINT_B = Isaac.GetPlayerTypeByName(stats.tainted.name, true)
}

local enums = {
	CollectibleType = collectibleType,
	PlayerType = playerType
}

return enums
