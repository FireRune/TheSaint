local stats = include("TheSaint.stats")

--- @class TheSaint.Enums
local Enums = {
	--- @enum TheSaint.Enums.CollectibleType
	CollectibleType = {
		COLLECTIBLE_ALMANACH = Isaac.GetItemIdByName("Almanach"),
		COLLECTIBLE_MENDING_HEART = Isaac.GetItemIdByName("Mending Heart"),
		COLLECTIBLE_DEVOUT_PRAYER = Isaac.GetItemIdByName("Devout Prayer"),
		COLLECTIBLE_DIVINE_BOMBS = Isaac.GetItemIdByName("Divine Bombs"),
		COLLECTIBLE_WOODEN_KEY = Isaac.GetItemIdByName("Wooden Key"),
		COLLECTIBLE_HOLY_HAND_GRENADE = Isaac.GetItemIdByName("Holy Hand Grenade"),
		COLLECTIBLE_RITE_OF_REBIRTH = Isaac.GetItemIdByName("Rite of Rebirth"),
		COLLECTIBLE_SCORCHED_BABY = Isaac.GetItemIdByName("Scorched Baby"),
	},

	--- @enum TheSaint.Enums.TrinketType
	TrinketType = {
		TRINKET_HOLY_PENNY = Isaac.GetTrinketIdByName("Holy Penny"),
		TRINKET_SCATTERED_PAGES = Isaac.GetTrinketIdByName("Scattered Pages"),
	},

	--- @enum TheSaint.Enums.Card
	Card = {
		CARD_LIBRARY = Isaac.GetCardIdByName("librarycard"),
		CARD_SOUL_SAINT = Isaac.GetCardIdByName("soulofthesaint"),
		CARD_RED_JOKER = Isaac.GetCardIdByName("redjoker"),
	},

	--- @enum TheSaint.Enums.PlayerType
	PlayerType = {
		PLAYER_THE_SAINT = Isaac.GetPlayerTypeByName(stats.saint.name, false),
		PLAYER_THE_SAINT_B = Isaac.GetPlayerTypeByName(stats.tSaint.name, true),
	},

	--- @enum TheSaint.Enums.FamiliarVariant
	FamiliarVariant = {
		SCORCHED_BABY = Isaac.GetEntityVariantByName("Scorched Baby"),
	},

	--- @enum TheSaint.Enums.SoundEffect
	SoundEffect = {
		SOUND_REVERSE_JOKER = Isaac.GetSoundIdByName("Red_Joker"),
	},

	--- @enum TheSaint.Enums.CompletionMarks
	CompletionMarks = {
		BOSS_RUSH = "BossRush",
		MOMS_HEART = "MomsHeart",
		SATAN = "Satan",
		ISAAC = "Isaac",
		THE_LAMB = "TheLamb",
		BLUE_BABY = "BlueBaby",
		MEGA_SATAN = "MegaSatan",
		GREED_MODE = "GreedMode",
		HUSH = "Hush",
		DELIRIUM = "Delirium",
		MOTHER = "Mother",
		THE_BEAST = "TheBeast",
	},

	CustomVarData = {
		--- @enum TheSaint.Enums.CustomVarData.Almanach
		Almanach = {
			NORMAL = 0,
			SCATTERED_PAGES = 1,
		},
	},

	--- @enum TheSaint.Enums.Setting
	Setting = {
		--- setting value is `boolean`
		UNLOCK_ALL = "UnlockAll",
	},
}

return Enums
