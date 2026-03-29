local charNames = {
	NAME_SAINT = "The Saint",
}

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
		COLLECTIBLE_PROTECTIVE_CANDLE = Isaac.GetItemIdByName("Protective Candle"),
		COLLECTIBLE_COPPER_STAKES = Isaac.GetItemIdByName("Copper Stakes"),
		COLLECTIBLE_TESLA_COIL = Isaac.GetItemIdByName("Tesla Coil"),
		COLLECTIBLE_SACRED_BLINDFOLD = Isaac.GetItemIdByName("Sacred Blindfold"),
	},

	--- @enum TheSaint.Enums.TrinketType
	TrinketType = {
		TRINKET_HOLY_PENNY = Isaac.GetTrinketIdByName("Holy Penny"),
		TRINKET_SCATTERED_PAGES = Isaac.GetTrinketIdByName("Scattered Pages"),
		TRINKET_CHARONS_OBOL = Isaac.GetTrinketIdByName("Charon's Obol"),
		TRINKET_OLD_HIVE = Isaac.GetTrinketIdByName("Old Hive"),
	},

	--- @enum TheSaint.Enums.Card
	Card = {
		CARD_LIBRARY = Isaac.GetCardIdByName("librarycard"),
		CARD_SOUL_SAINT = Isaac.GetCardIdByName("soulofthesaint"),
		CARD_RED_JOKER = Isaac.GetCardIdByName("redjoker"),
		CARD_GLITCHED = Isaac.GetCardIdByName("glitchedcard"),
	},

	--- @enum TheSaint.Enums.CharacterNames
	CharacterNames = {
		NAME_SAINT = charNames.NAME_SAINT,
	},

	--- @enum TheSaint.Enums.PlayerType
	PlayerType = {
		PLAYER_THE_SAINT = Isaac.GetPlayerTypeByName(charNames.NAME_SAINT, false),
		PLAYER_THE_SAINT_B = Isaac.GetPlayerTypeByName(charNames.NAME_SAINT, true),
	},

	--- @enum TheSaint.Enums.FamiliarVariant
	FamiliarVariant = {
		SCORCHED_BABY = Isaac.GetEntityVariantByName("Scorched Baby"),
		TESLA_COIL = Isaac.GetEntityVariantByName("Tesla Coil"),
	},

	--- @enum TheSaint.Enums.PickupVariant
	PickupVariant = {
		PICKUP_SINFULCHEST = Isaac.GetEntityVariantByName("Sinful Chest"),
	},

	--- @enum TheSaint.Enums.EffectVariant
	EffectVariant = {
		PROTECTIVE_CANDLE = Isaac.GetEntityVariantByName("Protective Candle"),
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

	--- @enum TheSaint.Enums.StatusEffect
	StatusEffect = {
		ELECTRIFIED = "SAINT_ELECTRIFIED",
	},

	--- @enum TheSaint.Enums.Callbacks
	Callbacks = {
		--- (EntityLaser Laser, Entity Collider): void, Optional Arg: LaserVariant - Fired from the `MC_POST_LASER_UPDATE` callback whenever a laser collides with an `EntityPlayer` or `EntityNPC`. Triggered on every frame of the collision.
		LASER_COLLISION = "TheSaint_LASER_COLLISION",

		--- (EntityLaser Laser, Entity Receiver): void, Optional Arg: LaserVariant - Same as "TheSaint_LASER_COLLISION", but will only trigger on the exact frame the colliding entity has received damage.
		LASER_DAMAGE = "TheSaint_LASER_DAMAGE",
	},
}

return Enums
