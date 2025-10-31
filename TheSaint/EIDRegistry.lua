if EID then

	local enums = require("TheSaint.Enums")

	--- Small helper function for adding 'bookOfVirtuesWisps'-condition entries
	--- @param collectible CollectibleType
	--- @param description string
	local function addVirtuesCondition(collectible, description)
		EID:addToGeneralCondition(collectible, "bookOfVirtuesWisps", description)
	end

	local desc = ""

	-- Collectibles BEGIN
	-- Almanach
	local almanach = enums.CollectibleType.COLLECTIBLE_ALMANACH
	desc = [[
	Invokes the effects of 2 random 'book'-items
	#Can also invoke Books that haven't been unlocked yet]]
	EID:addCollectible(almanach, desc)

	desc = "Spawns the appropriate wisps of the triggered books"
	addVirtuesCondition(almanach, desc)

	desc = "Book effects doubled"
	EID:addCarBatteryCondition(almanach, desc)

	-- Devout Prayer
	local devoutPrayer = enums.CollectibleType.COLLECTIBLE_DEVOUT_PRAYER
	desc = [[
	Charges by killing enemies
	#Effects depend on charges used (never takes more charges than needed)
	#{{EternalHeart}} Consumes an Eternal Heart for extra effects
	#↑ 1+ charges: +0.1 Luck ({{EternalHeart}} and +0.25 Damage) for the floor per charge spent
	#3+ charges: Spawns an {{EternalHeart}} Eternal Heart ({{EternalHeart}} and grants a {{HolyMantleSmall}} Holy Mantle shield)
	#6+ charges: Spawns an {{HolyChest}} Eternal Chest ({{EternalHeart}} and {{AngelChanceSmall}}+10% Angel Room chance)
	#12 charges: Spawns 2 items (1 from current pool, 1 from Angel pool). Only 1 can be taken ({{EternalHeart}} both can be taken)]]
	EID:addCollectible(devoutPrayer, desc)

	desc = "Spawns a regular wisp ({{EternalHeart}} spawns a {{Collectible"..CollectibleType.COLLECTIBLE_BIBLE.."}} Bible wisp instead)"
	addVirtuesCondition(devoutPrayer, desc)

	desc = "No Effect"
	EID:addCarBatteryCondition(devoutPrayer, desc)

	-- Mending Heart
	local mendingHeart = enums.CollectibleType.COLLECTIBLE_MENDING_HEART
	desc = [[
	Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container
	#Will replace 2 instead, if no damage was taken on the previous floor]]
	EID:addCollectible(mendingHeart, desc)

	-- Divine Bombs
	local divineBombs = enums.CollectibleType.COLLECTIBLE_DIVINE_BOMBS
	desc = "{{Bomb}} +5 Bombs#{{Collectible"..CollectibleType.COLLECTIBLE_HOLY_LIGHT.."}} Isaac's bombs release a beam of light that hits nearby enemies"
	EID:addCollectible(divineBombs, desc)

	-- Wooden Key
	local woodenKey = enums.CollectibleType.COLLECTIBLE_WOODEN_KEY
	desc = [[
	Opens a random door in the current room
	#Can open locked doors
	#Can open {{SecretRoom}}{{SuperSecretRoom}} Secret Rooms/Super Secret Rooms
	#{{Collectible]]..CollectibleType.COLLECTIBLE_RED_KEY.."}} Can also create Red Room Doors"
	EID:addCollectible(woodenKey, desc)

	EID:addCarBatteryCondition(woodenKey, {"a random door", "2{{CR}} random doors"})
	-- Collectibles END

	-- Trinkets BEGIN
	-- Holy Penny
	local holyPenny = enums.TrinketType.TRINKET_HOLY_PENNY
	desc = [[
	{{EternalHeart}} Picking up a coin has a 17% chance to spawn an Eternal Heart
	#Higher chance from nickels and dimes]]
	EID:addTrinket(holyPenny, desc)
	EID:addGoldenTrinketMetadataAdditive(holyPenny, nil, 17, {8, 13})
	-- Trinkets END

	-- PocketItems BEGIN
	local libraryCard = enums.Card.CARD_LIBRARY
	desc = "{{Library}} Teleports Isaac to the Library"
	EID:addCard(libraryCard, desc)
	-- PocketItems END

	-- Characters BEGIN
	-- The Saint
	local saint = enums.PlayerType.PLAYER_THE_SAINT
	desc = [[
	{{AngelRoom}} Entering an Angel Room for the first time each floor has the following effects:
	#↑{{IND}} Increases one of the following stats, whichever is lowest:
	#↑{{IND}}{{IND}} +1 Damage
	#↑{{IND}}{{IND}} +0.5 Fire Rate
	#↑{{IND}}{{IND}} +0.2 Speed
	#↑{{IND}}{{IND}} +2.5 Range
	#{{IND}} Spawns either 3 {{Coin}} coins, 1 {{Bomb}} bomb or 1 {{Key}} key depending on what you have the least of]]
	EID:addBirthright(saint, desc, "The Saint")

	-- Tainted Saint
	local tSaint = enums.PlayerType.PLAYER_THE_SAINT_B
	desc = [[
	Can't use {{SoulHeart}} Soul Hearts
	#When you take damage, turns all {{EmptyHeart}} empty Heart Containers into {{BrokenHeart}} Broken Hearts (doesn't apply to self-damage)
	#{{Collectible]]..mendingHeart..[[}} Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container
	#{{Collectible]]..mendingHeart.."}} Will replace 2 instead, if no damage was taken on the previous floor"
	EID:addCharacterInfo(tSaint, desc, "The Saint")

	desc = "Taking damage that causes penalties will only turn 1{{EmptyHeart}} empty Heart Container into a {{BrokenHeart}} Broken Heart"
	EID:addBirthright(tSaint, desc, "The Saint")
	-- Characters END

end
