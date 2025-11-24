local stats = include("TheSaint.stats")

--- @class TheSaint.Enums
local Enums = {
	--- @enum TheSaint.Enums.CollectibleType
	CollectibleType = {
		-- actives

		COLLECTIBLE_ALMANACH = Isaac.GetItemIdByName("Almanach"),
		COLLECTIBLE_DEVOUT_PRAYER = Isaac.GetItemIdByName("Devout Prayer"),
		COLLECTIBLE_WOODEN_KEY = Isaac.GetItemIdByName("Wooden Key"),
		COLLECTIBLE_HOLY_HAND_GRENADE = Isaac.GetItemIdByName("Holy Hand Grenade"),

		-- passives

		COLLECTIBLE_MENDING_HEART = Isaac.GetItemIdByName("Mending Heart"),
		COLLECTIBLE_DIVINE_BOMBS = Isaac.GetItemIdByName("Divine Bombs"),
	},

	--- @enum TheSaint.Enums.TrinketType
	TrinketType = {
		TRINKET_HOLY_PENNY = Isaac.GetTrinketIdByName("Holy Penny"),
	},

	--- @enum TheSaint.Enums.Card
	Card = {
		CARD_LIBRARY = Isaac.GetCardIdByName("librarycard"),
		CARD_SOUL_SAINT = Isaac.GetCardIdByName("soulofthesaint"),
	},

	--- @enum TheSaint.Enums.PlayerType
	PlayerType = {
		PLAYER_THE_SAINT = Isaac.GetPlayerTypeByName(stats.saint.name, false),
		PLAYER_THE_SAINT_B = Isaac.GetPlayerTypeByName(stats.tSaint.name, true),
	},
}

return Enums
