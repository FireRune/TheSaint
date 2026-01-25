--- @class TheSaint.stats.Character
--- @field name string
--- @field items ItemConfigItem[]
--- @field stats TheSaint.stats.Stats
--- @field costume string @ Costume name
--- @field trinket TrinketType
--- @field card Card
--- @field pill false | PillEffect
--- @field charge -1 | true | integer

--- @class TheSaint.stats.item
--- @field ID CollectibleType

--- @class TheSaint.stats.Stats
--- @field damage number
--- @field damageMult number
--- @field firedelay number
--- @field shotspeed number
--- @field range number
--- @field speed number
--- @field tearflags TearFlags
--- @field tearcolor Color
--- @field flying boolean
--- @field luck number

--- Regular Character
--- @type TheSaint.stats.Character
local character = {
	name = "The Saint",
	items = {},
	stats = {
		damage = 0.0,
		damageMult = 1,
		firedelay = 0.0,
		shotspeed = 0.0,
		range = 0.0,
		speed = 0.2,
		tearflags = TearFlags.TEAR_NORMAL,
		tearcolor = Color(1, 1, 1, 1, 0, 0, 0),
		flying = false,
		luck = 0,
	},
	costume = "character_sainthair",
	trinket = TrinketType.TRINKET_NULL,
	card = Card.CARD_NULL,
	pill = false,
	charge = -1,
}

--- Tainted Character
--- @type TheSaint.stats.Character
local tainted = {
	name = "The Saint",
	items = {},
	stats = {
		damage = 0.0,
		damageMult = 1.2,
		firedelay = 0.0,
		shotspeed = -0.1,
		range = 3.0,
		speed = 0.2,
		tearflags = TearFlags.TEAR_NORMAL,
		tearcolor = Color(0.65, 0, 0, 1, 0, 0, 0),
		flying = false,
		luck = -1,
	},
	costume = "character_sainthair_b",
	trinket = TrinketType.TRINKET_NULL,
	card = Card.CARD_NULL,
	pill = false,
	charge = -1,
}

--- @class TheSaint.stats
local stats = {
	ModName = "The Saint",
	saint = character,
	tSaint = tainted,
}

return stats
