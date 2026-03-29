local enums = require("TheSaint.Enums")

local config = Isaac.GetItemConfig()

--- @class TheSaint.stats.Character
--- @field Name string
--- @field Items TheSaint.stats.Item[]
--- @field Stats TheSaint.stats.Stats
--- @field Costume string	@ Costume name
--- @field Trinket TrinketType
--- @field Card Card
--- @field Pill PillEffect
--- @field Charge integer	@ value of `0` or more for exact charge or `-1` for full charge

--- @alias ConfigType
--- | "active"
--- | "passive"

--- @class TheSaint.stats.Item
--- @field ID CollectibleType
--- @field Type ConfigType
--- @field Innate boolean
--- @field Pocket boolean
local Item = {}

--- @param id CollectibleType
--- @param innate? boolean	@ default: `false` - if `true`, just remove from pools
--- @param pocket? boolean	@ default: `false`
--- @return TheSaint.stats.Item
function Item:new(id, innate, pocket)
	if (innate == nil) then innate = false end
	if (pocket == nil) then pocket = false end

	local conf = config:GetCollectible(id)
	--- @type ConfigType
	local cType = (((conf.Type == ItemType.ITEM_ACTIVE) and "active") or "passive")

	return {
		ID = id,
		Type = cType,
		Innate = innate,
		Pocket = pocket,
	}
end

--- @class TheSaint.stats.Stats
--- @field Damage number
--- @field DamageMult number
--- @field Firedelay number
--- @field Shotspeed number
--- @field Range number
--- @field Speed number
--- @field Tearflags TearFlags
--- @field Tearcolor Color
--- @field Flying boolean
--- @field Luck number

--- Regular Character
--- @type TheSaint.stats.Character
local character = {
	Name = "The Saint",
	Items = {
		Item:new(enums.CollectibleType.COLLECTIBLE_ALMANACH),
		Item:new(enums.CollectibleType.COLLECTIBLE_PROTECTIVE_CANDLE, true),
	},
	Stats = {
		Damage = 0.0,
		DamageMult = 1,
		Firedelay = 0.0,
		Shotspeed = 0.0,
		Range = 0.0,
		Speed = 0.2,
		Tearflags = TearFlags.TEAR_SPECTRAL,
		Tearcolor = Color(1, 1, 1, 1, 0, 0, 0),
		Flying = false,
		Luck = 0,
	},
	Costume = "character_sainthair",
	Trinket = TrinketType.TRINKET_NULL,
	Card = Card.CARD_NULL,
	Pill = PillEffect.PILLEFFECT_NULL,
	Charge = -1,
}

--- Tainted Character
--- @type TheSaint.stats.Character
local tainted = {
	Name = "The Saint",
	Items = {
		Item:new(enums.CollectibleType.COLLECTIBLE_MENDING_HEART, true),
		Item:new(enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER, true, true),
	},
	Stats = {
		Damage = 0.0,
		DamageMult = 1.2,
		Firedelay = 0.0,
		Shotspeed = -0.1,
		Range = -1.5,
		Speed = 0.2,
		Tearflags = TearFlags.TEAR_NORMAL,
		Tearcolor = Color(0.65, 0, 0, 1, 0, 0, 0),
		Flying = false,
		Luck = -1,
	},
	Costume = "character_sainthair_b",
	Trinket = TrinketType.TRINKET_NULL,
	Card = Card.CARD_NULL,
	Pill = PillEffect.PILLEFFECT_NULL,
	Charge = -1,
}

--- @class TheSaint.stats
local stats = {
	ModName = "The Saint",
	Saint = character,
	TSaint = tainted,
}

return stats
