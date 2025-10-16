local registry = include("TheSaint.ItemRegistry")
local stats = include("TheSaint.stats")

if EID then
	local desc = ""
	local extraTable = {}

	-- Almanach
	desc = "Invokes the effects of 2 'book'-items#Can also invoke Books that haven't been unlocked yet"
	EID:addCollectible(registry.COLLECTIBLE_ALMANACH, desc)

	EID:assignTransformation("collectible", registry.COLLECTIBLE_ALMANACH, EID.TRANSFORMATION["BOOKWORM"])

	desc = "Spawns the appropriate wisps of the triggered books"
	extraTable = {bulletpoint = "VirtuesCollectible"..registry.COLLECTIBLE_ALMANACH}
	EID:addCondition(registry.COLLECTIBLE_ALMANACH, CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, desc, nil, nil, extraTable)
	EID:addCondition(CollectibleType.COLLECTIBLE_BOOK_OF_VIRTUES, registry.COLLECTIBLE_ALMANACH, desc, nil, nil, extraTable)

	-- Mending Heart
	desc = "Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container#Will replace 2 instead, if no damage was taken on the previous floor"
	EID:addCollectible(registry.COLLECTIBLE_MENDING_HEART, desc)

	-- The Saint
	local char = Isaac.GetPlayerTypeByName(stats.default.name, false)
	desc = "{{AngelRoom}} Entering an Angel Room for the first time each floor has the following effects:#\1{{IND}} Increases one of the following stats, whichever is lowest:#\1{{IND}}{{IND}} +1 Damage#\1{{IND}}{{IND}} +0.5 Fire Rate#\1{{IND}}{{IND}} +0.2 Speed#\1{{IND}}{{IND}} +2.5 Range#{{IND}} Spawns either 3 {{Coin}} coins, 1 {{Bomb}} bomb or 1 {{Key}} key depending on what you have the least of"
	EID:addBirthright(char, desc, "The Saint")

	-- Tainted Saint
	local taintedChar = Isaac.GetPlayerTypeByName(stats.tainted.name, true)
	desc = "Can't use {{SoulHeart}} Soul Hearts#When you take damage, turns all {{EmptyHeart}} empty Heart Containers into {{BrokenHeart}} Broken Hearts (doesn't apply to self-damage)#{{Collectible"..registry.COLLECTIBLE_MENDING_HEART.."}} Entering a new floor will replace 1{{BrokenHeart}} Broken Heart with 1{{EmptyHeart}} empty Heart Container#{{Collectible"..registry.COLLECTIBLE_MENDING_HEART.."}} Will replace 2 instead, if no damage was taken on the previous floor"
	EID:addCharacterInfo(taintedChar, desc, "The Saint")

	desc = "Taking damage that causes penalties will only turn 1{{EmptyHeart}} empty Heart Container into a {{BrokenHeart}} Broken Heart"
	EID:addBirthright(taintedChar, desc, "The Saint")
end
